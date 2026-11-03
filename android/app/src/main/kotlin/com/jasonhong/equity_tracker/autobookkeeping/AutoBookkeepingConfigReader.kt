package com.jasonhong.equity_tracker.autobookkeeping

import android.content.Context
import android.util.Log
import org.json.JSONArray

class AutoBookkeepingConfigReader {

    companion object {
        private const val TAG = "AutoBookkeepingConfig"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        private const val KEY_ENABLED = "flutter.auto_bookkeeping_enabled"
        private const val KEY_NOTIFY = "flutter.auto_bookkeeping_notify_on_success"
        private const val KEY_DEFAULT_CAT = "flutter.auto_bookkeeping_default_category"
        private const val KEY_RULES_JSON = "flutter.auto_bookkeeping_rules_json"

        private val DEFAULT_COMMON_EXPENSE_KWS = listOf(
            "消費", "刷卡", "授權", "交易", "付款", "支付", "扣款", "NT$", "TWD", "元"
        )

        private val DEFAULT_COMMON_NEGATIVE_KWS = listOf(
            "驗證碼", "OTP", "動態密碼", "登入", "帳單", "繳費", "應繳", "最低應繳",
            "自動扣繳", "失敗", "未成功", "取消", "退款", "退貨", "優惠", "活動", "抽獎"
        )
    }

    fun loadConfig(context: Context): AutoBookkeepingConfig {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // 預設為 true（開箱即用）
        val isEnabled = if (prefs.contains(KEY_ENABLED)) prefs.getBoolean(KEY_ENABLED, true) else true
        val notifyOnSuccess = if (prefs.contains(KEY_NOTIFY)) prefs.getBoolean(KEY_NOTIFY, true) else true
        val defaultCategoryId = prefs.getString(KEY_DEFAULT_CAT, null)
        val rulesJson = prefs.getString(KEY_RULES_JSON, null)

        val rules = if (!rulesJson.isNullOrEmpty()) {
            parseRulesFromJson(rulesJson)
        } else {
            getBuiltInDefaultRules()
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
            Log.e(TAG, "Failed to parse rules JSON, falling back to built-in rules", e)
            return getBuiltInDefaultRules()
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

    fun getBuiltInDefaultRules(): List<NotificationRuleDto> {
        return listOf(
            // 1. 玉山銀行 (包含真實實機 Package: com.esunbank 與 com.esunbank.ESUNWALLET)
            NotificationRuleDto(
                id = "preset_esun",
                name = "玉山銀行",
                packageNames = listOf("com.esunbank", "com.esunbank.ESUNWALLET", "com.esunbank.ewallet", "com.esunbank.android"),
                titleKeywords = listOf("玉山", "ESUN", "玉山Wallet"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "玉山銀行刷卡",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 2. 國泰世華
            NotificationRuleDto(
                id = "preset_cathay",
                name = "國泰世華",
                packageNames = listOf("com.cathaybk.mymobibank.android", "com.cathaybk.koko.android"),
                titleKeywords = listOf("國泰世華", "CUBE", "KOKO"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "國泰世華刷卡",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 3. 中國信託
            NotificationRuleDto(
                id = "preset_ctbc",
                name = "中國信託",
                packageNames = listOf("com.chinatrust.mobilebank"),
                titleKeywords = listOf("中國信託", "中信", "CTBC"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "中國信託刷卡",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 4. 台新銀行
            NotificationRuleDto(
                id = "preset_taishin",
                name = "台新銀行",
                packageNames = listOf("tw.com.taishinbank.mobile", "tw.com.taishinbank.richart"),
                titleKeywords = listOf("台新", "Richart", "Taishin"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "台新銀行刷卡",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 5. 台北富邦
            NotificationRuleDto(
                id = "preset_fubon",
                name = "台北富邦",
                packageNames = listOf("com.fubon.mbank"),
                titleKeywords = listOf("台北富邦", "富邦", "Fubon"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "富邦銀行刷卡",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 6. 永豐銀行
            NotificationRuleDto(
                id = "preset_sinopac",
                name = "永豐銀行",
                packageNames = listOf("com.sinopac.mwallet", "com.sinopac.dawho"),
                titleKeywords = listOf("永豐", "DAWHO", "大戶"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "永豐銀行刷卡",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 7. 聯邦銀行
            NotificationRuleDto(
                id = "preset_ubot",
                name = "聯邦銀行",
                packageNames = listOf("com.ubot.mbank"),
                titleKeywords = listOf("聯邦", "UBOT"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "聯邦銀行刷卡",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 8. LINE Pay
            NotificationRuleDto(
                id = "preset_linepay",
                name = "LINE Pay",
                packageNames = listOf("jp.naver.line.android", "com.linepayplus.mobileapp"),
                titleKeywords = listOf("LINE Pay", "LINE 錢包", "LINE 錢包通知"),
                bodyKeywords = listOf("付款", "消費", "支付", "扣款", "扣款成功", "付款完成", "NT$", "元"),
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "LINE Pay 消費",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 9. 街口支付
            NotificationRuleDto(
                id = "preset_jkopay",
                name = "街口支付",
                packageNames = listOf("com.jkos.app"),
                titleKeywords = listOf("街口支付", "街口", "JKOPAY"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "街口支付消費",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 10. 全支付
            NotificationRuleDto(
                id = "preset_pxpayplus",
                name = "全支付",
                packageNames = listOf("com.pxpayplus.wallet", "com.pxmart.pxmartapp"),
                titleKeywords = listOf("全支付", "PXPay Plus"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "全支付消費",
                defaultCategoryId = null,
                isEnabled = true
            ),
            // 11. 台灣 Pay
            NotificationRuleDto(
                id = "preset_taiwanpay",
                name = "台灣 Pay",
                packageNames = listOf("tw.com.twmp.mwallet"),
                titleKeywords = listOf("台灣Pay", "台灣 Pay", "Taiwan Pay"),
                bodyKeywords = DEFAULT_COMMON_EXPENSE_KWS,
                negativeKeywords = DEFAULT_COMMON_NEGATIVE_KWS,
                defaultTransactionTitle = "台灣 Pay 消費",
                defaultCategoryId = null,
                isEnabled = true
            )
        )
    }
}
