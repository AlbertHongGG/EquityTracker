import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/providers/logging_providers.dart';

/// Google Places API (New) 單筆地點資料傳輸物件 (DTO)
///
/// 負責解析 Google Places API (New) 結構並安全轉換為領域實體 [StoreSearchResult]。
class GooglePlaceDto {
  final String? displayNameText;
  final String? formattedAddress;
  final double? rating;
  final int? userRatingCount;
  final List<String> types;

  const GooglePlaceDto({
    this.displayNameText,
    this.formattedAddress,
    this.rating,
    this.userRatingCount,
    this.types = const [],
  });

  factory GooglePlaceDto.fromJson(Map<String, dynamic> json) {
    final displayNameMap = json['displayName'] as Map<String, dynamic>?;
    final displayName = displayNameMap?['text'] as String?;
    final address = json['formattedAddress'] as String?;
    final ratingNum = json['rating'] as num?;
    final countNum = json['userRatingCount'] as num?;
    final rawTypes = json['types'] as List<dynamic>?;

    return GooglePlaceDto(
      displayNameText: displayName,
      formattedAddress: address,
      rating: ratingNum?.toDouble(),
      userRatingCount: countNum?.toInt(),
      types: rawTypes?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  StoreSearchResult toDomain() {
    return StoreSearchResult(
      name: displayNameText ?? '',
      address: formattedAddress ?? '',
      rating: rating ?? 0.0,
      userRatingsTotal: userRatingCount ?? 0,
      types: types,
    );
  }
}

/// Google Maps 地圖店家搜尋服務 (GoogleMapSearchService)
///
/// 完全基於 Google Places API (New) 規格實作：
/// 1. 端點：POST https://places.googleapis.com/v1/places:searchText
/// 2. 標頭安全傳遞 X-Goog-Api-Key 與 X-Goog-FieldMask
/// 3. 透過 [ApiCallRecorder] 記錄計時、金鑰自動遮罩與結構化審計日誌
/// 4. 支援建構子注入 [http.Client] 以利單元測試隔離
class GoogleMapSearchService implements IMapSearchService {
  final String apiKey;
  final ApiCallRecorder? callRecorder;
  final http.Client? _httpClient;

  static const String _endpoint =
      'https://places.googleapis.com/v1/places:searchText';
  static const String _fieldMask =
      'places.displayName,places.formattedAddress,places.types';

  GoogleMapSearchService({
    required this.apiKey,
    this.callRecorder,
    http.Client? httpClient,
  }) : _httpClient = httpClient;

  Future<http.Response> _executePost(
    Uri url,
    Map<String, String> headers,
    String encodedBody,
  ) {
    final client = _httpClient;
    if (client != null) {
      return client.post(url, headers: headers, body: encodedBody);
    }
    return http.post(url, headers: headers, body: encodedBody);
  }

  @override
  Future<List<StoreSearchResult>> search(String query) async {
    final trimmedQuery = query.trim();
    if (apiKey.trim().isEmpty || trimmedQuery.isEmpty) {
      return [];
    }

    final url = Uri.parse(_endpoint);
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey.trim(),
      'X-Goog-FieldMask': _fieldMask,
    };
    final requestBody = {
      'textQuery': trimmedQuery,
      'languageCode': 'zh-TW',
      'pageSize': 5,
    };
    final encodedBody = jsonEncode(requestBody);

    final recorder = callRecorder;
    try {
      final response = recorder != null
          ? await recorder.recordHttpCall(
              category: ApiLogCategory.googleMap,
              sourceName: 'GoogleMapSearch',
              method: 'POST',
              url: url,
              headers: headers,
              body: requestBody,
              action: () => _executePost(url, headers, encodedBody),
            )
          : await _executePost(url, headers, encodedBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
        final rawPlaces = parsedData['places'] as List<dynamic>?;
        if (rawPlaces == null || rawPlaces.isEmpty) {
          return [];
        }

        return rawPlaces
            .whereType<Map<String, dynamic>>()
            .map((item) => GooglePlaceDto.fromJson(item).toDomain())
            .toList();
      } else {
        debugPrint(
          '[GoogleMapSearchService] Places API (New) request failed with HTTP ${response.statusCode}: ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('[GoogleMapSearchService] Error: $e');
      return [];
    }
  }
}

final mapSearchServiceProvider = Provider<IMapSearchService>((ref) {
  final config = ref.watch(aiConfigControllerProvider);
  return GoogleMapSearchService(
    apiKey: config.googleMapApiKey,
    callRecorder: ref.watch(apiCallRecorderProvider),
  );
});
