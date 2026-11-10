import 'package:equity_tracker/features/ai/domain/models/workflow_step_result.dart';
import 'package:equity_tracker/features/ai/infrastructure/agents/store_lookup_agent/store_lookup_agent.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/bookkeeping_state.dart';
import 'package:equity_tracker/features/ai/application/workflows/bookkeeping/workers/i_bookkeeping_worker.dart';

class StoreLookupWorker implements IBookkeepingWorker {
  final StoreLookupAgent storeLookupAgent;
  final IMapSearchService mapSearchService;
  final bool isGoogleMapEnabled;

  StoreLookupWorker(
    this.storeLookupAgent,
    this.mapSearchService, {
    required this.isGoogleMapEnabled,
  });

  @override
  Future<bool> requiresProcessing(BookkeepingRecord record) async {
    final data = record.data;
    if ((data.store == null || data.store!.isEmpty) &&
        (data.locationClue == null || data.locationClue!.isEmpty)) {
      return false;
    }

    final currentQueryStr = [data.locationClue, data.store].join('|');
    final lastQueryStr = record.metadata['StoreLookupWorker_LastQuery'] as String?;
    if (currentQueryStr == lastQueryStr) {
      return false;
    }

    return true;
  }

  @override
  Future<WorkflowStepResult?> process(
    int recordIndex,
    BookkeepingRecord record,
    List<BookkeepingRecord> allRecords,
    String originalText, {
    void Function(String)? onProgress,
  }) async {
    final data = record.data;
    onProgress?.call('處理第 ${recordIndex + 1} 筆商品: ${data.item}');

    final hintDisplay =
        (data.store == null || data.store!.isEmpty) ? '可能的線索' : data.store;
    onProgress?.call('查詢店家名稱: $hintDisplay...');

    final fullQueryParts = [data.locationClue, data.store, data.item]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    final fullQueryStr = fullQueryParts.join(' ').trim();

    final relaxedQueryParts = [data.locationClue, data.store]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    final relaxedQueryStr = relaxedQueryParts.join(' ').trim();

    StoreLookupResult? finalLookupResponse;
    List<StoreSearchResult> searchResults = [];

    if (!isGoogleMapEnabled) {
      onProgress?.call('Google Map 查詢未啟用，交由 AI 直接推斷');
      finalLookupResponse = await storeLookupAgent.execute(
        StoreLookupInput(
          originalText: originalText,
          hint: data.store ?? '',
          location: data.locationClue ?? '',
          item: data.item ?? '',
          searchResults: [],
        ),
      );
    } else if (fullQueryStr.isNotEmpty) {
      searchResults = await mapSearchService.search(fullQueryStr);
      if (searchResults.isEmpty) {
        onProgress?.call('Google Map 查無結果，交由 AI 直接推斷');
      } else {
        onProgress?.call('Google Map 找到 ${searchResults.length} 筆可能店家，交由 AI 篩選');
      }

      finalLookupResponse = await storeLookupAgent.execute(
        StoreLookupInput(
          originalText: originalText,
          hint: data.store ?? '',
          location: data.locationClue ?? '',
          item: data.item ?? '',
          searchResults: searchResults,
        ),
      );

      if (!finalLookupResponse.isCertain &&
          (finalLookupResponse.options == null || finalLookupResponse.options!.isEmpty) &&
          data.item != null &&
          data.item!.isNotEmpty &&
          relaxedQueryStr.isNotEmpty &&
          relaxedQueryStr != fullQueryStr) {
        onProgress?.call('AI 判定地圖結果不符，嘗試移除品項名稱進行擴大搜尋...');
        searchResults = await mapSearchService.search(relaxedQueryStr);
        if (searchResults.isNotEmpty) {
          onProgress?.call('擴大搜尋找到 ${searchResults.length} 筆可能店家，交由 AI 再次篩選');
          finalLookupResponse = await storeLookupAgent.execute(
            StoreLookupInput(
              originalText: originalText,
              hint: data.store ?? '',
              location: data.locationClue ?? '',
              item: data.item ?? '',
              searchResults: searchResults,
            ),
          );
        }
      }
    } else {
      onProgress?.call('無足夠線索查詢地圖，交由 AI 推斷');
      finalLookupResponse = await storeLookupAgent.execute(
        StoreLookupInput(
          originalText: originalText,
          hint: data.store ?? '',
          location: data.locationClue ?? '',
          item: data.item ?? '',
          searchResults: [],
        ),
      );
    }

    record.metadata['StoreLookupWorker_LastQuery'] =
        [data.locationClue, data.store].join('|');

    if (finalLookupResponse.isCertain &&
        finalLookupResponse.storeName != null &&
        finalLookupResponse.storeName!.isNotEmpty) {
      onProgress?.call('確認店家名稱為: ${finalLookupResponse.storeName}');
      record.updateStore(finalLookupResponse.storeName!);
      record.metadata['StoreLookupWorker_LastQuery'] =
          [data.locationClue, finalLookupResponse.storeName].join('|');
      return null;
    } else {
      final options = finalLookupResponse.options ?? [];
      bool isUserCorrected = record.metadata.containsKey('User_Corrected_Store');
      if (options.isEmpty && isUserCorrected && data.store != null && data.store!.isNotEmpty) {
        onProgress?.call('地圖依然無匹配結果，強制採用您的輸入: ${data.store}');
        record.metadata['StoreLookupWorker_LastQuery'] =
            [data.locationClue, data.store].join('|');
        return null;
      }

      String message;
      if (options.isEmpty) {
        message = '請問「${data.item ?? data.store ?? '未知項目'}」是在哪家店消費的？請直接輸入：';
      } else {
        message = '請問「${data.item ?? data.store ?? '未知項目'}」是在哪家店消費的？';
      }

      return WorkflowRequiresInput(
        StoreSelectionSuspendedState(
          recordIndex: recordIndex,
          records: allRecords,
          originalText: originalText,
          options: options,
          message: message,
        ),
      );
    }
  }
}
