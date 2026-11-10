import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/transaction/widgets/premium_dashboard_header/premium_header_delegate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumHeaderDelegate 緊湊化與像素級防抖測試', () {
    test('maxExtent 正確設定為緊湊高度 175.0', () {
      final delegate = PremiumHeaderDelegate(
        totalBalance: 12500,
        totalIncome: 20000,
        totalExpense: 7500,
        monthlyBalance: 12500,
        monthlyIncome: 20000,
        monthlyExpense: 7500,
        topPadding: 30,
        selectedDate: DateTime(2026, 11, 1),
        isMonthlyView: false,
        onToggleView: () {},
        onPreviousMonth: () {},
        onNextMonth: () {},
        currencySymbol: '\$',
        isPrivacyMode: false,
      );

      expect(delegate.maxExtent, 175.0);
    });

    testWidgets('在明碼與隱蔽模式切換時，Total Balance 標題垂直座標像素級完全一致（零抖動）', (tester) async {
      Widget buildHeader(bool isPrivacy) {
        return MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PremiumHeaderDelegate(
                    totalBalance: 12500,
                    totalIncome: 20000,
                    totalExpense: 7500,
                    monthlyBalance: 12500,
                    monthlyIncome: 20000,
                    monthlyExpense: 7500,
                    topPadding: 0,
                    selectedDate: DateTime(2026, 11, 1),
                    isMonthlyView: false,
                    onToggleView: () {},
                    onPreviousMonth: () {},
                    onNextMonth: () {},
                    currencySymbol: '\$',
                    isPrivacyMode: isPrivacy,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // 1. 先以明碼模式渲染
      await tester.pumpWidget(buildHeader(false));
      await tester.pumpAndSettle();

      final normalTitleFinder = find.text('Total Balance');
      expect(normalTitleFinder, findsOneWidget);
      final normalOffset = tester.getTopLeft(normalTitleFinder);

      // 2. 切換為隱蔽模式 (****)
      await tester.pumpWidget(buildHeader(true));
      await tester.pumpAndSettle();

      final privacyTitleFinder = find.text('Total Balance');
      expect(privacyTitleFinder, findsOneWidget);
      final privacyOffset = tester.getTopLeft(privacyTitleFinder);

      // 3. 斷言：Y 座標百分之百相等，無任何像素位移！
      expect(privacyOffset.dy, equals(normalOffset.dy));
      expect(privacyOffset.dx, equals(normalOffset.dx));
    });
  });
}
