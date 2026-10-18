import 'package:flutter_test/flutter_test.dart';
import 'package:trifecta/core/routes/app_routes.dart';
import 'package:trifecta/services/deeplink/deeplink_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkService URI Parsing Tests', () {
    test('Correctly parses and extracts matchId from nascon://entity/match-m1', () {
      final service = DeepLinkServiceImpl(initialUri: 'nascon://entity/match-m1');
      expect(service.lastMatchId, equals('match-m1'));
    });

    test('Correctly parses and extracts sessionId from nascon://stream/cs-session-101', () {
      final service = DeepLinkServiceImpl(initialUri: 'nascon://stream/cs-session-101');
      expect(service.lastSessionId, equals('cs-session-101'));
    });

    test('Ignores invalid scheme URIs', () {
      final service = DeepLinkServiceImpl(initialUri: 'https://example.com/match-m1');
      expect(service.lastMatchId, isNull);
      expect(service.lastSessionId, isNull);
    });
  });

  group('DeepLink Route Constants Tests', () {
    test('Defines matchLive and coStream routes correctly', () {
      expect(AppRoutes.matchLive, equals('/match-live'));
      expect(AppRoutes.coStream, equals('/co-stream'));
    });
  });
}
