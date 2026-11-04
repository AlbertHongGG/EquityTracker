import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/log_inspector_header.dart';
import 'package:equity_tracker/core/widgets/json_tree_viewer.dart';

/// API 與 AI 互動日誌詳情畫面 (ApiLogDetailScreen)
///
/// 現代 DevTools Inspector 規範：
/// - 延遲自磁碟載入完整 JSON Payload
/// - 頂部 LogInspectorHeader (緊湊兩行終端流：分類、狀態徽章、耗時與時間戳記)
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
          final method = request is Map ? request['method']?.toString() : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 頂部終端風格遙測面板 (方案 1: 緊湊兩行流)
                LogInspectorHeader(
                  entry: entry,
                  method: method,
                ),

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
}
