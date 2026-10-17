import 'package:flutter_test/flutter_test.dart';
import 'package:trifecta/services/cache/cache_service.dart';
import 'package:trifecta/services/settings/settings_service_impl.dart';
import 'package:trifecta/services/storage/storage_service_impl.dart';
import 'package:trifecta/services/sync/sync_service_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SyncServiceMock initializes cleanly without throwing MissingPluginException', () async {
    final storageService = StorageServiceImpl();
    final cacheService = CacheServiceImpl();
    final settingsService = SettingsServiceImpl(storageService: storageService);

    // This must not throw MissingPluginException even if channel is missing
    final syncService = SyncServiceMock(
      cacheService: cacheService,
      settingsService: settingsService,
    );

    // Allow asynchronous init tasks to run
    await Future.delayed(const Duration(milliseconds: 100));

    expect(syncService.isOnline, isTrue);

    // Toggling simulation must also not throw
    syncService.toggleNetworkSimulation();
    expect(syncService.isOnline, isFalse);

    syncService.toggleNetworkSimulation();
    expect(syncService.isOnline, isTrue);

    syncService.dispose();
  });
}
