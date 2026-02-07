import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
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
        Provider.value(value: preferencesService),
      ],
      child: MaterialApp(
        title: 'MicroHelp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
