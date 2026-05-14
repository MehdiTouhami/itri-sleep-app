import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash_screen.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'core/theme/app_theme.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',            builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/home',        builder: (_, __) => const AppShell()),
    GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/settings',    builder: (_, __) => const SettingsScreen()),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: ItriSleepApp()));
}

class ItriSleepApp extends StatelessWidget {
  const ItriSleepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Itri Sleep',
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
