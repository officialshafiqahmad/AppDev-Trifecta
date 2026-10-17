import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'config/app_config.dart';
import 'core/bindings/initial_binding.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/strings/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'services/auth/auth_service_impl.dart';

/// Application entry point with session restoration.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  // Rule G7: Restore session from storage on cold start
  final authService = AuthServiceImpl();
  String initialRoute = AppPages.initial;
  try {
    final isAuthRes = await authService.isAuthenticated();
    if (isAuthRes.isSuccess && isAuthRes.dataOrNull == true) {
      final userRes = await authService.getCurrentUser();
      if (userRes.isSuccess && userRes.dataOrNull != null) {
        initialRoute = AppRoutes.main;
      }
    }
  } catch (_) {}

  runApp(TrifectaApp(
    config: config,
    initialRoute: initialRoute,
    preloadedAuth: authService,
  ));
}

/// Root application widget configuring theme, routes, translations, and font clamping.
class TrifectaApp extends StatelessWidget {
  const TrifectaApp({
    super.key,
    required this.config,
    this.initialRoute = AppPages.initial,
    this.preloadedAuth,
  });

  final AppConfig config;
  final String initialRoute;
  final AuthServiceImpl? preloadedAuth;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Trifecta',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(config, preloadedAuth: preloadedAuth),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clampedScaler = media.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.30,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
