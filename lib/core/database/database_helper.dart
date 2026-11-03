import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'equity_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN syncStatus TEXT DEFAULT "synced"');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categories
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT,
        iconCodePoint INTEGER,
        iconFontFamily TEXT,
        iconFontPackage TEXT,
        colorValue INTEGER,
        type TEXT,
        isSystem INTEGER,
        isEnabled INTEGER,
        sortOrder INTEGER DEFAULT 0
      )
    ''');

    // 2. Transactions
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notionId TEXT,
        title TEXT,
        type TEXT,
        amount INTEGER,
        categoryId TEXT,
        date TEXT,
        createdAt TEXT,
        note TEXT,
        syncStatus TEXT DEFAULT "synced",
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');

    // 3. Recurring Transactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount INTEGER,
        type TEXT,
        categoryId TEXT,
        frequency TEXT,
        nextDueDate TEXT,
        lastGeneratedDate TEXT,
        isEnabled INTEGER,
        note TEXT,
        createdAt TEXT,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');
    
    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    const uuid = Uuid();

    final List<Map<String, dynamic>> systemCategories = [
      {'id': uuid.v4(), 'name': '伙食', 'iconCodePoint': FontAwesomeIcons.utensils.codePoint, 'iconFontFamily': FontAwesomeIcons.utensils.fontFamily, 'iconFontPackage': FontAwesomeIcons.utensils.fontPackage, 'colorValue': Colors.orange.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '交通', 'iconCodePoint': FontAwesomeIcons.trainSubway.codePoint, 'iconFontFamily': FontAwesomeIcons.trainSubway.fontFamily, 'iconFontPackage': FontAwesomeIcons.trainSubway.fontPackage, 'colorValue': Colors.green.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '生活', 'iconCodePoint': FontAwesomeIcons.basketShopping.codePoint, 'iconFontFamily': FontAwesomeIcons.basketShopping.fontFamily, 'iconFontPackage': FontAwesomeIcons.basketShopping.fontPackage, 'colorValue': Colors.blue.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '加油', 'iconCodePoint': FontAwesomeIcons.gasPump.codePoint, 'iconFontFamily': FontAwesomeIcons.gasPump.fontFamily, 'iconFontPackage': FontAwesomeIcons.gasPump.fontPackage, 'colorValue': Colors.indigo.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '醫療', 'iconCodePoint': FontAwesomeIcons.briefcaseMedical.codePoint, 'iconFontFamily': FontAwesomeIcons.briefcaseMedical.fontFamily, 'iconFontPackage': FontAwesomeIcons.briefcaseMedical.fontPackage, 'colorValue': Colors.redAccent.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '購物', 'iconCodePoint': FontAwesomeIcons.bagShopping.codePoint, 'iconFontFamily': FontAwesomeIcons.bagShopping.fontFamily, 'iconFontPackage': FontAwesomeIcons.bagShopping.fontPackage, 'colorValue': Colors.deepPurpleAccent.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '娛樂', 'iconCodePoint': Icons.sports_esports.codePoint, 'iconFontFamily': 'MaterialIcons', 'iconFontPackage': null, 'colorValue': Colors.pinkAccent.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '社交', 'iconCodePoint': Icons.groups.codePoint, 'iconFontFamily': 'MaterialIcons', 'iconFontPackage': null, 'colorValue': Colors.lightBlueAccent.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '禮物', 'iconCodePoint': FontAwesomeIcons.gift.codePoint, 'iconFontFamily': FontAwesomeIcons.gift.fontFamily, 'iconFontPackage': FontAwesomeIcons.gift.fontPackage, 'colorValue': Colors.red.shade300.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '信用卡', 'iconCodePoint': FontAwesomeIcons.creditCard.codePoint, 'iconFontFamily': FontAwesomeIcons.creditCard.fontFamily, 'iconFontPackage': FontAwesomeIcons.creditCard.fontPackage, 'colorValue': Colors.orange.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '其他', 'iconCodePoint': FontAwesomeIcons.circleQuestion.codePoint, 'iconFontFamily': FontAwesomeIcons.circleQuestion.fontFamily, 'iconFontPackage': FontAwesomeIcons.circleQuestion.fontPackage, 'colorValue': Colors.grey.value, 'type': TransactionType.expense.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '薪水', 'iconCodePoint': FontAwesomeIcons.moneyBillWave.codePoint, 'iconFontFamily': FontAwesomeIcons.moneyBillWave.fontFamily, 'iconFontPackage': FontAwesomeIcons.moneyBillWave.fontPackage, 'colorValue': Colors.teal.value, 'type': TransactionType.income.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '投資', 'iconCodePoint': FontAwesomeIcons.chartLine.codePoint, 'iconFontFamily': FontAwesomeIcons.chartLine.fontFamily, 'iconFontPackage': FontAwesomeIcons.chartLine.fontPackage, 'colorValue': Colors.greenAccent.shade700.value, 'type': TransactionType.income.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '交易', 'iconCodePoint': FontAwesomeIcons.moneyBillTransfer.codePoint, 'iconFontFamily': FontAwesomeIcons.moneyBillTransfer.fontFamily, 'iconFontPackage': FontAwesomeIcons.moneyBillTransfer.fontPackage, 'colorValue': Colors.cyan.shade600.value, 'type': TransactionType.income.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '獎金', 'iconCodePoint': FontAwesomeIcons.sackDollar.codePoint, 'iconFontFamily': FontAwesomeIcons.sackDollar.fontFamily, 'iconFontPackage': FontAwesomeIcons.sackDollar.fontPackage, 'colorValue': Colors.amber.shade700.value, 'type': TransactionType.income.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '回饋', 'iconCodePoint': FontAwesomeIcons.percent.codePoint, 'iconFontFamily': FontAwesomeIcons.percent.fontFamily, 'iconFontPackage': FontAwesomeIcons.percent.fontPackage, 'colorValue': Colors.orangeAccent.shade400.value, 'type': TransactionType.income.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '提款', 'iconCodePoint': FontAwesomeIcons.moneyBill1.codePoint, 'iconFontFamily': FontAwesomeIcons.moneyBill1.fontFamily, 'iconFontPackage': FontAwesomeIcons.moneyBill1.fontPackage, 'colorValue': Colors.indigo.shade400.value, 'type': TransactionType.income.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
      {'id': uuid.v4(), 'name': '其他', 'iconCodePoint': FontAwesomeIcons.circleQuestion.codePoint, 'iconFontFamily': FontAwesomeIcons.circleQuestion.fontFamily, 'iconFontPackage': FontAwesomeIcons.circleQuestion.fontPackage, 'colorValue': Colors.grey.value, 'type': TransactionType.income.name, 'isSystem': 1, 'isEnabled': 1, 'sortOrder': 0},
    ];

    for (var catMap in systemCategories) {
      await db.insert('categories', catMap);
    }
  }
}
