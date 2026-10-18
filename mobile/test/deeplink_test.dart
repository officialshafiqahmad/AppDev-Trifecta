import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trifecta/config/app_config.dart';
import 'package:trifecta/core/routes/app_routes.dart';
import 'package:trifecta/main.dart';
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

  group('DeepLink Views Widget Tests', () {
    testWidgets('MatchLiveView renders successfully', (tester) async {
      final config = AppConfig.fromEnvironment();
      await tester.pumpWidget(TrifectaApp(
        config: config,
        initialRoute: AppRoutes.matchLive,
        initialDeepLinkUri: 'nascon://entity/match-m1',
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('match_live_header')), findsOneWidget);
      expect(find.byKey(const ValueKey('live-score-banner')), findsOneWidget);
    });

    testWidgets('CoStreamView renders successfully', (tester) async {
      final config = AppConfig.fromEnvironment();
      await tester.pumpWidget(TrifectaApp(
        config: config,
        initialRoute: AppRoutes.coStream,
        initialDeepLinkUri: 'nascon://stream/cs-session-101',
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('costream_header')), findsOneWidget);
    });

    testWidgets('QrScannerView renders successfully with viewfinder and resolve button', (tester) async {
      final config = AppConfig.fromEnvironment();
      await tester.pumpWidget(TrifectaApp(
        config: config,
        initialRoute: AppRoutes.qrScanner,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('qr_scanner_header')), findsOneWidget);
      expect(find.byKey(const ValueKey('qr-code-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('qr-resolve-btn')), findsOneWidget);
    });
  });
}
