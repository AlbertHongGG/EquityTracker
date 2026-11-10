import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen/category_type_toggle.dart';

class FakeCategoryList extends CategoryList {
  final List<CategoryModel> categories;
  FakeCategoryList(this.categories);

  @override
  Future<List<CategoryModel>> build() async => categories;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoryTypeToggle 物理平移滑動膠囊測試', () {
    testWidgets('正確渲染 Expense 與 Income 標籤並觸發平移切換', (tester) async {
      TransactionType currentType = TransactionType.expense;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryTypeToggle(
                  selectedType: currentType,
                  onChanged: (newType) {
                    setState(() {
                      currentType = newType;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      // 點擊 Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(currentType, TransactionType.income);

      // 再次點擊 Expense
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      expect(currentType, TransactionType.expense);
    });
  });

  group('CategoryManagementScreen 無框化介面測試', () {
    testWidgets('完全不包含 AppBar 與返回箭頭，頂部包含滑動 Tab 與編輯按鈕', (tester) async {
      final mockCategories = [
        CategoryModel(
          id: 'cat1',
          name: '餐飲',
          iconCodePoint: 1,
          colorValue: 1,
          type: TransactionType.expense,
          isEnabled: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryListProvider.overrideWith(() => FakeCategoryList(mockCategories)),
          ],
          child: const MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 驗證完全沒有 AppBar
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Manage Categories'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);

      // 驗證頂部存在滑動 Tab
      expect(find.byType(CategoryTypeToggle), findsOneWidget);

      // 驗證存在編輯按鈕 (未編輯時為 edit_outlined)
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // 點擊編輯按鈕
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // 驗證變更為 check_rounded
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
