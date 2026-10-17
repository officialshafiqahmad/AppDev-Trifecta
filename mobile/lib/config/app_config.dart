/// Non-secret client configuration injected via --dart-define.
/// No secrets or credentials may exist in this file.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.appName,
    required this.environment,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    this.useRealApi = const {
      'standings': false,
      'matchRead': false,
      'matchWrite': false,
      'store': false,
      'roster': false,
      'sync': false,
      'auth': false,
    },
  });

  /// Factory constructor to populate configuration from environment variables.
  factory AppConfig.fromEnvironment({Map<String, bool>? useRealApi}) {
    return AppConfig(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://astjq-203-99-61-238.free.pinggy.net',
      ),
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Trifecta',
      ),
      environment: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      connectTimeoutMs: const int.fromEnvironment(
        'CONNECT_TIMEOUT_MS',
        defaultValue: 10000,
      ),
      receiveTimeoutMs: const int.fromEnvironment(
        'RECEIVE_TIMEOUT_MS',
        defaultValue: 15000,
      ),
      useRealApi: useRealApi ?? const {
        'standings': false,
        'matchRead': false,
        'matchWrite': false,
        'store': false,
        'roster': false,
        'sync': false,
        'auth': false,
      },
    );
  }

  final String apiBaseUrl;
  final String appName;
  final String environment;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final Map<String, bool> useRealApi;

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';

  bool isRealApiEnabled(String serviceKey) => useRealApi[serviceKey] ?? false;
}
