import 'package:flutter/material.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';

/// API 與 AI 日誌詳情頂部看板 (LogInspectorHeader)
///
/// 1:1 復刻 LensWise_Android 頂部規格：
/// - 第一行：項目名稱 (Title, 20sp, bold) + 狀態碼徽章 (200 / 500 等) + 右側完整日誌複製按鈕
/// - 第二行：耗時 (Duration ms, 12sp) + 格式化時間戳記 (Timestamp, 12sp)
/// - 無外圍邊框與卡片背景，純排版呈現，隨外層 ScrollView 自然向上滾動移出視野
class LogInspectorHeader extends StatelessWidget {
  final ApiLogEntry entry;
  final VoidCallback? onCopyLog;
  final int? statusCode;

  const LogInspectorHeader({
    super.key,
    required this.entry,
    this.onCopyLog,
    this.statusCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isSuccess = !entry.isError;
    final code = statusCode ?? (isSuccess ? 200 : 500);

    // 狀態碼徽章配色 (參照 LensWise ApiLogStatusBadge)
    final badgeBg = isSuccess
        ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.14)
        : const Color(0xFFEF4444).withValues(alpha: isDark ? 0.22 : 0.14);
    final badgeFg = isSuccess
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : const Color(0xFFEF4444);

    final metaIconColor = isDark
        ? Colors.white.withValues(alpha: 0.54)
        : Colors.black.withValues(alpha: 0.54);
    final metaTextColor = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : Colors.black.withValues(alpha: 0.87);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：項目名稱 + 狀態碼徽章
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.sourceName,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$code',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 第二行：耗時 + 格式化時間戳
                Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 15,
                      color: metaIconColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.durationMs} ms',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: metaTextColor,
                      ),
                    ),
                    if (entry.displayTime.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: metaIconColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.displayTime,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: metaTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 右側複製完整日誌按鈕
          IconButton(
            onPressed: onCopyLog,
            tooltip: '複製完整日誌',
            splashRadius: 20,
            icon: Icon(
              Icons.copy_rounded,
              size: 20,
              color: isDark ? Colors.white70 : theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
