import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bax_logo.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final info = context.watch<AppState>().appInfo;
    final sports = ['⚽ Soccer', '🏀 Basketball', '🏎️ Formula 1', '🎾 Tennis',
        '🏏 Cricket', '🏉 Rugby', '🏈 NFL', '🏊 Swimming'];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Center(child: BaxLogo(size: 64)),
                  const SizedBox(height: 28),
                  Text(
                    info?.tagline ?? 'All sports. One subscription.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Stream live soccer, basketball, Formula 1, tennis, cricket, '
                    'rugby, American football and more — on any device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BaxColors.muted, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: sports
                        .map((s) => Chip(
                              label: Text(s),
                              backgroundColor: BaxColors.card,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: BaxColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BaxColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          info?.priceDisplay ?? 'N\$200/month',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: BaxColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Cancel anytime • Up to 2 profiles',
                            style: TextStyle(color: BaxColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: BaxColors.muted),
                      foregroundColor: BaxColors.text,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('I already have an account',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
