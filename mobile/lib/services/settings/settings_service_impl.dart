import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../storage/storage_service.dart';
import 'settings_service.dart';

/// Implementation storing server address and device identity.
class SettingsServiceImpl implements SettingsService {
  SettingsServiceImpl({required this.storageService});

  final StorageService storageService;

  static const String _keyHost = 'settings_server_host';
  static const String _keyDeviceId = 'settings_device_id';
  static const String _defaultHost = 'https://astjq-203-99-61-238.free.pinggy.net';
  static const int _fixedPort = 8080;
  static const String _defaultDeviceId = 'dev-1';

  @override
  Future<Result<ServerSettings>> getSettings() async {
    try {
      final hostRes = await storageService.getString(_keyHost);
      final devIdRes = await storageService.getString(_keyDeviceId);

      final host = (hostRes.isSuccess && hostRes.dataOrNull != null)
          ? hostRes.dataOrNull!
          : _defaultHost;

      final devId = (devIdRes.isSuccess && devIdRes.dataOrNull != null)
          ? devIdRes.dataOrNull!
          : _defaultDeviceId;

      return Success(
        ServerSettings(
          host: host,
          port: _fixedPort,
          deviceId: devId,
        ),
      );
    } catch (e) {
      return const Failure(
        AppFailure(
          code: 'SETTINGS_READ_ERROR',
          userMessageKey: AppStrings.errDefault,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateServerHost(String host) async {
    final cleanHost = host.trim().replaceAll(RegExp(r'/+$'), '');
    return storageService.setString(_keyHost, cleanHost);
  }

  @override
  Future<Result<String>> getDeviceId() async {
    final settingsRes = await getSettings();
    return switch (settingsRes) {
      Success(:final value) => Success(value.deviceId),
      Failure(:final failure) => Failure(failure),
    };
  }
}
