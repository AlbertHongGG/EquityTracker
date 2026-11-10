import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/logging/domain/api_log_entry.dart';
import 'package:equity_tracker/core/logging/presentation/widgets/log_inspector_header.dart';
import 'package:equity_tracker/core/widgets/json_tree_viewer.dart';

/// API 與 AI 互動日誌詳情畫面 (ApiLogDetailScreen)
///
/// 現代 DevTools Inspector 規範 (1:1 復刻 LensWise_Android)：
/// - 無 AppBar 與返回箭頭，完全由原生右滑手勢返回
/// - 頂部 LogInspectorHeader 純排版看板隨 ScrollView 滾動（隨動非置頂）
/// - 支援一鍵複製完整日誌 Payload 至剪貼簿
/// - 透過 JsonTreeViewer 展示結構化 Request 與 Response
class ApiLogDetailScreen extends StatelessWidget {
  final ApiLogEntry entry;

  const ApiLogDetailScreen({super.key, required this.entry});

  Future<void> _copyLog(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final rawText = const JsonEncoder.withIndent('  ').convert(payload);
    await Clipboard.setData(ClipboardData(text: rawText));
  }

  int? _extractStatusCode(dynamic response) {
    if (response is Map) {
      final code =
          response['status_code'] ??
          response['statusCode'] ??
          response['status'];
      if (code is int) return code;
      if (code is String) return int.tryParse(code);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, dynamic>>(
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
            final statusCode = _extractStatusCode(response);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 頂部隨動看板 (1:1 復刻 LensWise_Android)
                  LogInspectorHeader(
                    entry: entry,
                    statusCode: statusCode,
                    onCopyLog: () => _copyLog(context, payload),
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
                    JsonTreeViewer(
                      data: request,
                      isDark: isDark,
                      rootName: 'request',
                    ),
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
                          color: entry.isError
                              ? const Color(0xFFEF4444)
                              : primary,
                        ),
                      ),
                    ),
                    JsonTreeViewer(
                      data: response,
                      isDark: isDark,
                      rootName: 'response',
                    ),
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
      ),
    );
  }
}
