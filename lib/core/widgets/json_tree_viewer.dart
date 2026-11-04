import 'dart:convert';
import 'package:flutter/material.dart';

/// 結構化 JSON 階層檢視器 (JsonTreeViewer)
///
/// 1:1 復刻 LensWise_Android JsonTreeViewer 規範：
/// - 自動過濾 null、空字串、空 Map 與空 List (isValidDisplayNode 守門)
/// - 支援 SelectionArea 反白複製
/// - 長文字或 JSON 巢狀字串自動漂亮縮排展示 (Code Block)
/// - 語意型別色彩編碼 (Boolean: 紫色, Number: 綠色, String: 靛藍/薄荷綠, Key: 橘黃)
class JsonTreeViewer extends StatelessWidget {
  final dynamic data;
  final bool isDark;
  final String? rootName;

  const JsonTreeViewer({
    super.key,
    required this.data,
    required this.isDark,
    this.rootName,
  });

  static bool isValidDisplayNode(dynamic node) {
    if (node == null) return false;
    if (node is String && node.trim().isEmpty) return false;
    if (node is Map && node.isEmpty) return false;
    if (node is List && node.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (rootName != null) {
      return _JsonNodeRenderer(
        keyName: rootName!,
        data: data,
        isDark: isDark,
        isRoot: true,
      );
    }

    if (data is! Map && data is! List) {
      return _JsonNodeRenderer(
        keyName: 'data',
        data: data,
        isDark: isDark,
        isRoot: true,
      );
    }

    if (data is Map) {
      final entries = (data as Map)
          .entries
          .where((e) => isValidDisplayNode(e.value))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: entries.map((e) => _JsonNodeRenderer(
          keyName: e.key.toString(),
          data: e.value,
          isDark: isDark,
          isRoot: true,
        )).toList(),
      );
    }

    if (data is List) {
      final list = (data as List).asMap().entries.where((e) => isValidDisplayNode(e.value)).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: list.map((e) => _JsonNodeRenderer(
          keyName: '[${e.key}]',
          data: e.value,
          isDark: isDark,
          isRoot: true,
        )).toList(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _JsonNodeRenderer extends StatefulWidget {
  final String keyName;
  final dynamic data;
  final bool isDark;
  final bool isRoot;

  const _JsonNodeRenderer({
    required this.keyName,
    required this.data,
    required this.isDark,
    this.isRoot = false,
  });

  @override
  State<_JsonNodeRenderer> createState() => _JsonNodeRendererState();
}

class _JsonNodeRendererState extends State<_JsonNodeRenderer> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isRoot;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data is Map || widget.data is List) {
      final isMap = widget.data is Map;
      final int count = isMap ? (widget.data as Map).length : (widget.data as List).length;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      _expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      size: 18,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.keyName,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: widget.isDark ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMap ? '{$count}' : '[$count]',
                      style: TextStyle(
                        color: widget.isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: isMap
                      ? (widget.data as Map)
                          .entries
                          .where((e) => JsonTreeViewer.isValidDisplayNode(e.value))
                          .map((e) => _JsonNodeRenderer(
                                keyName: e.key.toString(),
                                data: e.value,
                                isDark: widget.isDark,
                              ))
                          .toList()
                      : (widget.data as List)
                          .asMap()
                          .entries
                          .where((e) => JsonTreeViewer.isValidDisplayNode(e.value))
                          .map((e) => _JsonNodeRenderer(
                                keyName: '[${e.key}]',
                                data: e.value,
                                isDark: widget.isDark,
                              ))
                          .toList(),
                ),
              ),
          ],
        ),
      );
    } else {
      // 原始類型展示 (Primitive node)
      bool isLongString = false;
      if (widget.data is String) {
        final str = widget.data as String;
        if (str.contains('\n') || str.length > 50) isLongString = true;
      }

      if (isLongString) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.keyName}:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: widget.isDark ? Colors.orange[300] : Colors.orange[800],
                ),
              ),
              const SizedBox(height: 4),
              _buildPrimitive(widget.data),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.keyName}: ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: widget.isDark ? Colors.orange[300] : Colors.orange[800],
                ),
              ),
              Expanded(child: _buildPrimitive(widget.data)),
            ],
          ),
        );
      }
    }
  }

  Widget _buildPrimitive(dynamic data) {
    if (data == null) {
      return Text(
        'null',
        style: TextStyle(fontFamily: 'monospace', color: widget.isDark ? Colors.grey[500] : Colors.grey[600]),
      );
    }
    if (data is bool) {
      return Text(
        data.toString(),
        style: TextStyle(fontFamily: 'monospace', color: widget.isDark ? Colors.purple[300] : Colors.purple[700]),
      );
    }
    if (data is num) {
      return Text(
        data.toString(),
        style: TextStyle(fontFamily: 'monospace', color: widget.isDark ? Colors.green[300] : Colors.green[800]),
      );
    }
    if (data is String) {
      final str = data;
      if (str.contains('\n') || str.length > 50) {
        String displayStr = str;
        try {
          int startObj = str.indexOf('{');
          int endObj = str.lastIndexOf('}');
          int startArr = str.indexOf('[');
          int endArr = str.lastIndexOf(']');

          int startIdx = -1;
          int endIdx = -1;

          if (startObj >= 0 && endObj > startObj && (startArr == -1 || startObj < startArr)) {
            startIdx = startObj;
            endIdx = endObj;
          } else if (startArr >= 0 && endArr > startArr) {
            startIdx = startArr;
            endIdx = endArr;
          }

          if (startIdx >= 0 && endIdx > startIdx) {
            final jsonSub = str.substring(startIdx, endIdx + 1);
            final parsed = jsonDecode(jsonSub);
            final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
            displayStr = str.substring(0, startIdx) + pretty + str.substring(endIdx + 1);
          }
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isDark ? Colors.white24 : Colors.black12,
            ),
          ),
          child: Text(
            displayStr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
              color: widget.isDark ? Colors.greenAccent[100] : Colors.indigo,
            ),
          ),
        );
      } else {
        return Text(
          '"$str"',
          style: TextStyle(
            fontFamily: 'monospace',
            color: widget.isDark ? Colors.greenAccent[100] : Colors.indigo,
          ),
        );
      }
    }
    return Text(data.toString(), style: const TextStyle(fontFamily: 'monospace'));
  }
}
