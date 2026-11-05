import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:equity_tracker/core/logging/data/api_call_recorder.dart';
import 'package:equity_tracker/core/logging/domain/api_log_category.dart';
import 'package:equity_tracker/core/logging/domain/api_log_record.dart';
import 'package:equity_tracker/core/logging/domain/i_api_logger.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/google_map_search_service.dart';

class _FakeApiLogger implements IApiLogger {
  final List<ApiLogRecord> recorded = [];

  @override
  Future<void> logInteraction(ApiLogRecord record) async {
    recorded.add(record);
  }
}

void main() {
  group('GooglePlaceDto', () {
    test('正確解析 Places API (New) 完整資料並轉換為 StoreSearchResult', () {
      final json = {
        'displayName': {
          'text': '爭鮮PLUS-善化店',
          'languageCode': 'zh-TW',
        },
        'formattedAddress': '741台灣臺南市善化區文昌里中正路363號',
        'rating': 4.3,
        'userRatingCount': 601,
        'types': ['sushi_restaurant', 'japanese_restaurant', 'restaurant'],
      };

      final dto = GooglePlaceDto.fromJson(json);
      expect(dto.displayNameText, '爭鮮PLUS-善化店');
      expect(dto.formattedAddress, '741台灣臺南市善化區文昌里中正路363號');
      expect(dto.rating, 4.3);
      expect(dto.userRatingCount, 601);
      expect(dto.types, ['sushi_restaurant', 'japanese_restaurant', 'restaurant']);

      final domain = dto.toDomain();
      expect(domain.name, '爭鮮PLUS-善化店');
      expect(domain.address, '741台灣臺南市善化區文昌里中正路363號');
      expect(domain.rating, 4.3);
      expect(domain.userRatingsTotal, 601);
      expect(domain.types, ['sushi_restaurant', 'japanese_restaurant', 'restaurant']);
    });

    test('遇到空值與缺失欄位時提供安全的預設值', () {
      final json = <String, dynamic>{};
      final dto = GooglePlaceDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.name, '');
      expect(domain.address, '');
      expect(domain.rating, 0.0);
      expect(domain.userRatingsTotal, 0);
      expect(domain.types, isEmpty);
    });
  });

  group('GoogleMapSearchService', () {
    test('當 apiKey 為空或全為空白字元時，直接返回空陣列且不發出 HTTP 請求', () async {
      bool httpCalled = false;
      final mockClient = MockClient((request) async {
        httpCalled = true;
        return http.Response('{}', 200);
      });

      final service = GoogleMapSearchService(
        apiKey: '   ',
        httpClient: mockClient,
      );

      final results = await service.search('善化 爭鮮');
      expect(results, isEmpty);
      expect(httpCalled, isFalse);
    });

    test('當 query 為空或全為空白字元時，直接返回空陣列且不發出 HTTP 請求', () async {
      bool httpCalled = false;
      final mockClient = MockClient((request) async {
        httpCalled = true;
        return http.Response('{}', 200);
      });

      final service = GoogleMapSearchService(
        apiKey: 'AIzaSyFakeKey123',
        httpClient: mockClient,
      );

      final results = await service.search('   ');
      expect(results, isEmpty);
      expect(httpCalled, isFalse);
    });

    test('成功執行 Places API (New) 請求並正確傳遞 Headers 與 Request Body', () async {
      http.Request? capturedRequest;

      final mockResponse = {
        'places': [
          {
            'displayName': {'text': '爭鮮PLUS-善化店', 'languageCode': 'zh-TW'},
            'formattedAddress': '741台灣臺南市善化區文昌里中正路363號',
            'rating': 4.3,
            'userRatingCount': 601,
            'types': ['restaurant', 'food'],
          }
        ]
      };

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response.bytes(
          utf8.encode(jsonEncode(mockResponse)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GoogleMapSearchService(
        apiKey: 'AIzaSyFakeKey12345678',
        httpClient: mockClient,
      );

      final results = await service.search('善化 爭鮮');

      expect(results.length, 1);
      expect(results.first.name, '爭鮮PLUS-善化店');
      expect(results.first.address, '741台灣臺南市善化區文昌里中正路363號');
      expect(results.first.rating, 4.3);
      expect(results.first.userRatingsTotal, 601);

      // 驗證 HTTP 協定與標頭規範
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.url.toString(), 'https://places.googleapis.com/v1/places:searchText');
      expect(capturedRequest!.headers['content-type'], contains('application/json'));
      expect(capturedRequest!.headers['x-goog-api-key'], 'AIzaSyFakeKey12345678');
      expect(
        capturedRequest!.headers['x-goog-fieldmask'],
        'places.displayName,places.formattedAddress,places.types',
      );

      // 驗證 Request Body 結構
      final requestBody = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(requestBody['textQuery'], '善化 爭鮮');
      expect(requestBody['languageCode'], 'zh-TW');
      expect(requestBody['pageSize'], 5);
    });

    test('當 API 回傳空物件或 places 為空陣列時，安全返回空陣列', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final service = GoogleMapSearchService(
        apiKey: 'AIzaSyFakeKey123',
        httpClient: mockClient,
      );

      final results = await service.search('查無此地');
      expect(results, isEmpty);
    });

    test('當 API 回傳 HTTP 403 或 400 錯誤時，優雅返回空陣列不拋出崩潰例外', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 403,
              'message': 'This API key is not authorized to use this service or API.',
              'status': 'PERMISSION_DENIED',
            }
          }),
          403,
        );
      });

      final service = GoogleMapSearchService(
        apiKey: 'AIzaSyFakeKey123',
        httpClient: mockClient,
      );

      final results = await service.search('善化 爭鮮');
      expect(results, isEmpty);
    });

    test('當網路連線異常拋出例外時，優雅捕獲並返回空陣列', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network connection failed');
      });

      final service = GoogleMapSearchService(
        apiKey: 'AIzaSyFakeKey123',
        httpClient: mockClient,
      );

      final results = await service.search('善化 爭鮮');
      expect(results, isEmpty);
    });

    test('整合 ApiCallRecorder 時，正確記錄請求日誌並將 X-Goog-Api-Key 進行遮罩', () async {
      final fakeLogger = _FakeApiLogger();
      final recorder = ApiCallRecorder(fakeLogger);

      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'places': [
              {
                'displayName': {'text': '星巴克'},
                'formattedAddress': '台北市信義區',
                'rating': 4.6,
                'userRatingCount': 100,
                'types': ['cafe'],
              }
            ]
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = GoogleMapSearchService(
        apiKey: 'AIzaSySecretApiKey12345678',
        callRecorder: recorder,
        httpClient: mockClient,
      );

      final results = await service.search('台北 星巴克');
      expect(results.length, 1);

      // 驗證 Fake Logger 記錄到該呼叫
      expect(fakeLogger.recorded.length, 1);
      final log = fakeLogger.recorded.first;
      expect(log.category, ApiLogCategory.googleMap);
      expect(log.sourceName, 'GoogleMapSearch');
      expect(log.isError, isFalse);
      expect(log.request.method, 'POST');
      expect(log.request.url, 'https://places.googleapis.com/v1/places:searchText');

      // 驗證遮罩保護 (X-Goog-Api-Key 必須被 LogSanitizer 遮罩)
      final serializedJson = log.toJson();
      final loggedHeaders = (serializedJson['request'] as Map<String, dynamic>)['headers'] as Map<String, dynamic>?;
      expect(loggedHeaders, isNotNull);
      final maskedKey = loggedHeaders!['X-Goog-Api-Key'] as String?;
      expect(maskedKey, isNotNull);
      expect(maskedKey, contains('AIza'));
      expect(maskedKey, contains('...'));
      expect(maskedKey, isNot(contains('SecretApiKey')));
    });
  });
}
