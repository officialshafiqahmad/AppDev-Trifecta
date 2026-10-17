/// Non-secret client configuration injected via --dart-define.
/// No secrets or credentials may exist in this file.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.appName,
    required this.environment,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
  });

  /// Factory constructor to populate configuration from environment variables.
  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8080', // Android emulator default to host (WITHOUT /api)
      ),
      appName: String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Trifecta',
      ),
      environment: String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      connectTimeoutMs: int.fromEnvironment(
        'CONNECT_TIMEOUT_MS',
        defaultValue: 10000,
      ),
      receiveTimeoutMs: int.fromEnvironment(
        'RECEIVE_TIMEOUT_MS',
        defaultValue: 15000,
      ),
    );
  }

  final String apiBaseUrl;
  final String appName;
  final String environment;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
}
