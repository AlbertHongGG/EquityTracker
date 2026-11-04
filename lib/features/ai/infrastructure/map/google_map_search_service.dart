import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_record.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:equity_tracker/core/logging/data/api_log_manager.dart';

class GoogleMapSearchService implements IMapSearchService {
  final String apiKey;
  final IApiLogger? logManager;

  GoogleMapSearchService({required this.apiKey, this.logManager});

  @override
  Future<List<StoreSearchResult>> search(String query) async {
    if (apiKey.isEmpty) {
      return [];
    }

    final sw = Stopwatch()..start();
    final startTime = DateTime.now().toIso8601String();
    final urlString =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(query)}&language=zh-TW&key=$apiKey';
    final url = Uri.parse(urlString);

    final request = ApiLogRequest(
      url: urlString,
      method: 'GET',
      queryParameters: {'query': query, 'language': 'zh-TW'},
    );

    try {
      final response = await http.get(url);
      sw.stop();
      final durationMs = sw.elapsedMilliseconds;

      if (response.statusCode == 200) {
        final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
        final status = parsedData['status'] as String? ?? 'UNKNOWN';

        if (status != 'OK' && status != 'ZERO_RESULTS') {
          final errorMessage = parsedData['error_message'] as String? ?? 'Place Search failed with status $status';
          print('[GoogleMapSearchService] API Error: $status $errorMessage');

          logManager?.logInteraction(
            ApiLogRecord(
              timestamp: startTime,
              category: ApiLogCategory.googleMap,
              sourceName: 'GoogleMapSearch',
              durationMs: durationMs,
              isError: true,
              request: request,
              response: ApiLogResponse(
                statusCode: 200,
                body: parsedData,
                error: 'Status: $status ($errorMessage)',
              ),
            ),
          );
          return [];
        }

        if (status == 'ZERO_RESULTS') {
          logManager?.logInteraction(
            ApiLogRecord(
              timestamp: startTime,
              category: ApiLogCategory.googleMap,
              sourceName: 'GoogleMapSearch',
              durationMs: durationMs,
              isError: false,
              request: request,
              response: ApiLogResponse(
                statusCode: 200,
                body: {'status': 'ZERO_RESULTS', 'results': []},
              ),
            ),
          );
          return [];
        }

        final rawResults = (parsedData['results'] as List).take(5);
        final mappedResults = rawResults.map((result) {
          return StoreSearchResult(
            name: result['name'] ?? '',
            address: result['formatted_address'] ?? '',
            types: (result['types'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
            rating: (result['rating'] as num?)?.toDouble() ?? 0.0,
            userRatingsTotal: result['user_ratings_total'] ?? 0,
          );
        }).toList();

        logManager?.logInteraction(
          ApiLogRecord(
            timestamp: startTime,
            category: ApiLogCategory.googleMap,
            sourceName: 'GoogleMapSearch',
            durationMs: durationMs,
            isError: false,
            request: request,
            response: ApiLogResponse(
              statusCode: 200,
              body: {
                'status': 'OK',
                'results': mappedResults.map((r) => r.toMap()).toList(),
              },
            ),
          ),
        );

        return mappedResults;
      } else {
        print('[GoogleMapSearchService] Request failed with status: ${response.statusCode}');
        logManager?.logInteraction(
          ApiLogRecord(
            timestamp: startTime,
            category: ApiLogCategory.googleMap,
            sourceName: 'GoogleMapSearch',
            durationMs: durationMs,
            isError: true,
            request: request,
            response: ApiLogResponse(
              statusCode: response.statusCode,
              body: response.body,
              error: 'HTTP error ${response.statusCode}',
            ),
          ),
        );
        return [];
      }
    } catch (e, st) {
      sw.stop();
      final durationMs = sw.elapsedMilliseconds;
      print('[GoogleMapSearchService] Error: $e');

      logManager?.logInteraction(
        ApiLogRecord(
          timestamp: startTime,
          category: ApiLogCategory.googleMap,
          sourceName: 'GoogleMapSearch',
          durationMs: durationMs,
          isError: true,
          request: request,
          response: ApiLogResponse(
            error: '$e\n$st',
          ),
        ),
      );
      return [];
    }
  }
}

final mapSearchServiceProvider = Provider.autoDispose<IMapSearchService>((ref) {
  final config = ref.watch(aiConfigControllerProvider);
  return GoogleMapSearchService(
    apiKey: config.googleMapApiKey,
    logManager: ref.watch(apiLogManagerProvider.notifier),
  );
});
