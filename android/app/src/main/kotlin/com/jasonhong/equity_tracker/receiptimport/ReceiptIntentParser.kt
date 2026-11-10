package com.jasonhong.equity_tracker.receiptimport

import android.content.Intent
import android.net.Uri
import android.util.Log
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class ReceiptIntentParser {

    companion object {
        private const val TAG = "ReceiptIntentParser"
        private const val DEFAULT_MERCHANT = "收據消費"
        private const val DEFAULT_ITEM_NAME = "未知名稱"
    }

    private val isoDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
        timeZone = TimeZone.getDefault()
    }

    fun parse(intent: Intent?): ReceiptPayloadDto? {
        if (intent == null) return null

        val rawJson = extractRawJson(intent) ?: return null
        return parseJson(rawJson)
    }

    fun extractRawJson(intent: Intent): String? {
        // 1. 處理 ACTION_VIEW (Deep Link: equitytracker://receipt/import?data=...)
        if (Intent.ACTION_VIEW == intent.action) {
            val uri = intent.data ?: return null
            val dataParam = uri.getQueryParameter("data")
            if (!dataParam.isNullOrEmpty()) {
                return dataParam
            }
            // 若整串 URI 為 JSON 封裝或直接附帶在路徑後方
            val uriString = uri.toString()
            val queryIdx = uriString.indexOf("data=")
            if (queryIdx != -1) {
                val encoded = uriString.substring(queryIdx + 5)
                return try {
                    Uri.decode(encoded)
                } catch (_: Exception) {
                    encoded
                }
            }
        }

        // 2. 處理 ACTION_SEND (系統分享選單純文字或 JSON)
        if (Intent.ACTION_SEND == intent.action) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!text.isNullOrEmpty()) {
                return text.trim()
            }
        }

        return null
    }

    fun parseJson(rawJson: String): ReceiptPayloadDto? {
        try {
            var content = rawJson.trim()
            // 若為 URL Scheme 帶入且包含 data=
            if (content.startsWith("equitytracker://") || content.startsWith("http://") || content.startsWith("https://")) {
                val uri = Uri.parse(content)
                val param = uri.getQueryParameter("data")
                if (!param.isNullOrEmpty()) {
                    content = param.trim()
                }
            }

            val json = JSONObject(content)

            // 店家名稱
            val rawMerchant = when {
                json.has("merchant") -> json.optString("merchant")
                json.has("store") -> json.optString("store")
                json.has("shop") -> json.optString("shop")
                else -> ""
            }
            val merchant = if (rawMerchant.trim().isNotEmpty()) rawMerchant.trim() else DEFAULT_MERCHANT

            // 日期時間
            val rawDate = when {
                json.has("date") -> json.optString("date")
                json.has("time") -> json.optString("time")
                else -> ""
            }
            val dateIso = if (rawDate.trim().isNotEmpty()) {
                rawDate.trim()
            } else {
                isoDateFormat.format(Date())
            }

            // 細項清單
            val items = mutableListOf<ReceiptItemDto>()
            val itemsArray = json.optJSONArray("items") 
                ?: json.optJSONArray("details") 
                ?: json.optJSONArray("list")

            if (itemsArray != null) {
                for (i in 0 until itemsArray.length()) {
                    val itemObj = itemsArray.optJSONObject(i) ?: continue
                    val rawName = when {
                        itemObj.has("name") -> itemObj.optString("name")
                        itemObj.has("title") -> itemObj.optString("title")
                        itemObj.has("item") -> itemObj.optString("item")
                        else -> ""
                    }
                    val name = if (rawName.trim().isNotEmpty()) rawName.trim() else DEFAULT_ITEM_NAME

                    val rawAmount = when {
                        itemObj.has("amount") -> itemObj.optDouble("amount", 0.0)
                        itemObj.has("price") -> itemObj.optDouble("price", 0.0)
                        itemObj.has("subtotal") -> itemObj.optDouble("subtotal", 0.0)
                        else -> 0.0
                    }
                    val amount = Math.round(rawAmount).toInt()

                    val rawQty = when {
                        itemObj.has("quantity") -> itemObj.optInt("quantity", 1)
                        itemObj.has("qty") -> itemObj.optInt("qty", 1)
                        itemObj.has("count") -> itemObj.optInt("count", 1)
                        else -> 1
                    }
                    val quantity = if (rawQty > 0) rawQty else 1

                    items.add(ReceiptItemDto(name = name, amount = amount, quantity = quantity))
                }
            }

            // 若無 items 細項但有整筆 totalAmount，自動生成一筆明細兜底
            if (items.isEmpty()) {
                val totalAmount = when {
                    json.has("totalAmount") -> json.optDouble("totalAmount", 0.0)
                    json.has("amount") -> json.optDouble("amount", 0.0)
                    else -> 0.0
                }
                if (totalAmount > 0) {
                    items.add(ReceiptItemDto(name = DEFAULT_ITEM_NAME, amount = Math.round(totalAmount).toInt(), quantity = 1))
                }
            }

            return ReceiptPayloadDto(
                merchant = merchant,
                dateIso = dateIso,
                items = items
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse receipt JSON", e)
            return null
        }
    }
}
