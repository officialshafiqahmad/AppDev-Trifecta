import '../../core/utils/result.dart';

/// Server connectivity and device configuration settings.
class ServerSettings {
  const ServerSettings({
    required this.host,
    required this.port,
    required this.deviceId,
  });

  final String host;
  final int port;
  final String deviceId;

  String get baseUrl {
    final clean = host.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    return 'http://$clean:$port';
  }
}

/// Settings service contract.
abstract class SettingsService {
  Future<Result<ServerSettings>> getSettings();
  Future<Result<void>> updateServerHost(String host);
  Future<Result<String>> getDeviceId();
}
