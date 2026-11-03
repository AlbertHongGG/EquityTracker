package com.jasonhong.equity_tracker.autobookkeeping

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class TransactionSqliteWriter {

    companion object {
        private const val TAG = "TransactionSqliteWriter"
        private const val DB_NAME = "equity_tracker.db"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_NOTION_ENABLED = "flutter.notion_enabled"
    }

    private val isoDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
        timeZone = TimeZone.getDefault()
    }

    fun insertExpense(
        context: Context,
        expense: MatchedExpense,
        defaultCategoryId: String?
    ): InsertedTransactionResult? {
        val dbFile = context.getDatabasePath(DB_NAME)
        if (!dbFile.exists()) {
            Log.w(TAG, "Database file does not exist yet: ${dbFile.absolutePath}")
            return null
        }

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)

            // 1. 決定分類 ID 與名稱
            val (resolvedCatId, resolvedCatName) = resolveCategory(db, expense.categoryId, defaultCategoryId)

            // 2. 檢查 Notion Sync 狀態
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isNotionEnabled = prefs.getBoolean(KEY_NOTION_ENABLED, false)
            val syncStatus = if (isNotionEnabled) "pendingCreate" else "synced"

            // 3. 準備寫入欄位
            val now = Date()
            val expenseDate = if (expense.timestamp > 0) Date(expense.timestamp) else now
            val dateStr = isoDateFormat.format(expenseDate)
            val createdAtStr = isoDateFormat.format(now)

            val values = ContentValues().apply {
                put("title", expense.transactionTitle)
                put("type", "expense")
                put("amount", expense.amount)
                put("categoryId", resolvedCatId)
                put("date", dateStr)
                put("createdAt", createdAtStr)
                put("note", expense.rawBody)
                put("syncStatus", syncStatus)
            }

            val insertedId = db.insert("transactions", null, values)
            if (insertedId == -1L) {
                Log.e(TAG, "Failed to insert transaction into SQLite")
                return null
            }

            Log.i(TAG, "Successfully inserted auto-bookkeeping transaction: id=$insertedId, title=${expense.transactionTitle}, amount=${expense.amount}")

            return InsertedTransactionResult(
                id = insertedId,
                title = expense.transactionTitle,
                amount = expense.amount,
                categoryId = resolvedCatId,
                categoryName = resolvedCatName,
                dateIso = dateStr
            )
        } catch (e: Exception) {
            Log.e(TAG, "SQLite error inserting transaction", e)
            return null
        } finally {
            try {
                db?.close()
            } catch (_: Exception) {}
        }
    }

    private fun resolveCategory(
        db: SQLiteDatabase,
        targetCatId: String?,
        fallbackCatId: String?
    ): Pair<String, String> {
        val candidateId = targetCatId ?: fallbackCatId

        // 1. 嘗試查詢候選 ID
        if (!candidateId.isNullOrEmpty()) {
            db.rawQuery("SELECT id, name FROM categories WHERE id = ? LIMIT 1", arrayOf(candidateId)).use { cursor ->
                if (cursor.moveToFirst()) {
                    val id = cursor.getString(0)
                    val name = cursor.getString(1) ?: "未分類"
                    return Pair(id, name)
                }
            }
        }

        // 2. 優先尋找名稱為「信用卡」的支出類別 (使用者預設核心需求)
        db.rawQuery("SELECT id, name FROM categories WHERE name = '信用卡' AND type = 'expense' LIMIT 1", null).use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: "信用卡"
                return Pair(id, name)
            }
        }

        // 3. 次選尋找名稱為「其他」的支出類別
        db.rawQuery("SELECT id, name FROM categories WHERE name = '其他' AND type = 'expense' LIMIT 1", null).use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: "其他"
                return Pair(id, name)
            }
        }

        // 4. 尋找任意支出類別
        db.rawQuery("SELECT id, name FROM categories WHERE type = 'expense' LIMIT 1", null).use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1) ?: "支出"
                return Pair(id, name)
            }
        }

        // 5. 若 categories 表為空，兜底回傳信用卡分類
        return Pair("default_credit_card", "信用卡")
    }
}
