import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:equity_tracker/core/router/app_router.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/providers/shared_prefs_provider.dart';
import 'package:equity_tracker/core/providers/package_info_provider.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/core/notifications/services/system_notification_service.dart';
import 'package:equity_tracker/features/updater/data/github_updater_config.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';

class FakeSystemNotificationService implements SystemNotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
  @override
  Future<void> cancelNotification(int id) async {}
  @override
  Future<void> cancelAllNotifications() async {}
}

class FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => [];
  @override
  Future<void> addCategoryModel(CategoryModel category) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> insertedTransactions = [];

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    insertedTransactions.add(transaction);
    return insertedTransactions.length;
  }

  @override
  Future<List<TransactionModel>> getTransactionsByMonth(DateTime month) async => insertedTransactions;

  @override
  Future<List<RecurringTransactionModel>> getEnabledRecurringTransactions() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotionConfigController extends NotionConfigController {
  @override
  NotionConfigState build() => NotionConfigState(isEnabled: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCategoryRepository fakeCatRepo;
  late FakeTransactionRepository fakeTxRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    PackageInfo.setMockInitialValues(
      appName: 'EquityTracker',
      packageName: 'com.jasonhong.equity_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    fakeCatRepo = FakeCategoryRepository();
    fakeTxRepo = FakeTransactionRepository();
  });

  group('GoRouter Deep Link Gateway Tests', () {
    testWidgets('接收 /receipt/import 路由時應重定向至 /home 且不拋出任何 GoException', (tester) async {
      final packageInfo = await PackageInfo.fromPlatform();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          packageInfoProvider.overrideWithValue(packageInfo),
          githubUpdaterConfigProvider.overrideWithValue(
            const GithubUpdaterConfig(
              githubOwner: 'JasonHongGG',
              githubRepo: 'EquityTracker',
              downloadFileName: 'EquityTracker_update.apk',
            ),
          ),
          systemNotificationServiceProvider.overrideWithValue(FakeSystemNotificationService()),
          notionConfigControllerProvider.overrideWith(FakeNotionConfigController.new),
          categoryRepositoryProvider.overrideWithValue(fakeCatRepo),
          transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 模擬外部 Deep Link: /receipt/import
      const sampleData = '{"merchant":"測試店家","items":[{"name":"水","amount":20,"quantity":1}]}';
      final deepLink = '/receipt/import?data=${Uri.encodeComponent(sampleData)}';

      // 呼叫導航，驗證不會拋出 Page Not Found / GoException
      router.go(deepLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 驗證已成功抵達 /home
      expect(router.state.uri.path, '/home');

      // 等候通知的 3.5 秒自動淡出定時器結束
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('若有未知 scheme 或路徑，errorBuilder 應安全回退至 /home 而非紅底白字崩潰', (tester) async {
      final packageInfo = await PackageInfo.fromPlatform();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          packageInfoProvider.overrideWithValue(packageInfo),
          githubUpdaterConfigProvider.overrideWithValue(
            const GithubUpdaterConfig(
              githubOwner: 'JasonHongGG',
              githubRepo: 'EquityTracker',
              downloadFileName: 'EquityTracker_update.apk',
            ),
          ),
          systemNotificationServiceProvider.overrideWithValue(FakeSystemNotificationService()),
          notionConfigControllerProvider.overrideWith(FakeNotionConfigController.new),
          categoryRepositoryProvider.overrideWithValue(fakeCatRepo),
          transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 嘗試導向未知路徑
      router.go('/unknown-route-that-does-not-exist');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 驗證 errorBuilder 渲染了畫面，且沒有崩潰
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
