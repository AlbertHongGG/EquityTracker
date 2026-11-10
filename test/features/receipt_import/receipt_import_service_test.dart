import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';
import 'package:equity_tracker/core/notifications/controllers/notification_controller.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/receipt_import/domain/models/receipt_payload.dart';
import 'package:equity_tracker/features/receipt_import/services/receipt_import_service.dart';

class FakeNotionConfigController extends NotionConfigController {
  @override
  NotionConfigState build() => NotionConfigState(isEnabled: false);
}

class FakeCategoryRepository implements CategoryRepository {
  final List<CategoryModel> categories = [];

  @override
  Future<List<CategoryModel>> getCategories() async => List.unmodifiable(categories);

  @override
  Future<void> addCategoryModel(CategoryModel category) async {
    categories.add(category);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> insertedTransactions = [];

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    final id = insertedTransactions.length + 1;
    insertedTransactions.add(transaction.copyWith(id: id));
    return id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCategoryRepository fakeCategoryRepo;
  late FakeTransactionRepository fakeTxRepo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeCategoryRepo = FakeCategoryRepository();
    fakeTxRepo = FakeTransactionRepository();

    container = ProviderContainer(
      overrides: [
        notionConfigControllerProvider.overrideWith(FakeNotionConfigController.new),
        categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
        transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ReceiptImportService Tests', () {
    test('細項個別記帳：title為店名、note為品項x個數、分類統一為發票、觸發通知', () async {
      final service = container.read(receiptImportServiceProvider);

      final payload = ReceiptPayload(
        merchant: '全聯福利中心',
        date: DateTime.parse('2026-11-10T12:00:00.000'),
        items: const [
          ReceiptItem(name: '林鳳營鮮乳', amount: 95, quantity: 1),
          ReceiptItem(name: '舒潔衛生紙', amount: 120, quantity: 2),
        ],
      );

      final count = await service.importReceiptPayload(payload);

      expect(count, 2);
      expect(fakeTxRepo.insertedTransactions.length, 2);

      // 第一筆檢驗
      final tx1 = fakeTxRepo.insertedTransactions[0];
      expect(tx1.title, '全聯福利中心');
      expect(tx1.amount, 95);
      expect(tx1.note, '林鳳營鮮乳 x1');
      expect(tx1.type, TransactionType.expense);
      expect(tx1.date, DateTime.parse('2026-11-10T12:00:00.000'));

      // 第二筆檢驗
      final tx2 = fakeTxRepo.insertedTransactions[1];
      expect(tx2.title, '全聯福利中心');
      expect(tx2.amount, 120);
      expect(tx2.note, '舒潔衛生紙 x2');

      // 檢查分類已自動建立且指派
      final invoiceCat = fakeCategoryRepo.categories.firstWhere((c) => c.name == '發票');
      expect(tx1.categoryId, invoiceCat.id);
      expect(tx2.categoryId, invoiceCat.id);

      // 檢查通知元件通知 (無 Emoji，文字精確為「已成功匯入 2 筆收據帳務」)
      final notification = container.read(notificationControllerProvider);
      expect(notification, isNotNull);
      expect(notification!.type, NotificationType.success);
      expect(notification.message, '已成功匯入 2 筆收據帳務');
    });

    test('無店家時 title 預設為 收據消費', () async {
      final service = container.read(receiptImportServiceProvider);

      final payload = const ReceiptPayload(
        merchant: null,
        items: [
          ReceiptItem(name: '早餐三明治', amount: 45, quantity: 1),
        ],
      );

      final count = await service.importReceiptPayload(payload);

      expect(count, 1);
      final tx = fakeTxRepo.insertedTransactions.first;
      expect(tx.title, '收據消費');
      expect(tx.note, '早餐三明治 x1');
      expect(tx.amount, 45);
    });

    test('handleRawData 支援 Deep Link 格式與 JSON', () async {
      final service = container.read(receiptImportServiceProvider);

      const rawJson = '{"merchant":"7-Eleven","items":[{"name":"黑咖啡","amount":40,"quantity":1}]}';
      final uri = 'equitytracker://receipt/import?data=${Uri.encodeComponent(rawJson)}';

      final success = await service.handleRawData(uri);
      expect(success, isTrue);
      expect(fakeTxRepo.insertedTransactions.length, 1);

      final tx = fakeTxRepo.insertedTransactions.first;
      expect(tx.title, '7-Eleven');
      expect(tx.note, '黑咖啡 x1');
      expect(tx.amount, 40);

      final notification = container.read(notificationControllerProvider);
      expect(notification!.message, '已成功匯入 1 筆收據帳務');
    });
  });
}
