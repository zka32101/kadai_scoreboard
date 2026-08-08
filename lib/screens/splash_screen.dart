import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadai_scoreboard/providers/auth_provider.dart';
import 'package:kadai_scoreboard/providers/user_provider.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isProfileComplete = ref.watch(isProfileCompleteProvider);

    return currentUser.when(
      data: (user) {
        if (user != null) {
          if (isProfileComplete) {
            return const DashboardScreen();
          } else {
            return const OnboardingScreen();
          }
        } else {
          return const LoginScreen();
        }
      },
      loading: () {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  '課題スコアボード',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
        );
      },
      error: (err, stack) {
        return Scaffold(
          body: Center(
            child: Text('Error: $err'),
          ),
        );
      },
    );
  }
}
