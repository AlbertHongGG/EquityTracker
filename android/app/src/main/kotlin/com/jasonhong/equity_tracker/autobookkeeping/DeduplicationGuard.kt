package com.jasonhong.equity_tracker.autobookkeeping

import java.util.concurrent.ConcurrentHashMap

class DeduplicationGuard(
    private val rawKeyWindowMs: Long = 10_000L,
    private val semanticWindowMs: Long = 15_000L
) {
    // 記錄 sbn.key 的時間戳
    private val keyTimestamps = ConcurrentHashMap<String, Long>()

    // 記錄業務語意簽章 (如 "rule_esun|160") 的時間戳
    private val semanticTimestamps = ConcurrentHashMap<String, Long>()

    fun shouldProcessRaw(key: String, currentTime: Long = System.currentTimeMillis()): Boolean {
        if (key.isEmpty()) return true
        val lastTime = keyTimestamps[key]
        if (lastTime != null && (currentTime - lastTime) < rawKeyWindowMs) {
            return false
        }
        keyTimestamps[key] = currentTime
        cleanupOldEntries(currentTime)
        return true
    }

    fun shouldProcessExpense(ruleId: String, amount: Int, currentTime: Long = System.currentTimeMillis()): Boolean {
        val signature = "$ruleId|$amount"
        val lastTime = semanticTimestamps[signature]
        if (lastTime != null && (currentTime - lastTime) < semanticWindowMs) {
            return false
        }
        semanticTimestamps[signature] = currentTime
        cleanupOldEntries(currentTime)
        return true
    }

    private fun cleanupOldEntries(currentTime: Long) {
        if (keyTimestamps.size > 80) {
            val cutoff = currentTime - 60_000L
            keyTimestamps.entries.removeIf { it.value < cutoff }
        }
        if (semanticTimestamps.size > 80) {
            val cutoff = currentTime - 60_000L
            semanticTimestamps.entries.removeIf { it.value < cutoff }
        }
    }
}
