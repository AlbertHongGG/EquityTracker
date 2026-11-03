import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/router/global_navigator.dart';
import 'package:equity_tracker/core/router/app_router.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/notion_sync/services/notion_sync_service.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/auto_bookkeeping_repository.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/raw_notification_data.dart';

class NotificationAutoBookkeepingService {
  static const MethodChannel _channel = MethodChannel('com.jasonhong.equitytracker/notification_listener');

  final Ref _ref;
  final AutoBookkeepingRepository _repository;
  bool _isInitialized = false;

  NotificationAutoBookkeepingService(this._ref, this._repository);

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 確保規則已預載同步至共用 SharedPreferences
    await _repository.getRules();

    _channel.setMethodCallHandler(_handleNativeCall);

    // 檢查冷啟動時是否有因點擊通知而要求編輯的交易
    await checkInitialEditRequest();
  }

  Future<bool> isPermissionGranted() async {
    try {
      final bool? res = await _channel.invokeMethod<bool>('isPermissionGranted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openPermissionSettings');
    } catch (_) {}
  }

  Future<void> checkInitialEditRequest() async {
    try {
      final dynamic txId = await _channel.invokeMethod('getInitialEditTxId');
      if (txId != null && txId is num && txId > 0) {
        await _navigateToEditScreen(txId.toInt());
      }
    } catch (_) {}
  }

  Future<bool> simulateNotification(RawNotificationData raw) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('simulateNotification', raw.toMap());
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onTransactionAdded':
        // 原生管線已直接寫入 SQLite，在此通知 Riverpod 刷新畫面
        _ref.invalidate(transactionListProvider);
        
        // 若啟用 Notion 同步，非同步推播更新
        final notionConfig = _ref.read(notionConfigControllerProvider);
        if (notionConfig.isEnabled) {
          Future.microtask(() {
            _ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true);
          });
        }
        break;

      case 'onEditTransactionRequested':
        final args = call.arguments;
        if (args is Map && args['id'] != null) {
          final txId = (args['id'] as num).toInt();
          await _navigateToEditScreen(txId);
        }
        break;
    }
  }

  Future<void> _navigateToEditScreen(int txId) async {
    final tx = await _ref.read(transactionRepositoryProvider).getTransactionById(txId);
    if (tx == null) return;

    _ref.read(goRouterProvider).push('/add-transaction', extra: {'transaction': tx});
  }
}
