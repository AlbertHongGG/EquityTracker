package com.jasonhong.equity_tracker.receiptimport

import android.app.Activity
import android.os.Build
import android.os.Bundle

/**
 * 外部收據進件透明無介面跳板 Activity
 * 收到 Intent 後於原生背景管線直接完成 SQLite 記帳與系統通知，隨即呼叫 finish()
 * 保證零畫面跳轉、不打斷使用者在外部收據 App 的當前操作
 */
class ReceiptImportActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        disableTransitions()

        val receivedIntent = intent
        if (receivedIntent != null) {
            ReceiptImportPipeline.getInstance(applicationContext).processIntent(receivedIntent)
        }

        finish()
        disableTransitions()
    }

    private fun disableTransitions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            overrideActivityTransition(OVERRIDE_TRANSITION_OPEN, 0, 0)
            overrideActivityTransition(OVERRIDE_TRANSITION_CLOSE, 0, 0)
        } else {
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
    }
}
