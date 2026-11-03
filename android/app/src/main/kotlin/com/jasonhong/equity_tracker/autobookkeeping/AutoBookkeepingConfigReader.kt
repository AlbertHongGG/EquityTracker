package com.jasonhong.equity_tracker.autobookkeeping

import android.content.Context
import android.util.Log
import org.json.JSONArray

/**
 * 讀取 SharedPreferences 內的自動記帳配置與機構規則
 * 規則唯一真相來源 (SSOT) 為 Dart 側持久化的 rules JSON
 */
class AutoBookkeepingConfigReader {

    companion object {
        private const val TAG = "AutoBookkeepingConfig"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        private const val KEY_ENABLED = "flutter.auto_bookkeeping_enabled"
        private const val KEY_NOTIFY = "flutter.auto_bookkeeping_notify_on_success"
        private const val KEY_DEFAULT_CAT = "flutter.auto_bookkeeping_default_category"
        private const val KEY_RULES_JSON = "flutter.auto_bookkeeping_rules_json"
    }

    fun loadConfig(context: Context): AutoBookkeepingConfig {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val isEnabled = if (prefs.contains(KEY_ENABLED)) prefs.getBoolean(KEY_ENABLED, true) else true
        val notifyOnSuccess = if (prefs.contains(KEY_NOTIFY)) prefs.getBoolean(KEY_NOTIFY, true) else true
        val defaultCategoryId = prefs.getString(KEY_DEFAULT_CAT, null)
        val rulesJson = prefs.getString(KEY_RULES_JSON, null)

        val rules = if (!rulesJson.isNullOrEmpty()) {
            parseRulesFromJson(rulesJson)
        } else {
            emptyList()
        }

        return AutoBookkeepingConfig(
            isEnabled = isEnabled,
            notifyOnSuccess = notifyOnSuccess,
            defaultCategoryId = defaultCategoryId,
            rules = rules
        )
    }

    private fun parseRulesFromJson(jsonStr: String): List<NotificationRuleDto> {
        val list = mutableListOf<NotificationRuleDto>()
        try {
            val array = JSONArray(jsonStr)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val isEnabled = when (val raw = obj.opt("isEnabled")) {
                    is Boolean -> raw
                    is Number -> raw.toInt() == 1
                    is String -> raw.equals("true", ignoreCase = true) || raw == "1"
                    else -> true
                }
                list.add(
                    NotificationRuleDto(
                        id = obj.optString("id"),
                        name = obj.optString("name"),
                        packageNames = jsonArrayToStringList(obj.optJSONArray("packageNames")),
                        titleKeywords = jsonArrayToStringList(obj.optJSONArray("titleKeywords")),
                        bodyKeywords = jsonArrayToStringList(obj.optJSONArray("bodyKeywords")),
                        negativeKeywords = jsonArrayToStringList(obj.optJSONArray("negativeKeywords")),
                        defaultTransactionTitle = obj.optString("defaultTransactionTitle"),
                        defaultCategoryId = if (obj.has("defaultCategoryId") && !obj.isNull("defaultCategoryId")) obj.optString("defaultCategoryId") else null,
                        isEnabled = isEnabled
                    )
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse rules JSON", e)
            return emptyList()
        }
        return list
    }

    private fun jsonArrayToStringList(array: JSONArray?): List<String> {
        if (array == null) return emptyList()
        val result = mutableListOf<String>()
        for (i in 0 until array.length()) {
            result.add(array.optString(i))
        }
        return result
    }
}
