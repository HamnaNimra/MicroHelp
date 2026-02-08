import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/preferences_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/splash_screen.dart';

class MicroHelpApp extends StatelessWidget {
  const MicroHelpApp({super.key, required this.preferencesService});

  final PreferencesService preferencesService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => NotificationService()),
        ProxyProvider<NotificationService, AuthService>(
          create: (context) => AuthService(context.read<NotificationService>()),
          update: (context, notificationService, previous) =>
            previous ?? AuthService(notificationService),
        ),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => AnalyticsService()),
        Provider.value(value: preferencesService),
        ChangeNotifierProvider(
          create: (context) =>
              ThemeProvider(context.read<PreferencesService>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final analytics = context.read<AnalyticsService>();
          return MaterialApp(
            title: 'MicroHelp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            navigatorObservers: [analytics.observer],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
