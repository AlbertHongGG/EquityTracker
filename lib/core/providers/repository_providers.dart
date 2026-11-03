import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/settings/data/settings_repository.dart';
import 'package:equity_tracker/features/notion_sync/data/notion_api_client.dart';
import 'package:equity_tracker/features/notion_sync/domain/sync_state_repository.dart';
import 'package:equity_tracker/features/notion_sync/data/sync_state_repository_impl.dart';
import 'package:equity_tracker/features/auto_bookkeeping/data/auto_bookkeeping_repository.dart';

final notionApiClientProvider = Provider<NotionApiClient>((ref) {
  return NotionApiClient();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final syncStateRepositoryProvider = Provider<ISyncStateRepository>((ref) {
  return SyncStateRepositoryImpl();
});

final autoBookkeepingRepositoryProvider = Provider<AutoBookkeepingRepository>((ref) {
  return AutoBookkeepingRepository();
});
