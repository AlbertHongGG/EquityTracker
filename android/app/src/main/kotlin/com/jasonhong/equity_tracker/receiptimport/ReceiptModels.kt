package com.jasonhong.equity_tracker.receiptimport

data class ReceiptItemDto(
    val name: String,
    val amount: Int,
    val quantity: Int
)

data class ReceiptPayloadDto(
    val merchant: String,
    val dateIso: String,
    val items: List<ReceiptItemDto>
)

data class ReceiptImportResult(
    val count: Int,
    val merchant: String,
    val totalAmount: Int,
    val insertedIds: List<Long>
)
