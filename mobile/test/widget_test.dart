import 'package:flutter_test/flutter_test.dart';
import 'package:trifecta/config/app_config.dart';
import 'package:trifecta/main.dart';

void main() {
  testWidgets('App root initializes properly and displays Role Selection screen', (WidgetTester tester) async {
    final config = AppConfig.fromEnvironment();
    await tester.pumpWidget(TrifectaApp(config: config));
    await tester.pumpAndSettle();

    expect(find.text('Select Your Role'), findsOneWidget);
    expect(find.text('League Organizer'), findsOneWidget);
    expect(find.text('Club Manager'), findsOneWidget);

    // Tap on League Organizer
    await tester.tap(find.text('League Organizer'));
    await tester.pumpAndSettle();

    // Verifies navigation to LoginView with prefilled email
    expect(find.text('Sign In to Trifecta'), findsOneWidget);
    expect(find.text('organizer@nascon.test'), findsWidgets);
  });
}
