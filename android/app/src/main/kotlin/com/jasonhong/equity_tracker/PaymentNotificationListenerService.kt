package com.jasonhong.equity_tracker

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.jasonhong.equity_tracker.autobookkeeping.AutoBookkeepingPipeline
import com.jasonhong.equity_tracker.autobookkeeping.RawNotificationEvent

class PaymentNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifService"

        @Volatile
        var isConnected: Boolean = false
            private set
    }

    private lateinit var pipeline: AutoBookkeepingPipeline

    override fun onCreate() {
        super.onCreate()
        pipeline = AutoBookkeepingPipeline.getInstance(applicationContext)
        Log.i(TAG, "PaymentNotificationListenerService created")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isConnected = true
        Log.i(TAG, "Notification listener connected! Checking recent active notifications...")
        try {
            val activeNotifs = activeNotifications ?: return
            val now = System.currentTimeMillis()
            // 掃描最近 5 分鐘內可能遺漏的推播
            for (sbn in activeNotifs) {
                if (now - sbn.postTime < 5 * 60 * 1000L) {
                    handleStatusBarNotification(sbn)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking active notifications on connect", e)
        }
    }

    override fun onListenerDisconnected() {
        isConnected = false
        super.onListenerDisconnected()
        Log.w(TAG, "Notification listener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        handleStatusBarNotification(sbn)
    }

    private fun handleStatusBarNotification(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        if (packageName == applicationContext.packageName) {
            return
        }

        val extras = sbn.notification?.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        var text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim() ?: ""

        if (bigText.isNotEmpty() && bigText.length > text.length) {
            text = bigText
        }

        if (title.isEmpty() && text.isEmpty()) {
            return
        }

        val key = sbn.key ?: "$packageName|${sbn.id}"
        val event = RawNotificationEvent(
            key = key,
            packageName = packageName,
            title = title,
            body = text,
            timestamp = sbn.postTime
        )

        pipeline.processEvent(event)
    }
}
