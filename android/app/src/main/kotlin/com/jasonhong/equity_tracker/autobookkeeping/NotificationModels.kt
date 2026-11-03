package com.jasonhong.equity_tracker.autobookkeeping

data class RawNotificationEvent(
    val key: String,
    val packageName: String,
    val title: String,
    val body: String,
    val timestamp: Long
)

data class NotificationRuleDto(
    val id: String,
    val name: String,
    val packageNames: List<String>,
    val titleKeywords: List<String>,
    val bodyKeywords: List<String>,
    val negativeKeywords: List<String>,
    val defaultTransactionTitle: String,
    val defaultCategoryId: String?,
    val isEnabled: Boolean
)

data class AutoBookkeepingConfig(
    val isEnabled: Boolean,
    val notifyOnSuccess: Boolean,
    val defaultCategoryId: String?,
    val rules: List<NotificationRuleDto>
)

data class MatchedExpense(
    val ruleId: String,
    val ruleName: String,
    val transactionTitle: String,
    val amount: Int,
    val categoryId: String?,
    val timestamp: Long,
    val rawBody: String
)

data class InsertedTransactionResult(
    val id: Long,
    val title: String,
    val amount: Int,
    val categoryId: String,
    val categoryName: String,
    val dateIso: String
)
