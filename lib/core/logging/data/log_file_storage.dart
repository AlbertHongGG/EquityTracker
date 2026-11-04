import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

/// 統一底層日誌檔案存取與容量留存引擎 (LogFileStorage)
class LogFileStorage {
  static const String subDirApi = 'api';
  static const String subDirNotifications = 'notifications';

  /// 取得指定日誌子目錄 (.runtime/log/$subDir)
  Future<Directory> getLogDirectory(String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/.runtime/log/$subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 產生日誌檔名: yyyyMMdd_HHmmss_[category]_[source]_[random6].json
  String generateFileName({
    String? category,
    String? source,
    String prefix = 'Log',
  }) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final random = Random().nextInt(999999).toString().padLeft(6, '0');

    final catStr = category != null && category.isNotEmpty ? '_$category' : '';
    final srcStr = source != null && source.isNotEmpty ? '_$source' : '';

    return '${y}${m}${d}_${h}${min}${s}${catStr}${srcStr}_$random.json';
  }

  /// 寫入日誌檔案並自動執行留存限制
  Future<File?> writeLog(
    String subDir,
    String fileName,
    Map<String, dynamic> data, {
    int maxFiles = 100,
  }) async {
    try {
      final dir = await getLogDirectory(subDir);
      final file = File('${dir.path}/$fileName');
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString, mode: FileMode.write, flush: true);

      // 自動觸發容量留存限制，非同步執行避免阻塞
      enforceRetentionPolicy(subDir, maxFiles: maxFiles);
      return file;
    } catch (e) {
      // 寫入失敗印出除錯訊息，但不讓 Log 崩潰主線程
      print('[LogFileStorage] Failed to write log $fileName to $subDir: $e');
      return null;
    }
  }

  /// 列出目錄下所有日誌檔案 (依檔名降冪排序，即最新的在前)
  Future<List<File>> listLogFiles(String subDir) async {
    try {
      final dir = await getLogDirectory(subDir);
      if (!await dir.exists()) return [];

      final entities = await dir.list().toList();
      final files = entities.whereType<File>().toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (e) {
      print('[LogFileStorage] Failed to list log files in $subDir: $e');
      return [];
    }
  }

  /// 讀取檔案前 [maxBytes] 位元組作為標頭預覽，避免將數 MB 的 JSON 全數載入記憶體
  Future<String> readHeaderPreview(File file, {int maxBytes = 2048}) async {
    try {
      if (!await file.exists()) return '';
      final length = await file.length();
      if (length <= maxBytes) {
        return await file.readAsString();
      }

      final stream = file.openRead(0, maxBytes);
      final bytes = await stream.expand((chunk) => chunk).toList();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  /// 刪除單一檔案
  Future<bool> deleteLog(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('[LogFileStorage] Failed to delete log file ${file.path}: $e');
      return false;
    }
  }

  /// 清空特定子目錄的所有日誌
  Future<void> clearLogs(String subDir) async {
    try {
      final dir = await getLogDirectory(subDir);
      if (await dir.exists()) {
        final files = await dir.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('[LogFileStorage] Failed to clear logs in $subDir: $e');
    }
  }

  /// 清空整個 .runtime/log 根目錄
  Future<void> clearAllLogs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final rootDir = Directory('${appDir.path}/.runtime/log');
      if (await rootDir.exists()) {
        await rootDir.delete(recursive: true);
      }
    } catch (e) {
      print('[LogFileStorage] Failed to clear all runtime logs: $e');
    }
  }

  /// 執行留存策略 (Retention Policy)
  Future<void> enforceRetentionPolicy(String subDir, {int maxFiles = 100}) async {
    try {
      final dir = await getLogDirectory(subDir);
      if (!await dir.exists()) return;

      final entities = await dir.list().toList();
      final files = entities.whereType<File>().toList();
      if (files.length <= maxFiles) return;

      // 降冪排序，保留前 maxFiles 筆，其餘刪除
      files.sort((a, b) => b.path.compareTo(a.path));
      final filesToDelete = files.sublist(maxFiles);
      for (final file in filesToDelete) {
        await file.delete();
      }
    } catch (e) {
      print('[LogFileStorage] Failed to enforce retention policy in $subDir: $e');
    }
  }
}
