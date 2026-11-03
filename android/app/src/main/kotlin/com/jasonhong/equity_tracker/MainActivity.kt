package com.jasonhong.equity_tracker

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.jasonhong.equity_tracker.autobookkeeping.AutoBookkeepingNotifier
import com.jasonhong.equity_tracker.autobookkeeping.AutoBookkeepingPipeline
import com.jasonhong.equity_tracker.autobookkeeping.RawNotificationEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jasonhong.equitytracker/notification_listener"
    private var methodChannel: MethodChannel? = null
    private var pendingEditTxId: Long? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val txId = intent.getLongExtra(AutoBookkeepingNotifier.EXTRA_EDIT_TX_ID, -1L)
        if (txId != -1L) {
            pendingEditTxId = txId
            methodChannel?.invokeMethod("onEditTransactionRequested", mapOf("id" to txId))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    val isGranted = isNotificationServiceEnabled()
                    result.success(isGranted)
                }
                "openPermissionSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }
                "getInitialEditTxId" -> {
                    val txId = pendingEditTxId
                    pendingEditTxId = null
                    result.success(txId)
                }
                "simulateNotification" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args != null) {
                        val pkg = args["packageName"] as? String ?: "com.test.simulator"
                        val title = args["title"] as? String ?: ""
                        val body = args["body"] as? String ?: ""
                        val timestamp = (args["timestamp"] as? Number)?.toLong() ?: System.currentTimeMillis()

                        val event = RawNotificationEvent(
                            key = "sim_${System.currentTimeMillis()}",
                            packageName = pkg,
                            title = title,
                            body = body,
                            timestamp = timestamp
                        )

                        // 統一透過單例管線處理
                        val processed = AutoBookkeepingPipeline.getInstance(applicationContext).processEvent(event)
                        result.success(processed)
                    } else {
                        result.error("INVALID_ARGS", "Missing notification arguments", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 註冊交易寫入成功回呼，向 Flutter 推播通知
        AutoBookkeepingPipeline.getInstance(applicationContext).setTransactionListener { txId ->
            runOnUiThread {
                methodChannel?.invokeMethod("onTransactionAdded", mapOf("id" to txId))
            }
        }

        // 如果冷啟動時帶有待編輯交易 ID，立即通知
        pendingEditTxId?.let { txId ->
            methodChannel?.invokeMethod("onEditTransactionRequested", mapOf("id" to txId))
        }
    }

    override fun onDestroy() {
        AutoBookkeepingPipeline.getInstance(applicationContext).setTransactionListener(null)
        super.onDestroy()
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!flat.isNullOrEmpty()) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn.packageName == pkgName) {
                    return true
                }
            }
        }
        return NotificationManagerCompat.getEnabledListenerPackages(this).contains(pkgName)
    }
}
