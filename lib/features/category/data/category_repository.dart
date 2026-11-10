import 'package:sqflite/sqflite.dart';
import 'package:equity_tracker/core/database/database_helper.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'sortOrder ASC',
    );
    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addCategoryModel(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategoryModel(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> updateCategoryOrder(List<CategoryModel> categories) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var category in categories) {
      batch.update(
        'categories',
        {'sortOrder': category.order},
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteCategoryModel(String id) async {
    final db = await _dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllCategories() async {
    final db = await _dbHelper.database;
    await db.delete('categories');
  }
}
