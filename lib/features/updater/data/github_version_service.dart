import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/updater/data/github_updater_config.dart';
import 'package:equity_tracker/features/updater/domain/release_info.dart';
import 'package:equity_tracker/core/providers/package_info_provider.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/providers/logging_providers.dart';

class GithubVersionService {
  final GithubUpdaterConfig config;
  final PackageInfo packageInfo;
  final ApiCallRecorder? callRecorder;

  GithubVersionService({
    required this.config,
    required this.packageInfo,
    this.callRecorder,
  });

  /// Checks GitHub for the latest release and compares it with the current app version.
  /// Returns a tuple of (hasUpdate, releaseInfo, errorMessage).
  Future<(bool, ReleaseInfo?, String?)> checkForUpdate() async {
    try {
      final url = 'https://api.github.com/repos/${config.githubOwner}/${config.githubRepo}/releases/latest';

      final uri = Uri.parse(url);
      final headers = {'Accept': 'application/vnd.github.v3+json'};

      final response = callRecorder != null
          ? await callRecorder!.recordHttpCall(
              category: ApiLogCategory.githubUpdater,
              sourceName: 'checkForUpdate',
              method: 'GET',
              url: uri,
              headers: headers,
              action: () => http.get(uri, headers: headers).timeout(const Duration(seconds: 5)),
            )
          : await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        String? apkUrl;
        final assets = json['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name'] as String?;
            if (name != null && name.toLowerCase().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }

        final releaseInfo = ReleaseInfo(
          version: json['tag_name'] as String? ?? 'unknown',
          downloadUrl: apkUrl,
          releaseNotes: json['body'] as String?,
          publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
        );

        final hasUpdate = _isNewerVersion(releaseInfo.version, packageInfo.version);

        return (hasUpdate, releaseInfo, null);
      } else if (response.statusCode == 404) {
        return (false, null, '找不到任何發布版本 (Repository or Release not found)');
      } else {
        return (false, null, '無法檢查更新 (錯誤碼: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      return (false, null, '無法連線到網路，請檢查網路連線');
    }
  }

  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latest = latestVersion.replaceFirst(RegExp(r'^v'), '');
      final current = currentVersion.replaceFirst(RegExp(r'^v'), '');

      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (var i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false; // They are equal or older
    } catch (e) {
      debugPrint('Version comparison error: $e');
      return false;
    }
  }
}

final githubVersionServiceProvider = Provider<GithubVersionService>((ref) {
  return GithubVersionService(
    config: ref.watch(githubUpdaterConfigProvider),
    packageInfo: ref.watch(packageInfoProvider),
    callRecorder: ref.watch(apiCallRecorderProvider),
  );
});
