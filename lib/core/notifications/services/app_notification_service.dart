import 'package:intl/intl.dart';
import 'package:equity_tracker/core/notifications/services/system_notification_service.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class AppNotificationService {
  final SystemNotificationService _systemNotificationService;
  final CategoryRepository _categoryRepository;

  AppNotificationService(
    this._systemNotificationService,
    this._categoryRepository,
  );

  Future<void> showTransactionAddedNotification(
    TransactionModel transaction,
  ) async {
    final amountStr = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    ).format(transaction.amount);
    final typeStr = transaction.type.isIncome ? '收入' : '支出';

    // Fetch category name
    String categoryName = '未分類';
    final category = await _categoryRepository.getCategoryById(
      transaction.categoryId,
    );
    if (category != null) {
      categoryName = category.name;
    }

    final body = '已成功新增一筆 [$categoryName] $typeStr $amountStr';

    await _systemNotificationService.showNotification(
      id: transaction.id ?? transaction.hashCode,
      title: '自動記帳：${transaction.title}',
      body: body,
      payload: transaction.id?.toString(),
    );
  }
}
