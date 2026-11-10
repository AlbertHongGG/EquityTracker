package com.jasonhong.equity_tracker.receiptimport

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

class ReceiptSqliteWriter {

    companion object {
        private const val TAG = "ReceiptSqliteWriter"
        private const val DB_NAME = "equity_tracker.db"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_NOTION_ENABLED = "flutter.notion_enabled"
    }

    private val isoDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
        timeZone = TimeZone.getDefault()
    }

    fun insertReceipt(context: Context, payload: ReceiptPayloadDto): ReceiptImportResult? {
        val dbFile = context.getDatabasePath(DB_NAME)
        if (!dbFile.exists()) {
            Log.w(TAG, "Database file does not exist yet: ${dbFile.absolutePath}")
            return null
        }

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)

            // 1. 取得或初始化「發票」分類 ID
            val (resolvedCatId, _) = resolveInvoiceCategory(db)

            // 2. 檢查 Notion Sync 狀態
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isNotionEnabled = prefs.getBoolean(KEY_NOTION_ENABLED, false)
            val syncStatus = if (isNotionEnabled) "pendingCreate" else "synced"

            val createdAtStr = isoDateFormat.format(Date())
            val insertedIds = mutableListOf<Long>()
            var totalAmount = 0

            // 3. 單一事務原子批次寫入 (All or Nothing)
            db.beginTransaction()
            try {
                for (item in payload.items) {
                    val noteStr = "${item.name} x${item.quantity}"
                    val values = ContentValues().apply {
                        put("title", payload.merchant)
                        put("type", "expense")
                        put("amount", item.amount)
                        put("categoryId", resolvedCatId)
                        put("date", payload.dateIso)
                        put("createdAt", createdAtStr)
                        put("note", noteStr)
                        put("syncStatus", syncStatus)
                    }

                    val insertedId = db.insert("transactions", null, values)
                    if (insertedId == -1L) {
                        throw IllegalStateException("Failed to insert receipt item: ${item.name}")
                    }
                    insertedIds.add(insertedId)
                    totalAmount += item.amount
                }
                db.setTransactionSuccessful()
            } finally {
                db.endTransaction()
            }

            Log.i(TAG, "Successfully batch-inserted ${insertedIds.size} receipt items for ${payload.merchant}, total: \$$totalAmount")

            return ReceiptImportResult(
                count = insertedIds.size,
                merchant = payload.merchant,
                totalAmount = totalAmount,
                insertedIds = insertedIds
            )
        } catch (e: Exception) {
            Log.e(TAG, "SQLite error batch-inserting receipt items", e)
            return null
        } finally {
            try {
                db?.close()
            } catch (_: Exception) {}
        }
    }

    private fun resolveInvoiceCategory(db: SQLiteDatabase): Pair<String, String> {
        // 1. 優先尋找名稱為「發票」的支出類別
        db.rawQuery("SELECT id, name FROM categories WHERE name = '發票' AND type = 'expense' LIMIT 1", null).use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: "發票"
                return Pair(id, name)
            }
        }

        // 2. 若資料庫尚未建立「發票」類別，原地插入一筆系統預設發票類別
        val newId = UUID.randomUUID().toString()
        val catValues = ContentValues().apply {
            put("id", newId)
            put("name", "發票")
            put("iconCodePoint", 0xe506) // Icons.receipt_long
            put("iconFontFamily", "MaterialIcons")
            put("iconFontPackage", null as String?)
            put("colorValue", -10453621) // Colors.blueGrey
            put("type", "expense")
            put("isSystem", 1)
            put("isEnabled", 1)
            put("sortOrder", 0)
        }
        val res = db.insert("categories", null, catValues)
        if (res != -1L) {
            return Pair(newId, "發票")
        }

        // 3. 次選尋找任意支出類別
        db.rawQuery("SELECT id, name FROM categories WHERE type = 'expense' LIMIT 1", null).use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: "支出"
                return Pair(id, name)
            }
        }

        return Pair("default_invoice", "發票")
    }
}
