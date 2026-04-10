import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/screens/onboarding_goal_screen.dart';
import '../../features/onboarding/screens/onboarding_usage_screen.dart';
import '../../features/onboarding/screens/onboarding_shock_screen.dart';
import '../../features/onboarding/screens/onboarding_permission_screen.dart';
import '../../features/paywall/screens/paywall_screen.dart';
import '../../features/paywall/screens/paywall_feature_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/block/screens/block_setup_screen.dart';
import '../../features/block/screens/blocking_active_screen.dart';
import '../../features/block/screens/block_complete_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../constants/app_constants.dart';

class AppRoutes {
  static const onboardingGoal = '/onboarding/goal';
  static const onboardingUsage = '/onboarding/usage';
  static const onboardingShock = '/onboarding/shock';
  static const onboardingPermission = '/onboarding/permission';
  static const paywall = '/paywall';
  static const paywallFeature = '/paywall/feature';
  static const home = '/home';
  static const blockSetup = '/lock';
  static const blockingActive = '/block/active';
  static const blockComplete = '/block/complete';
  static const stats = '/stats';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboardingGoal,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
      if (onboardingDone &&
          state.matchedLocation.startsWith('/onboarding')) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // オンボーディング
      GoRoute(
        path: AppRoutes.onboardingGoal,
        builder: (context, state) => const OnboardingGoalScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingUsage,
        builder: (context, state) => const OnboardingUsageScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingShock,
        builder: (context, state) {
          final minutes = state.extra as int? ?? 240;
          return OnboardingShockScreen(dailyMinutes: minutes);
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingPermission,
        builder: (context, state) => const OnboardingPermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) {
          final fromOnboarding = state.extra as bool? ?? false;
          return PaywallScreen(fromOnboarding: fromOnboarding);
        },
      ),
      GoRoute(
        path: AppRoutes.paywallFeature,
        builder: (context, state) {
          final featureKey = state.extra as String? ?? 'premium';
          return PaywallFeatureScreen(featureKey: featureKey);
        },
      ),

      // メイン（4タブ ShellRoute）
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.blockSetup,
            builder: (context, state) => const BlockSetupScreen(),
          ),
          GoRoute(
            path: AppRoutes.stats,
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // フルスクリーン（BottomNavなし）
      GoRoute(
        path: AppRoutes.blockingActive,
        builder: (context, state) {
          final args = state.extra as BlockingActiveArgs?;
          return BlockingActiveScreen(
              args: args ?? const BlockingActiveArgs());
        },
      ),
      GoRoute(
        path: AppRoutes.blockComplete,
        builder: (context, state) {
          final args = state.extra as BlockCompleteArgs?;
          return BlockCompleteScreen(
              args: args ?? const BlockCompleteArgs());
        },
      ),
    ],
  );
});

// ─── 4タブ BottomNav シェル ──────────────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location == AppRoutes.blockSetup) currentIndex = 1;
    if (location == AppRoutes.stats) currentIndex = 2;
    if (location == AppRoutes.settings) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF2E3440), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go(AppRoutes.home);
              case 1:
                context.go(AppRoutes.blockSetup);
              case 2:
                context.go(AppRoutes.stats);
              case 3:
                context.go(AppRoutes.settings);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lock_outline),
              activeIcon: Icon(Icons.lock),
              label: 'ロック',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: '記録',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 引数クラス ──────────────────────────────────────────
class BlockingActiveArgs {
  final List<String> appNames;
  final int durationMinutes;
  final bool strictMode;

  const BlockingActiveArgs({
    this.appNames = const [],
    this.durationMinutes = 25,
    this.strictMode = false,
  });
}

class BlockCompleteArgs {
  final int elapsedSeconds;
  final List<String> appNames;

  const BlockCompleteArgs({
    this.elapsedSeconds = 0,
    this.appNames = const [],
  });
}
