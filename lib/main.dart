import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const ProviderScope(
      child: AwraApp(),
    ),
  );
}

class AwraApp extends StatelessWidget {
  const AwraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awra Spin Wheel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (ctx) => const AuthGate(),
        '/login': (ctx) => const LoginScreen(),
        '/dashboard': (ctx) => const DashboardScreen(),
        '/game': (ctx) => const GameScreen(),
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    // Since Firebase auth resolves quickly enough, we just check if it's null.
    // Riverpod's keepAlive: true ensures stream is active.
    return user != null ? const DashboardScreen() : const LoginScreen();
  }
}
