import 'package:flutter/material.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';

/// API 與 AI 日誌頂部遙測面板 (LogInspectorHeader)
///
/// 方案 1 緊湊兩行終端流 (Compact 2-Row Flow)：
/// - Row 1: 分類與操作標籤 (左) ─── 狀態徽章 SUCCESS / ERROR (右)
/// - Row 2: 耗時 (ms) · 精確時間戳記 (單一資訊流，Monospace 等寬排版)
/// - 與 JsonTreeViewer 保持 100% 視覺統一，消滅笨重白底卡片與粗暴 Divider
class LogInspectorHeader extends StatelessWidget {
  final ApiLogEntry entry;
  final String? method;

  const LogInspectorHeader({
    super.key,
    required this.entry,
    this.method,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    // 狀態顏色判定
    final statusColor = entry.isError
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final statusText = entry.isError ? 'ERROR' : 'SUCCESS';

    // 耗時色階判定 (AI 任務閾值：<2s 綠, 2-5s 橙, >5s 紅)
    Color durationColor;
    if (entry.isError) {
      durationColor = const Color(0xFFEF4444);
    } else if (entry.durationMs > 5000) {
      durationColor = const Color(0xFFEF4444);
    } else if (entry.durationMs > 2000) {
      durationColor = const Color(0xFFF59E0B);
    } else {
      durationColor = const Color(0xFF10B981);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: 左側分類與 HTTP Method 標籤，右側狀態徽章 (與 AppBar 解耦)
          Row(
            children: [
              Icon(
                entry.category.icon,
                size: 16,
                color: primary,
              ),
              const SizedBox(width: 8),
              Text(
                entry.category.displayName,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (method != null && method!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    method!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 極細分隔線 (與 JsonTreeViewer 內部線條一致)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 9),
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),

          // Row 2: 耗時與時間整合為單一終端資訊流 (無小螢幕擠壓破版問題)
          Row(
            children: [
              // 耗時標籤 (帶色階與微底色)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: durationColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: durationColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: durationColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.durationMs} ms',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: durationColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 中間分隔點
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '·',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 時間戳記 (等寬字型，對齊 DevTools 規格)
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        entry.displayTime,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
