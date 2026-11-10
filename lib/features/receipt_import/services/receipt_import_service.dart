import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/notion_sync/services/notion_sync_service.dart';
import 'package:equity_tracker/features/receipt_import/domain/models/receipt_payload.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';

class ReceiptImportService {
  static const MethodChannel _channel = MethodChannel('com.jasonhong.equitytracker/receipt_import');

  final Ref _ref;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  bool _isInitialized = false;

  ReceiptImportService(
    this._ref,
    this._categoryRepository,
    this._transactionRepository,
  );

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler(_handleNativeCall);

    try {
      final initialData = await _channel.invokeMethod<String>('getInitialReceiptData');
      if (initialData != null && initialData.trim().isNotEmpty) {
        await handleRawData(initialData);
      }
    } catch (e) {
      debugPrint('ReceiptImportService check initial data error: $e');
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onReceiptDataReceived':
        final raw = call.arguments;
        if (raw is String && raw.trim().isNotEmpty) {
          await handleRawData(raw);
        }
        break;
      default:
        break;
    }
  }

  Future<String> getOrCreateInvoiceCategoryId() async {
    final categories = await _categoryRepository.getCategories();
    final existing = categories.where(
      (c) => c.name == '發票' && c.type == TransactionType.expense,
    );
    if (existing.isNotEmpty) {
      return existing.first.id;
    }

    final newCat = CategoryModel(
      id: const Uuid().v4(),
      name: '發票',
      iconCodePoint: Icons.receipt_long.codePoint,
      iconFontFamily: 'MaterialIcons',
      iconFontPackage: null,
      colorValue: Colors.blueGrey.toARGB32(),
      type: TransactionType.expense,
      isSystem: true,
      isEnabled: true,
      order: 0,
    );
    await _categoryRepository.addCategoryModel(newCat);
    return newCat.id;
  }

  Future<bool> handleRawData(String raw) async {
    try {
      String jsonStr = raw.trim();

      // 若為 URL Scheme (如 equitytracker://receipt/import?data=...)
      if (jsonStr.startsWith('equitytracker://') || jsonStr.startsWith('http://') || jsonStr.startsWith('https://')) {
        final uri = Uri.tryParse(jsonStr);
        if (uri != null && uri.queryParameters.containsKey('data')) {
          jsonStr = uri.queryParameters['data']!;
        }
      }

      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map) {
        return false;
      }

      final payload = ReceiptPayload.fromMap(Map<String, dynamic>.from(decoded));
      final count = await importReceiptPayload(payload);
      return count > 0;
    } catch (e) {
      debugPrint('ReceiptImportService handleRawData error: $e');
      return false;
    }
  }

  Future<int> importReceiptPayload(ReceiptPayload payload) async {
    if (payload.items.isEmpty) {
      return 0;
    }

    final categoryId = await getOrCreateInvoiceCategoryId();
    final merchantTitle = payload.merchant?.trim().isNotEmpty == true
        ? payload.merchant!.trim()
        : '收據消費';
    final date = payload.date ?? DateTime.now();
    final isNotionEnabled = _ref.read(notionConfigControllerProvider).isEnabled;

    int insertedCount = 0;
    for (final item in payload.items) {
      final amount = item.amount.round().toInt();
      final note = '${item.name} x${item.quantity}';

      final transaction = TransactionModel(
        title: merchantTitle,
        amount: amount,
        type: TransactionType.expense,
        categoryId: categoryId,
        date: date,
        createdAt: DateTime.now(),
        note: note,
        syncStatus: isNotionEnabled ? SyncStatus.pendingCreate : SyncStatus.synced,
      );

      await _transactionRepository.insertTransaction(transaction);
      insertedCount++;
    }

    // 刷新交易列表
    _ref.invalidate(transactionListProvider);

    // 若有啟用 Notion 同步，觸發背景同步
    if (isNotionEnabled) {
      Future.microtask(() {
        _ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true);
      });
    }

    // 透過專案內部 InAppNotificationService 彈出通知 (無 Emoji，文案精簡)
    _ref.read(inAppNotificationServiceProvider).showSuccess(
      '已成功匯入 $insertedCount 筆收據帳務',
    );

    return insertedCount;
  }
}

final receiptImportServiceProvider = Provider<ReceiptImportService>((ref) {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return ReceiptImportService(ref, categoryRepo, transactionRepo);
});
