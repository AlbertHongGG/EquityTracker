package com.jasonhong.equity_tracker.receiptimport

import android.content.Context
import android.content.Intent
import android.util.Log

class ReceiptImportPipeline private constructor(private val appContext: Context) {

    companion object {
        private const val TAG = "ReceiptImportPipeline"

        @Volatile
        private var instance: ReceiptImportPipeline? = null

        fun getInstance(context: Context): ReceiptImportPipeline {
            return instance ?: synchronized(this) {
                instance ?: ReceiptImportPipeline(context.applicationContext).also { instance = it }
            }
        }
    }

    private val parser = ReceiptIntentParser()
    private val dbWriter = ReceiptSqliteWriter()
    private val notifier = ReceiptImportNotifier()

    private var transactionListener: ((Long) -> Unit)? = null

    fun setTransactionListener(listener: ((Long) -> Unit)?) {
        synchronized(this) {
            transactionListener = listener
        }
    }

    /**
     * 處理外部收據進件 Intent (ACTION_VIEW 或 ACTION_SEND)
     * 原生直接於背景完成 SQLite 原子批次寫入並發送系統通知
     */
    fun processIntent(intent: Intent): Boolean {
        try {
            // 1. 解析 Intent 與 JSON
            val payload = parser.parse(intent)
            if (payload == null || payload.items.isEmpty()) {
                Log.w(TAG, "Failed to parse receipt payload or items were empty")
                return false
            }

            // 2. 原生 SQLite 事務批次寫入
            val result = dbWriter.insertReceipt(appContext, payload)
            if (result == null || result.insertedIds.isEmpty()) {
                Log.e(TAG, "Failed to batch insert receipt items into SQLite")
                return false
            }

            // 3. 發送 Android 原生系統推播通知 (零 Emoji，精確文案)
            notifier.sendSuccessNotification(appContext, result)

            // 4. 若 Flutter 正在執行中，通知 Flutter 刷新 UI 與推送 Notion
            synchronized(this) {
                if (result.insertedIds.isNotEmpty()) {
                    transactionListener?.invoke(result.insertedIds.first())
                }
            }

            Log.i(TAG, "Receipt import pipeline completed successfully: ${result.count} items, merchant=${result.merchant}")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error in ReceiptImportPipeline", e)
            return false
        }
    }
}
