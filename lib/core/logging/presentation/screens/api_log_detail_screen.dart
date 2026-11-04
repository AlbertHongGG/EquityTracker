import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/widgets/json_tree_viewer.dart';

/// API 與 AI 互動日誌詳情畫面 (ApiLogDetailScreen)
///
/// 1:1 復刻 LensWise_Android ApiLogDetailScreen 規範：
/// - 延遲自磁碟載入完整 JSON Payload
/// - 呈現耗時、時間、分類與狀態徽章
/// - 透過強化版 JsonTreeViewer 展示結構化 Request 與 Response
class ApiLogDetailScreen extends StatelessWidget {
  final ApiLogEntry entry;

  const ApiLogDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          entry.sourceName,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.isError
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: entry.isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    width: 1,
                  ),
                ),
                child: Text(
                  entry.isError ? 'ERROR' : 'SUCCESS',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: entry.isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: entry.resolvePayload(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '讀取日誌失敗: ${snapshot.error}',
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
            );
          }

          final payload = snapshot.data ?? {};
          final request = payload['request'];
          final response = payload['response'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Metadata 卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow(
                        icon: Icons.category_rounded,
                        label: '分類',
                        value: entry.category.displayName,
                        color: primary,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildMetaRow(
                        icon: Icons.timer_rounded,
                        label: '耗時',
                        value: '${entry.durationMs} ms',
                        color: entry.durationMs > 2000 ? Colors.orange : Colors.green,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildMetaRow(
                        icon: Icons.calendar_today_rounded,
                        label: '時間',
                        value: entry.displayTime,
                        color: isDark ? Colors.white70 : Colors.black87,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Request 節點
                if (request != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'REQUEST',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: primary,
                      ),
                    ),
                  ),
                  JsonTreeViewer(data: request, isDark: isDark, rootName: 'request'),
                  const SizedBox(height: 24),
                ],

                // 3. Response 節點
                if (response != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'RESPONSE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: entry.isError ? const Color(0xFFEF4444) : primary,
                      ),
                    ),
                  ),
                  JsonTreeViewer(data: response, isDark: isDark, rootName: 'response'),
                  const SizedBox(height: 24),
                ],

                // Fallback: 如果非標準 request/response 結構，直接展開完整 payload
                if (request == null && response == null) ...[
                  JsonTreeViewer(data: payload, isDark: isDark),
                ],

                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
