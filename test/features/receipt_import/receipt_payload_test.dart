import 'package:flutter_test/flutter_test.dart';
import 'package:equity_tracker/features/receipt_import/domain/models/receipt_payload.dart';

void main() {
  group('ReceiptPayload Unit Tests', () {
    test('應正確解析包含店家與多筆品項的標準 JSON', () {
      final jsonMap = {
        'merchant': '全聯福利中心',
        'date': '2026-11-10T12:30:00.000',
        'items': [
          {'name': '林鳳營鮮乳', 'amount': 95, 'quantity': 1},
          {'name': '舒潔抽取式衛生紙', 'amount': 120, 'quantity': 2},
        ],
      };

      final payload = ReceiptPayload.fromMap(jsonMap);

      expect(payload.merchant, '全聯福利中心');
      expect(payload.date, DateTime.parse('2026-11-10T12:30:00.000'));
      expect(payload.items.length, 2);
      expect(payload.items[0].name, '林鳳營鮮乳');
      expect(payload.items[0].amount, 95);
      expect(payload.items[0].quantity, 1);
      expect(payload.items[1].name, '舒潔抽取式衛生紙');
      expect(payload.items[1].amount, 120);
      expect(payload.items[1].quantity, 2);
    });

    test('缺少店家與日期時應優雅容錯為 null', () {
      final jsonMap = {
        'items': [
          {'name': '咖啡', 'amount': 60},
        ],
      };

      final payload = ReceiptPayload.fromMap(jsonMap);

      expect(payload.merchant, isNull);
      expect(payload.date, isNull);
      expect(payload.items.length, 1);
      expect(payload.items[0].name, '咖啡');
      expect(payload.items[0].amount, 60);
      expect(payload.items[0].quantity, 1);
    });

    test('金額與數量格式多樣性容錯測試 (字串數字、浮點數、別名)', () {
      final jsonMap = {
        'store': '7-Eleven',
        'items': [
          {'title': '御飯糰', 'price': '35.4', 'qty': '3'},
          {'item': '無糖綠茶', 'subtotal': 25.8, 'count': 0},
        ],
      };

      final payload = ReceiptPayload.fromMap(jsonMap);

      expect(payload.merchant, '7-Eleven');
      expect(payload.items.length, 2);

      // 第一項
      expect(payload.items[0].name, '御飯糰');
      expect(payload.items[0].amount, 35.4);
      expect(payload.items[0].quantity, 3);

      // 第二項 (count: 0 應自動修正為最低 1)
      expect(payload.items[1].name, '無糖綠茶');
      expect(payload.items[1].amount, 25.8);
      expect(payload.items[1].quantity, 1);
    });

    test('無品項空陣列容錯', () {
      final jsonMap = <String, dynamic>{
        'merchant': 'Taxi',
        'items': [],
      };

      final payload = ReceiptPayload.fromMap(jsonMap);
      expect(payload.merchant, 'Taxi');
      expect(payload.items, isEmpty);
    });
  });
}
