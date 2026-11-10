import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/app/screens/splash_screen.dart';
import 'package:equity_tracker/features/app/screens/home_screen.dart';
import 'package:equity_tracker/features/settings/screens/settings_screen.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_transaction/add_edit_transaction_screen.dart';
import 'package:equity_tracker/features/transaction/screens/recurring_transactions/recurring_transactions_screen.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_recurring_transaction/add_edit_recurring_transaction_screen.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen.dart';
import 'package:equity_tracker/features/category/screens/add_category_screen.dart';
import 'package:equity_tracker/core/router/global_navigator.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';
import 'package:equity_tracker/core/logging/presentation/screens/system_notification_log_screen.dart';
import 'package:equity_tracker/core/logging/presentation/screens/api_log_viewer_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: globalNavigatorKey,
    initialLocation: '/',
    errorBuilder: (context, state) => const HomeScreen(),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transaction = extra?['transaction'] as TransactionModel?;
          final initialDate = extra?['initialDate'] as DateTime?;
          return AddEditTransactionScreen(
            transaction: transaction,
            initialDate: initialDate,
          );
        },
      ),
      GoRoute(
        path: '/recurring-transactions',
        builder: (context, state) => const RecurringTransactionModelsScreen(),
      ),
      GoRoute(
        path: '/add-recurring-transaction',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transaction = extra?['transaction'] as RecurringTransactionModel?;
          return AddEditRecurringTransactionModelScreen(
            transaction: transaction,
          );
        },
      ),
      GoRoute(
        path: '/manage-categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/add-category',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final categoryToEdit = extra?['categoryToEdit'] as CategoryModel?;
          final initialType = extra?['initialType'] as TransactionType?;
          return AddCategoryScreen(
            categoryToEdit: categoryToEdit,
            initialType: initialType,
          );
        },
      ),
      GoRoute(
        path: '/logs/notifications',
        builder: (context, state) => const SystemNotificationLogScreen(),
      ),
      GoRoute(
        path: '/logs/api',
        builder: (context, state) => const ApiLogViewerScreen(),
      ),
    ],
  );
});
