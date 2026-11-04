import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/data/api_call_recorder.dart';
import 'package:equity_tracker/core/logging/providers/logging_providers.dart';

/// Google Maps 地圖店家搜尋服務 (GoogleMapSearchService)
///
/// 統一透過 [ApiCallRecorder] 記錄 HTTP 請求、耗時、敏感 Key 遮罩與結構化日誌。
class GoogleMapSearchService implements IMapSearchService {
  final String apiKey;
  final ApiCallRecorder? callRecorder;

  GoogleMapSearchService({required this.apiKey, this.callRecorder});

  @override
  Future<List<StoreSearchResult>> search(String query) async {
    if (apiKey.isEmpty) {
      return [];
    }

    final urlString =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(query)}&language=zh-TW&key=$apiKey';
    final url = Uri.parse(urlString);

    try {
      final response = callRecorder != null
          ? await callRecorder!.recordHttpCall(
              category: ApiLogCategory.googleMap,
              sourceName: 'GoogleMapSearch',
              method: 'GET',
              url: url,
              action: () => http.get(url),
            )
          : await http.get(url);

      if (response.statusCode == 200) {
        final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
        final status = parsedData['status'] as String? ?? 'UNKNOWN';

        if (status != 'OK' && status != 'ZERO_RESULTS') {
          final errorMessage =
              parsedData['error_message'] as String? ?? 'Place Search failed with status $status';
          debugPrint('[GoogleMapSearchService] API Error: $status $errorMessage');
          return [];
        }

        if (status == 'ZERO_RESULTS') {
          return [];
        }

        final rawResults = (parsedData['results'] as List).take(5);
        return rawResults.map((result) {
          return StoreSearchResult(
            name: result['name'] ?? '',
            address: result['formatted_address'] ?? '',
            types: (result['types'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
            rating: (result['rating'] as num?)?.toDouble() ?? 0.0,
            userRatingsTotal: result['user_ratings_total'] ?? 0,
          );
        }).toList();
      } else {
        debugPrint('[GoogleMapSearchService] Request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[GoogleMapSearchService] Error: $e');
      return [];
    }
  }
}

final mapSearchServiceProvider = Provider.autoDispose<IMapSearchService>((ref) {
  final config = ref.watch(aiConfigControllerProvider);
  return GoogleMapSearchService(
    apiKey: config.googleMapApiKey,
    callRecorder: ref.watch(apiCallRecorderProvider),
  );
});
