import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/ai/domain/entities/ai_transaction_draft.dart';
import 'package:equity_tracker/features/ai/infrastructure/gateways/ledger_gateway_impl.dart';

class FakeCategoryRepository extends CategoryRepository {
  List<CategoryModel> categories = [];

  @override
  Future<List<CategoryModel>> getCategories() async => categories;
}

class FakeTransactionRepository extends TransactionRepository {
  List<TransactionModel> transactions = [];
  Map<int, String> lastBatchUpdates = {};
  bool? lastMarkPendingSync;

  @override
  Future<List<TransactionModel>> getTransactionsByCategoryId(String categoryId) async {
    return transactions.where((t) => t.categoryId == categoryId).toList();
  }

  @override
  Future<void> batchUpdateTransactionsCategory(
    Map<int, String> txIdToNewCategoryId, {
    bool markPendingSync = false,
  }) async {
    lastBatchUpdates = txIdToNewCategoryId;
    lastMarkPendingSync = markPendingSync;
  }
}

class FakeTransactionList extends TransactionList {
  final List<TransactionModel> added = [];

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    added.add(transaction);
  }
}

void main() {
  late FakeCategoryRepository fakeCategoryRepo;
  late FakeTransactionRepository fakeTxRepo;
  late FakeTransactionList fakeTxList;
  late bool notionSyncEnabled;
  late bool notionPushCalled;
  late bool transactionsChangedCalled;
  late LedgerGatewayImpl gateway;

  setUp(() {
    fakeCategoryRepo = FakeCategoryRepository();
    fakeTxRepo = FakeTransactionRepository();
    fakeTxList = FakeTransactionList();
    notionSyncEnabled = false;
    notionPushCalled = false;
    transactionsChangedCalled = false;

    gateway = LedgerGatewayImpl(
      categoryRepo: fakeCategoryRepo,
      transactionRepo: fakeTxRepo,
      transactionList: fakeTxList,
      isNotionSyncEnabled: () => notionSyncEnabled,
      pushNotionPendingChanges: () {
        notionPushCalled = true;
      },
      onTransactionsChanged: () {
        transactionsChangedCalled = true;
      },
    );
  });

  group('LedgerGatewayImpl 領域適配器測試', () {
    test('getActiveCategories 能正確過濾啟用中分類並支援收支篩選', () async {
      fakeCategoryRepo.categories = [
        CategoryModel(id: 'c1', name: '餐飲', iconCodePoint: 1, colorValue: 1, type: TransactionType.expense, isEnabled: true),
        CategoryModel(id: 'c2', name: '交通', iconCodePoint: 2, colorValue: 2, type: TransactionType.expense, isEnabled: false),
        CategoryModel(id: 'c3', name: '薪資', iconCodePoint: 3, colorValue: 3, type: TransactionType.income, isEnabled: true),
      ];

      final allActive = await gateway.getActiveCategories();
      expect(allActive.length, 2);
      expect(allActive.map((c) => c.name), containsAll(['餐飲', '薪資']));

      final expenseOnly = await gateway.getActiveCategories(isExpense: true);
      expect(expenseOnly.length, 1);
      expect(expenseOnly.first.name, '餐飲');

      final incomeOnly = await gateway.getActiveCategories(isExpense: false);
      expect(incomeOnly.length, 1);
      expect(incomeOnly.first.name, '薪資');
    });

    test('findCategoryByName 能不分大小寫比對分類名稱', () async {
      fakeCategoryRepo.categories = [
        CategoryModel(id: 'c1', name: 'Food', iconCodePoint: 1, colorValue: 1, type: TransactionType.expense, isEnabled: true),
      ];

      final found = await gateway.findCategoryByName('food');
      expect(found, isNotNull);
      expect(found!.id, 'c1');

      final notFound = await gateway.findCategoryByName('Unknown');
      expect(notFound, isNull);
    });

    test('getTransactionsByCategoryId 能將交易實體轉換為領域摘要', () async {
      final now = DateTime.now();
      fakeTxRepo.transactions = [
        TransactionModel(id: 101, title: '7-11', amount: 85, categoryId: 'cat_receipt', type: TransactionType.expense, date: now, createdAt: now),
        TransactionModel(id: 102, title: '全家', amount: 45, categoryId: 'cat_receipt', type: TransactionType.expense, date: now, createdAt: now),
        TransactionModel(id: 103, title: '其他', amount: 100, categoryId: 'other', type: TransactionType.expense, date: now, createdAt: now),
      ];

      final summaries = await gateway.getTransactionsByCategoryId('cat_receipt');
      expect(summaries.length, 2);
      expect(summaries[0].id, 101);
      expect(summaries[0].title, '7-11');
      expect(summaries[1].id, 102);
      expect(summaries[1].title, '全家');
    });

    test('createTransactions 能正確透過 TransactionList 新增交易並回傳視圖物件', () async {
      final drafts = [
        AITransactionDraft(item: '拿鐵咖啡', price: 65, store: '星巴克', categoryId: 'cat_food'),
      ];

      final viewItems = await gateway.createTransactions(drafts);
      expect(viewItems.length, 1);
      expect(viewItems.first.title, '星巴克');
      expect(viewItems.first.note, '拿鐵咖啡');
      expect(viewItems.first.amount, 65);
      expect(viewItems.first.categoryId, 'cat_food');

      expect(fakeTxList.added.length, 1);
      expect(fakeTxList.added.first.title, '星巴克');
      expect(fakeTxList.added.first.amount, 65);
    });

    test('batchUpdateCategories 在開啟 Notion 同步時正確通知背景推送並發出變更事件', () async {
      notionSyncEnabled = true;

      await gateway.batchUpdateCategories({101: 'food', 102: 'traffic'});

      expect(fakeTxRepo.lastBatchUpdates, {101: 'food', 102: 'traffic'});
      expect(fakeTxRepo.lastMarkPendingSync, isTrue);
      expect(notionPushCalled, isTrue);
      expect(transactionsChangedCalled, isTrue);
    });

    test('batchUpdateCategories 在未開啟 Notion 時不呼叫 Notion 推送', () async {
      notionSyncEnabled = false;

      await gateway.batchUpdateCategories({201: 'drinks'});

      expect(fakeTxRepo.lastBatchUpdates, {201: 'drinks'});
      expect(fakeTxRepo.lastMarkPendingSync, isFalse);
      expect(notionPushCalled, isFalse);
      expect(transactionsChangedCalled, isTrue);
    });
  });
}
