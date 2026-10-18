import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../services/api/api_service.dart';
import '../../services/api/api_service_impl.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_service_impl.dart';
import '../../services/cache/cache_service.dart';
import '../../services/club/club_service.dart';
import '../../services/club/club_service_mock.dart';
import '../../services/fixtures/fixtures_service.dart';
import '../../services/fixtures/fixtures_service_mock.dart';
import '../../services/match/match_service.dart';
import '../../services/match/match_service_mock.dart';
import '../../services/roster/roster_service.dart';
import '../../services/roster/roster_service_mock.dart';
import '../../services/settings/settings_service.dart';
import '../../services/settings/settings_service_impl.dart';
import '../../services/standings/standings_service.dart';
import '../../services/standings/standings_service_mock.dart';
import '../../services/storage/storage_service.dart';
import '../../services/storage/storage_service_impl.dart';
import '../../services/store/store_service.dart';
import '../../services/store/store_service_mock.dart';
import '../../services/deeplink/deeplink_service.dart';
import '../../services/streaming/streaming_service.dart';
import '../../services/sync/sync_service.dart';
import '../../services/sync/sync_service_mock.dart';

/// Registers all global service singletons permanently.
/// Controllers only ever depend on these interfaces via Get.find().
class InitialBinding extends Bindings {
  InitialBinding(this.config, {this.preloadedAuth, this.initialDeepLinkUri});

  final AppConfig config;
  final AuthService? preloadedAuth;
  final String? initialDeepLinkUri;

  @override
  void dependencies() {
    Get.put<AppConfig>(config, permanent: true);

    final deepLink = DeepLinkServiceImpl(initialUri: initialDeepLinkUri);
    Get.put<DeepLinkService>(deepLink, permanent: true);

    final storage = StorageServiceImpl();
    Get.put<StorageService>(storage, permanent: true);

    final cache = CacheServiceImpl();
    Get.put<CacheService>(cache, permanent: true);

    final settings = SettingsServiceImpl(storageService: storage);
    Get.put<SettingsService>(settings, permanent: true);

    final api = ApiServiceImpl(settingsService: settings);
    Get.put<ApiService>(api, permanent: true);

    final streaming = config.isRealApiEnabled('streaming')
        ? StreamingServiceImpl(apiService: api)
        : StreamingServiceMock();
    Get.put<StreamingService>(streaming, permanent: true);

    final sync = SyncServiceMock(cacheService: cache, settingsService: settings);
    Get.put<SyncService>(sync, permanent: true);

    final auth = preloadedAuth ?? AuthServiceImpl();
    Get.put<AuthService>(auth, permanent: true);

    final fixtures = FixturesServiceMock(cacheService: cache);
    Get.put<FixturesService>(fixtures, permanent: true);

    final match = MatchServiceMock(cacheService: cache, syncService: sync);
    Get.put<MatchService>(match, permanent: true);

    final standings = StandingsServiceMock(cacheService: cache);
    Get.put<StandingsService>(standings, permanent: true);

    final club = ClubServiceMock(cacheService: cache);
    Get.put<ClubService>(club, permanent: true);

    final roster = RosterServiceMock(syncService: sync);
    Get.put<RosterService>(roster, permanent: true);

    final store = StoreServiceMock();
    Get.put<StoreService>(store, permanent: true);
  }
}
