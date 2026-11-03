import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/default_notification_rules.dart';

class AutoBookkeepingRepository {
  static const String _keyEnabled = 'auto_bookkeeping_enabled';
  static const String _keyNotifyOnSuccess = 'auto_bookkeeping_notify_on_success';
  static const String _keyDefaultCategory = 'auto_bookkeeping_default_category';
  static const String _keyCustomRules = 'auto_bookkeeping_rules_json';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // 預設為 true（開箱即用）
    return prefs.getBool(_keyEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  Future<bool> notifyOnSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifyOnSuccess) ?? true;
  }

  Future<void> setNotifyOnSuccess(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifyOnSuccess, value);
  }

  Future<String?> getDefaultCategoryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultCategory);
  }

  Future<void> setDefaultCategoryId(String? categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    if (categoryId == null) {
      await prefs.remove(_keyDefaultCategory);
    } else {
      await prefs.setString(_keyDefaultCategory, categoryId);
    }
  }

  Future<List<NotificationRule>> getRules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCustomRules);
    if (jsonStr == null || jsonStr.isEmpty) {
      // 首次初始化時，將預設規則寫入 SharedPreferences，確保 Native 端同步
      final list = List<NotificationRule>.from(defaultNotificationRules);
      await saveRules(list);
      return list;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((m) => NotificationRule.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return List.from(defaultNotificationRules);
    }
  }

  Future<void> saveRules(List<NotificationRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final maps = rules.map((r) => r.toMap()).toList();
    await prefs.setString(_keyCustomRules, jsonEncode(maps));
  }

  Future<void> resetToDefaultRules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomRules);
    // 重新寫入預設規則
    await saveRules(List.from(defaultNotificationRules));
  }

  Future<Map<String, dynamic>> exportState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_keyEnabled) ?? true,
      'notify_on_success': prefs.getBool(_keyNotifyOnSuccess) ?? true,
      'default_category': prefs.getString(_keyDefaultCategory),
      'rules_json': prefs.getString(_keyCustomRules),
    };
  }

  Future<void> importState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    if (state.containsKey('enabled') && state['enabled'] is bool) {
      await prefs.setBool(_keyEnabled, state['enabled'] as bool);
    }
    if (state.containsKey('notify_on_success') && state['notify_on_success'] is bool) {
      await prefs.setBool(_keyNotifyOnSuccess, state['notify_on_success'] as bool);
    }
    if (state.containsKey('default_category')) {
      final cat = state['default_category'] as String?;
      if (cat != null) {
        await prefs.setString(_keyDefaultCategory, cat);
      } else {
        await prefs.remove(_keyDefaultCategory);
      }
    }
    if (state.containsKey('rules_json') && state['rules_json'] is String) {
      await prefs.setString(_keyCustomRules, state['rules_json'] as String);
    }
  }
}
