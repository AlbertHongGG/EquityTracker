import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/shared_prefs_provider.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/ai/infrastructure/gateways/ledger_gateway_impl.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/ai_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/providers/provider_factory.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_session_controller.dart';

class MockAIProvider implements AIProvider {
  @override
  String get name => 'mock';

  @override
  Future<GenerateResponse> generate(GenerateRequest request) async {
    // 模擬網路延遲
    await Future.delayed(const Duration(milliseconds: 50));
    // 若為 IntentRouter 的 Prompt
    if (request.prompt.contains('intent')) {
      return GenerateResponse(text: '{"intent": "add_transaction", "explanation": "記帳"}');
    }
    // 預設回傳空的 JSON 物件
    return GenerateResponse(text: '[]');
  }

  @override
  Stream<GenerateResponse> generateStream(GenerateRequest request) async* {
    await Future.delayed(const Duration(milliseconds: 20));
    final systemInst = request.systemPrompt ?? '';

    if (systemInst.contains('意圖識別路由器')) {
      yield GenerateResponse(text: '{"intent": "add_transaction", "explanation": "記帳"}');
    } else if (systemInst.contains('記帳資訊解析助手')) {
      yield GenerateResponse(text: '[{"item": "便當", "price": 100, "store": "便當店", "categoryId": "food"}]');
    } else if (systemInst.contains('店家名稱推斷助手')) {
      yield GenerateResponse(text: '{"isCertain": true, "storeName": "便當店", "options": []}');
    } else if (systemInst.contains('資料審查助手')) {
      yield GenerateResponse(text: '{"isValid": true, "question": null}');
    } else {
      yield GenerateResponse(text: '{"isValid": true}');
    }
  }
}

class FakeCategoryRepo extends CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async {
    return [
      CategoryModel(id: 'food', name: '餐飲', iconCodePoint: 1, colorValue: 1, type: TransactionType.expense, isEnabled: true),
      CategoryModel(id: 'other', name: '其他', iconCodePoint: 2, colorValue: 2, type: TransactionType.expense, isEnabled: true),
    ];
  }
}

class FakeTxRepo extends TransactionRepository {
  @override
  Future<List<TransactionModel>> getTransactionsByCategoryId(String categoryId) async => [];

  @override
  Future<void> batchUpdateTransactionsCategory(Map<int, String> updates, {bool markPendingSync = false}) async {}
}

class FakeTxList extends TransactionList {
  final List<TransactionModel> added = [];

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    added.add(transaction);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AI 端到端生命週期測試：跨越非同步 turns 絕不發生 Ref disposed 異常', () async {
    final fakeCategoryRepo = FakeCategoryRepo();
    final fakeTxRepo = FakeTxRepo();
    final fakeTxList = FakeTxList();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        aiProviderProvider.overrideWithValue(MockAIProvider()),
        ledgerGatewayProvider.overrideWithValue(
          LedgerGatewayImpl(
            categoryRepo: fakeCategoryRepo,
            transactionRepo: fakeTxRepo,
            transactionList: fakeTxList,
            isNotionSyncEnabled: () => false,
            pushNotionPendingChanges: () {},
            onTransactionsChanged: () {},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 取得 AISessionController 並送出記帳訊息
    final sessionNotifier = container.read(aiSessionControllerProvider.notifier);

    // 發送非同步輸入
    await sessionNotifier.sendMessage('晚餐買便當100元');

    final state = container.read(aiSessionControllerProvider);

    // 斷言：處理已完成且未掛起
    expect(state.isProcessing, isFalse);

    // 斷言：絕無拋出任何 Ref 已被 disposed 的例外訊息
    for (final msg in state.messages) {
      expect(msg.text, isNot(contains('Cannot use the Ref of Provider')));
      expect(msg.text, isNot(contains('after it has been disposed')));
    }

    // 斷言：成功建立交易
    expect(fakeTxList.added.length, 1);
    expect(fakeTxList.added.first.amount, 100);
  });
}
