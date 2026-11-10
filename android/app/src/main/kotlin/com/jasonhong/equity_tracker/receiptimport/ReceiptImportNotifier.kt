package com.jasonhong.equity_tracker.receiptimport

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.jasonhong.equity_tracker.MainActivity
import com.jasonhong.equity_tracker.R
import com.jasonhong.equity_tracker.autobookkeeping.AutoBookkeepingNotifier

class ReceiptImportNotifier {

    companion object {
        const val CHANNEL_ID = "receipt_import_channel"
        private const val NOTIFICATION_ID_BASE = 88000
    }

    fun sendSuccessNotification(context: Context, result: ReceiptImportResult) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // 確保 Channel 已建立
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "收據自動記帳通知",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "外部收據分享匯入自動記帳完成時會發送此通知"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // 點擊通知時啟動 MainActivity
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (result.insertedIds.isNotEmpty()) {
                putExtra(AutoBookkeepingNotifier.EXTRA_EDIT_TX_ID, result.insertedIds.first())
            }
        }

        val notificationId = (NOTIFICATION_ID_BASE + (System.currentTimeMillis() % 10000)).toInt()

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = "自動記帳：${result.merchant}"
        val body = "已成功匯入 ${result.count} 筆收據帳務"

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(notificationId, notification)
    }
}
