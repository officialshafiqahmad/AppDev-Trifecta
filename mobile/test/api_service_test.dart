import 'package:flutter_test/flutter_test.dart';
import 'package:trifecta/core/strings/app_strings.dart';
import 'package:trifecta/core/utils/api_error_mapper.dart';
import 'package:trifecta/core/utils/result.dart';
import 'package:trifecta/services/api/api_service_impl.dart';
import 'package:trifecta/services/settings/settings_service.dart';

class _FakeSettingsService implements SettingsService {
  _FakeSettingsService(this.baseUrl);
  final String baseUrl;

  @override
  Future<Result<ServerSettings>> getSettings() async {
    return Success(
      ServerSettings(
        host: baseUrl,
        port: 8080,
        deviceId: 'dev-smoke-test',
      ),
    );
  }

  @override
  Future<Result<String>> getDeviceId() async => const Success('dev-smoke-test');

  @override
  Future<Result<void>> updateServerHost(String host) async => const Success(null);
}

void main() {
  group('ApiErrorMapper', () {
    test('maps all canonical codes properly', () {
      expect(ApiErrorMapper.userMessageKeyForCode('VALIDATION_ERROR'), AppStrings.errValidation);
      expect(ApiErrorMapper.userMessageKeyForCode('UNKNOWN_EVENT_TYPE'), AppStrings.errUnknownEventType);
      expect(ApiErrorMapper.userMessageKeyForCode('INVALID_DISCOUNT_CODE'), AppStrings.errInvalidDiscountCode);
      expect(ApiErrorMapper.userMessageKeyForCode('PAYMENT_DECLINED'), AppStrings.errPaymentDeclined);
      expect(ApiErrorMapper.userMessageKeyForCode('PAYMENT_CAPTURE_FAILED'), AppStrings.errPaymentCaptureFailed);
      expect(ApiErrorMapper.userMessageKeyForCode('OUT_OF_STOCK'), AppStrings.errOutOfStock);
      expect(ApiErrorMapper.userMessageKeyForCode('MATCH_NOT_FOUND'), AppStrings.errNotFound);
      expect(ApiErrorMapper.userMessageKeyForCode('SPORT_NOT_FOUND'), AppStrings.errNotFound);
      expect(ApiErrorMapper.userMessageKeyForCode('NON_EXISTENT_CODE'), AppStrings.errDefault);
    });
  });

  group('ApiService Smoke Target', () {
    test('GET /api/v1/ping against running backend returns pong: true', () async {
      final settings = _FakeSettingsService('https://astjq-203-99-61-238.free.pinggy.net');
      final api = ApiServiceImpl(settingsService: settings);

      final res = await api.get('/api/v1/ping');
      expect(res.isSuccess, isTrue);

      final data = res.dataOrNull;
      expect(data, isA<Map<String, dynamic>>());
      expect((data as Map<String, dynamic>)['pong'], isTrue);
    });
  });
}
