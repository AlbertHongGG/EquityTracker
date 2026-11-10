class ReceiptItem {
  final String name;
  final num amount;
  final int quantity;

  const ReceiptItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
  });

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    final rawName = map['name'] ?? map['title'] ?? map['item'];
    final name = rawName?.toString().trim().isNotEmpty == true
        ? rawName.toString().trim()
        : '未知名稱';

    final rawAmount = map['amount'] ?? map['price'] ?? map['subtotal'] ?? 0;
    final num parsedAmount;
    if (rawAmount is num) {
      parsedAmount = rawAmount;
    } else {
      parsedAmount = num.tryParse(rawAmount.toString().replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
    }

    final rawQty = map['quantity'] ?? map['qty'] ?? map['count'] ?? 1;
    final int parsedQty;
    if (rawQty is num) {
      parsedQty = rawQty.toInt();
    } else {
      parsedQty = int.tryParse(rawQty.toString()) ?? 1;
    }

    return ReceiptItem(
      name: name,
      amount: parsedAmount,
      quantity: parsedQty > 0 ? parsedQty : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'quantity': quantity,
    };
  }
}

class ReceiptPayload {
  final String? merchant;
  final DateTime? date;
  final List<ReceiptItem> items;

  const ReceiptPayload({
    this.merchant,
    this.date,
    this.items = const [],
  });

  factory ReceiptPayload.fromMap(Map<String, dynamic> map) {
    final rawMerchant = map['merchant'] ?? map['store'] ?? map['shop'];
    final merchant = rawMerchant?.toString().trim().isNotEmpty == true
        ? rawMerchant.toString().trim()
        : null;

    DateTime? parsedDate;
    final rawDate = map['date'] ?? map['time'] ?? map['timestamp'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        parsedDate = rawDate;
      } else if (rawDate is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      } else if (rawDate is String && rawDate.trim().isNotEmpty) {
        parsedDate = DateTime.tryParse(rawDate.trim());
      }
    }

    final rawItems = map['items'] ?? map['details'] ?? map['list'];
    final List<ReceiptItem> items = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(ReceiptItem.fromMap(item));
        } else if (item is Map) {
          items.add(ReceiptItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ReceiptPayload(
      merchant: merchant,
      date: parsedDate,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchant': merchant,
      'date': date?.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}
