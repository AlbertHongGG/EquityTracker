import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/auto_bookkeeping/domain/models/notification_rule.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/default_notification_rules.dart';

void main() {
  group('NotificationRule Model & Serialization Tests', () {
    test('Rule serialization should use real booleans for Kotlin compatibility', () {
      const rule = NotificationRule(
        id: 'test_rule',
        name: '測試規則',
        packageNames: ['com.example.bank'],
        titleKeywords: ['銀行'],
        bodyKeywords: ['消費'],
        defaultTransactionTitle: '銀行刷卡',
        isEnabled: false,
        isSystemPreset: true,
      );

      final map = rule.toMap();
      expect(map['isEnabled'], isA<bool>());
      expect(map['isEnabled'], equals(false));
      expect(map['isSystemPreset'], isA<bool>());
      expect(map['isSystemPreset'], equals(true));

      // Test deserialization with booleans
      final fromMapBool = NotificationRule.fromMap(map);
      expect(fromMapBool.isEnabled, isFalse);
      expect(fromMapBool.isSystemPreset, isTrue);

      // Test deserialization backwards compatibility with 1 and 0
      final legacyMap = Map<String, dynamic>.from(map);
      legacyMap['isEnabled'] = 1;
      legacyMap['isSystemPreset'] = 0;
      final fromMapLegacy = NotificationRule.fromMap(legacyMap);
      expect(fromMapLegacy.isEnabled, isTrue);
      expect(fromMapLegacy.isSystemPreset, isFalse);
    });

    test('Default rules should all have valid structure', () {
      expect(defaultNotificationRules, isNotEmpty);
      for (final rule in defaultNotificationRules) {
        expect(rule.id, isNotEmpty);
        expect(rule.name, isNotEmpty);
        expect(rule.packageNames, isNotEmpty);
        expect(rule.titleKeywords, isNotEmpty);
        expect(rule.bodyKeywords, isNotEmpty);
        expect(rule.defaultTransactionTitle, isNotEmpty);
        expect(rule.isEnabled, isTrue);
        expect(rule.isSystemPreset, isTrue);
      }
    });
  });
}
