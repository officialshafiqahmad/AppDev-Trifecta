import 'package:flutter_test/flutter_test.dart';
import 'package:trifecta/config/app_config.dart';
import 'package:trifecta/main.dart';

void main() {
  testWidgets('App root initializes properly', (WidgetTester tester) async {
    final config = AppConfig.fromEnvironment();
    await tester.pumpWidget(TrifectaApp(config: config));
    await tester.pump();
  });
}
