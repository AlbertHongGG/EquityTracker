package com.jasonhong.equity_tracker.autobookkeeping

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.jasonhong.equity_tracker.MainActivity
import com.jasonhong.equity_tracker.R

class AutoBookkeepingNotifier {

    companion object {
        const val CHANNEL_ID = "auto_bookkeeping_channel"
        const val EXTRA_EDIT_TX_ID = "auto_bookkeeping_edit_tx_id"
    }

    fun sendSuccessNotification(context: Context, tx: InsertedTransactionResult) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // 確保 Channel 已建立
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "刷卡自動記帳通知",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "系統根據信用卡或行動支付推播自動新增帳務時會發送此通知"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // 點擊通知時啟動 MainActivity 並傳遞交易 ID
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_EDIT_TX_ID, tx.id)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            tx.id.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = "自動記帳：${tx.title}"
        val body = "[${tx.categoryName}] 支出 $${tx.amount}"

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(tx.id.toInt(), notification)
    }
}
