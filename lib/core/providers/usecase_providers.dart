import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/logging/providers/logging_providers.dart';
import 'package:equity_tracker/features/notion_sync/domain/use_cases/connect_notion_use_case.dart';
import 'package:equity_tracker/features/notion_sync/domain/use_cases/wipe_all_data_use_case.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart'; 
import 'package:equity_tracker/features/notion_sync/services/notion_sync_service.dart';

final connectNotionUseCaseProvider = Provider<ConnectNotionUseCase>((ref) {
  return ConnectNotionUseCase(
    ref.read(syncStateRepositoryProvider),
    ref.read(notionApiClientProvider),
    ref.read(notionSyncServiceProvider),
    ref.read(transactionRepositoryProvider),
  );
});

final wipeAllDataUseCaseProvider = Provider<WipeAllDataUseCase>((ref) {
  return WipeAllDataUseCase(
    ref.read(syncStateRepositoryProvider),
    ref.read(transactionRepositoryProvider),
    ref.read(autoBookkeepingRepositoryProvider),
    ref.read(logFileStorageProvider),
  );
});
