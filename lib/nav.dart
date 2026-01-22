import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_detox_master/pages/dashboard_page.dart';
import 'package:digital_detox_master/pages/habits_page.dart';
import 'package:digital_detox_master/pages/learn_page.dart';
import 'package:digital_detox_master/pages/profile_page.dart';
import 'package:digital_detox_master/widgets/scaffold_with_nav_bar.dart';
import 'package:digital_detox_master/pages/brain_training_page.dart';
import 'package:digital_detox_master/pages/math_trainer_page.dart';
import 'package:digital_detox_master/pages/focus_timer_page.dart';
import 'package:digital_detox_master/pages/sign_in_page.dart';
import 'package:digital_detox_master/supabase/supabase_config.dart';

// Private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final _shellNavigatorHabitsKey = GlobalKey<NavigatorState>(debugLabel: 'shellHabits');
final _shellNavigatorLearnKey = GlobalKey<NavigatorState>(debugLabel: 'shellLearn');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: _GoRouterRefreshStream(SupabaseConfig.auth.onAuthStateChange),
    redirect: (context, state) {
      final isLoggedIn = SupabaseConfig.auth.currentSession != null;
      final loggingIn = state.matchedLocation == AppRoutes.signIn;
      if (!isLoggedIn && !loggingIn) return AppRoutes.signIn;
      if (isLoggedIn && loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        name: 'sign_in',
        pageBuilder: (context, state) => const NoTransitionPage(child: SignInPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardPage(),
                ),
              ),
              GoRoute(
                path: AppRoutes.focus,
                name: 'focus',
                builder: (context, state) => const FocusTimerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHabitsKey,
            routes: [
              GoRoute(
                path: AppRoutes.habits,
                name: 'habits',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HabitsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLearnKey,
            routes: [
              GoRoute(
                path: AppRoutes.learn,
                name: 'learn',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: LearnPage(),
                ),
              ),
              GoRoute(
                path: AppRoutes.learnBrain,
                name: 'learn_brain',
                builder: (context, state) => const BrainTrainingPage(),
              ),
              GoRoute(
                path: AppRoutes.learnMath,
                name: 'learn_math',
                builder: (context, state) => const MathTrainerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppRoutes {
  static const String home = '/';
  static const String habits = '/habits';
  static const String learn = '/learn';
  static const String profile = '/profile';
  static const String focus = '/focus';
  static const String learnBrain = '/learn/brain';
  static const String learnMath = '/learn/math';
  static const String signIn = '/signin';
}

/// Notifier that refreshes the router when the provided stream emits.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListener = () => notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final VoidCallback notifyListener;
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
