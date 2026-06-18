import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: const BaxApp(),
    ),
  );
}

class BaxApp extends StatelessWidget {
  const BaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bax',
      debugShowCheckedModeBanner: false,
      theme: buildBaxTheme(),
      home: const RootRouter(),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.booting) return const SplashScreen();
    if (!state.isLoggedIn) return const WelcomeScreen();
    return const HomeShell();
  }
}
