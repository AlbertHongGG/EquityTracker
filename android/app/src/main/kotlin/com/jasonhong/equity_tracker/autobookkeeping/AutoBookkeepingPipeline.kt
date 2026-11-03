package com.jasonhong.equity_tracker.autobookkeeping

import android.content.Context
import android.util.Log

/**
 * 信用卡與行動支付通知自動記帳核心管線（單例）
 * 100% 獨立自治於 Android 原生行程，不依賴 Flutter 執行緒存活
 */
class AutoBookkeepingPipeline private constructor(private val appContext: Context) {

    companion object {
        private const val TAG = "AutoBookkeepingPipeline"

        @Volatile
        private var instance: AutoBookkeepingPipeline? = null

        fun getInstance(context: Context): AutoBookkeepingPipeline {
            return instance ?: synchronized(this) {
                instance ?: AutoBookkeepingPipeline(context.applicationContext).also { instance = it }
            }
        }
    }

    private val deduplicationGuard = DeduplicationGuard()
    private val configReader = AutoBookkeepingConfigReader()
    private val ruleMatcher = NotificationRuleMatcher()
    private val dbWriter = TransactionSqliteWriter()
    private val notifier = AutoBookkeepingNotifier()

    // UI 前景回呼監聽器（當 Flutter 處於前景時即時通知 UI 刷新）
    private var transactionListener: ((Long) -> Unit)? = null

    fun setTransactionListener(listener: ((Long) -> Unit)?) {
        synchronized(this) {
            transactionListener = listener
        }
    }

    /**
     * 處理一則原生通知事件
     * @return true 若成功比對並寫入 SQLite，否則 false
     */
    fun processEvent(event: RawNotificationEvent): Boolean {
        // 1. 略過本 App 自身發出的通知（防止循環記帳）
        if (event.packageName == appContext.packageName) {
            return false
        }

        // 2. 原生通知 Key 去重（15 秒內相同 notification key 略過）
        val now = System.currentTimeMillis()
        if (!deduplicationGuard.shouldProcessRaw(event.key, now)) {
            Log.d(TAG, "Ignored duplicate notification raw key: ${event.key}")
            return false
        }

        // 3. 讀取最新設定（支援即時讀取 SharedPreferences）
        val config = configReader.loadConfig(appContext)
        if (!config.isEnabled) {
            Log.d(TAG, "Auto-bookkeeping is disabled in settings. Skipping.")
            return false
        }

        // 4. 規則比對與金額提取
        val expense = ruleMatcher.matchAndParse(event, config.rules)
        if (expense == null) {
            Log.d(TAG, "Notification did not match any auto-bookkeeping rules.")
            return false
        }

        // 5. 業務語意跨 App 去重 (防止同一筆消費由多個 App 如銀行網銀與行動支付同時推播)
        if (!deduplicationGuard.shouldProcessExpense(expense.ruleId, expense.amount, now)) {
            Log.i(TAG, "Ignored duplicate expense within deduplication window: ${expense.ruleName} \$${expense.amount}")
            return false
        }

        // 6. 原生直接寫入 SQLite
        val result = dbWriter.insertExpense(appContext, expense, config.defaultCategoryId)
        if (result == null) {
            Log.e(TAG, "Failed to insert transaction into SQLite: ${expense.transactionTitle}")
            return false
        }

        Log.i(TAG, "Auto-bookkeeping succeeded: id=${result.id}, title=${result.title}, amount=${result.amount}")

        // 7. 原生推播成功通知（供點擊查看或直接檢視）
        if (config.notifyOnSuccess) {
            notifier.sendSuccessNotification(appContext, result)
        }

        // 8. 若 Flutter 正在前景執行，通知 Flutter 刷新狀態
        synchronized(this) {
            transactionListener?.invoke(result.id)
        }

        return true
    }
}
