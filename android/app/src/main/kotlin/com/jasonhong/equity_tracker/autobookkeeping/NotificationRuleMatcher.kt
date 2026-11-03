package com.jasonhong.equity_tracker.autobookkeeping

class NotificationRuleMatcher {

    private val amountRegexes = listOf(
        // 1. 前綴提示詞 + 金額 (如：消費1463元、消費 NT$1,463、付款完成 250 元、扣款 500 元)
        Regex(
            """(?:消費|刷卡|付款|支付|金額|授權|交易|扣款|NT\$|TWD|\$)\D{0,8}?([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\.[0-9]+)?(?:\s*元)?""",
            RegexOption.IGNORE_CASE
        ),
        // 2. 金額 + 後綴「元」 (如：1463元通知、2,500 元)
        Regex(
            """(?<![0-9])([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\.[0-9]+)?\s*元"""
        )
    )

    private val interferenceCardRegex = Regex("""(?:末四碼|末4碼|卡號末|卡號)\s*\d+""")
    private val interferenceTimeRegex = Regex("""\d{1,2}:\d{2}""")

    fun matchAndParse(event: RawNotificationEvent, rules: List<NotificationRuleDto>): MatchedExpense? {
        val fullText = "${event.title} ${event.body}".trim()
        if (fullText.isEmpty()) return null

        for (rule in rules) {
            if (!rule.isEnabled) continue

            // 1. 機構識別 (PackageName 或 TitleKeywords)
            val packageMatched = rule.packageNames.isNotEmpty() && rule.packageNames.any { pkg ->
                event.packageName.isNotEmpty() && event.packageName.contains(pkg, ignoreCase = true)
            }

            val titleMatched = rule.titleKeywords.isNotEmpty() && rule.titleKeywords.any { kw ->
                event.title.contains(kw, ignoreCase = true)
            }

            // LINE 主程式特別隔離：標題必須明確包含 LINE Pay 或 LINE 錢包
            if (event.packageName == "jp.naver.line.android") {
                val isLinePayTitle = rule.titleKeywords.any { kw ->
                    event.title.contains(kw, ignoreCase = true)
                }
                if (!isLinePayTitle) {
                    continue
                }
            }

            if (!packageMatched && !titleMatched) {
                continue
            }

            // 2. 排除關鍵字過濾 (Negative Keywords)
            val hasNegative = rule.negativeKeywords.any { neg ->
                fullText.contains(neg, ignoreCase = true)
            }
            if (hasNegative) {
                continue
            }

            // 3. 消費關鍵字過濾 (Body Keywords)
            if (rule.bodyKeywords.isNotEmpty()) {
                val hasBodyKw = rule.bodyKeywords.any { kw ->
                    fullText.contains(kw, ignoreCase = true)
                }
                if (!hasBodyKw) {
                    continue
                }
            }

            // 4. 提取金額
            val amount = extractAmount(fullText)
            if (amount == null || amount <= 0) {
                continue
            }

            return MatchedExpense(
                ruleId = rule.id,
                ruleName = rule.name,
                transactionTitle = rule.defaultTransactionTitle,
                amount = amount,
                categoryId = rule.defaultCategoryId,
                timestamp = event.timestamp,
                rawBody = if (event.body.isNotEmpty()) event.body else event.title
            )
        }

        return null
    }

    fun extractAmount(text: String): Int? {
        // 先移除卡號末四碼與時間字元干擾
        val sanitized = text.replace(interferenceCardRegex, "")
            .replace(interferenceTimeRegex, "")

        for (regex in amountRegexes) {
            val match = regex.find(sanitized)
            if (match != null) {
                val amountStr = match.groups[1]?.value?.replace(",", "")
                val valInt = amountStr?.toIntOrNull()
                if (valInt != null && valInt > 0 && valInt < 10_000_000) {
                    return valInt
                }
            }
        }
        return null
    }
}
