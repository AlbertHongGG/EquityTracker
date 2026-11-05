import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/auto_bookkeeping_repository.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/raw_notification_data.dart';
import 'package:equity_tracker/features/auto_bookkeeping/services/notification_auto_bookkeeping_service.dart';

final notificationAutoBookkeepingServiceProvider = Provider<NotificationAutoBookkeepingService>((ref) {
  final repo = ref.watch(autoBookkeepingRepositoryProvider);
  return NotificationAutoBookkeepingService(ref, repo);
});

class AutoBookkeepingState {
  final bool isPermissionGranted;
  final bool isEnabled;
  final bool notifyOnSuccess;
  final String? defaultCategoryId;
  final List<NotificationRule> rules;

  const AutoBookkeepingState({
    this.isPermissionGranted = false,
    this.isEnabled = true,
    this.notifyOnSuccess = true,
    this.defaultCategoryId,
    this.rules = const [],
  });

  /// 真實啟用狀態 (SSOT)：同時滿足「系統已授予通知存取權」與「偏好設定為開啟」
  bool get isActive => isEnabled && isPermissionGranted;

  AutoBookkeepingState copyWith({
    bool? isPermissionGranted,
    bool? isEnabled,
    bool? notifyOnSuccess,
    String? defaultCategoryId,
    bool clearDefaultCategory = false,
    List<NotificationRule>? rules,
  }) {
    return AutoBookkeepingState(
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isEnabled: isEnabled ?? this.isEnabled,
      notifyOnSuccess: notifyOnSuccess ?? this.notifyOnSuccess,
      defaultCategoryId: clearDefaultCategory ? null : (defaultCategoryId ?? this.defaultCategoryId),
      rules: rules ?? this.rules,
    );
  }
}

class AutoBookkeepingNotifier extends AsyncNotifier<AutoBookkeepingState> {
  bool _pendingEnableOnGrant = false;

  @override
  Future<AutoBookkeepingState> build() async {
    final service = ref.read(notificationAutoBookkeepingServiceProvider);
    final repo = ref.read(autoBookkeepingRepositoryProvider);

    final isPermissionGranted = await service.isPermissionGranted();
    final isEnabled = await repo.isEnabled();
    final notifyOnSuccess = await repo.notifyOnSuccess();
    final defaultCat = await repo.getDefaultCategoryId();
    final rules = await repo.getRules();

    return AutoBookkeepingState(
      isPermissionGranted: isPermissionGranted,
      isEnabled: isEnabled,
      notifyOnSuccess: notifyOnSuccess,
      defaultCategoryId: defaultCat,
      rules: rules,
    );
  }

  Future<void> checkPermission() async {
    final service = ref.read(notificationAutoBookkeepingServiceProvider);
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    final isGranted = await service.isPermissionGranted();

    bool targetEnabled = state.value?.isEnabled ?? true;
    if (isGranted && _pendingEnableOnGrant) {
      _pendingEnableOnGrant = false;
      targetEnabled = true;
      await repo.setEnabled(true);
    }

    state = AsyncData(state.value!.copyWith(
      isPermissionGranted: isGranted,
      isEnabled: targetEnabled,
    ));
  }

  Future<void> openPermissionSettings() async {
    final service = ref.read(notificationAutoBookkeepingServiceProvider);
    await service.openPermissionSettings();
  }

  /// 使用者在抽屜點擊「設定權限」時呼叫：記錄待啟用意圖，並開啟系統設定頁
  Future<void> requestPermissionForEnabling() async {
    _pendingEnableOnGrant = true;
    final service = ref.read(notificationAutoBookkeepingServiceProvider);
    await service.openPermissionSettings();
  }

  Future<void> toggleEnabled(bool enabled) async {
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    await repo.setEnabled(enabled);
    state = AsyncData(state.value!.copyWith(isEnabled: enabled));
  }

  Future<void> toggleNotifyOnSuccess(bool notify) async {
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    await repo.setNotifyOnSuccess(notify);
    state = AsyncData(state.value!.copyWith(notifyOnSuccess: notify));
  }

  Future<void> setDefaultCategoryId(String? categoryId) async {
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    await repo.setDefaultCategoryId(categoryId);
    state = AsyncData(state.value!.copyWith(
      defaultCategoryId: categoryId,
      clearDefaultCategory: categoryId == null,
    ));
  }

  Future<void> toggleRule(String ruleId, bool isEnabled) async {
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    final currentRules = state.value!.rules;
    final updated = currentRules.map((r) {
      if (r.id == ruleId) {
        return r.copyWith(isEnabled: isEnabled);
      }
      return r;
    }).toList();

    await repo.saveRules(updated);
    state = AsyncData(state.value!.copyWith(rules: updated));
  }

  Future<void> saveRule(NotificationRule rule) async {
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    final currentRules = List<NotificationRule>.from(state.value!.rules);
    final index = currentRules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      currentRules[index] = rule;
    } else {
      currentRules.add(rule);
    }
    await repo.saveRules(currentRules);
    state = AsyncData(state.value!.copyWith(rules: currentRules));
  }

  Future<void> deleteRule(String ruleId) async {
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    final currentRules = state.value!.rules.where((r) => r.id != ruleId).toList();
    await repo.saveRules(currentRules);
    state = AsyncData(state.value!.copyWith(rules: currentRules));
  }

  Future<void> resetRules() async {
    final repo = ref.read(autoBookkeepingRepositoryProvider);
    await repo.resetToDefaultRules();
    final fresh = await repo.getRules();
    state = AsyncData(state.value!.copyWith(rules: fresh));
  }

  Future<bool> simulateNotification(RawNotificationData raw) async {
    final service = ref.read(notificationAutoBookkeepingServiceProvider);
    return await service.simulateNotification(raw);
  }
}

final autoBookkeepingNotifierProvider = AsyncNotifierProvider<AutoBookkeepingNotifier, AutoBookkeepingState>(
  AutoBookkeepingNotifier.new,
);
