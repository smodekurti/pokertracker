import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:poker_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:poker_tracker/features/auth/presentation/screens/register_screen.dart';
import 'package:poker_tracker/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';
import 'package:poker_tracker/features/consent/presentation/screens/consent_screen.dart';
import 'package:poker_tracker/features/consent/providers/consent_provider.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/presentation/screens/active_game_screen.dart';
import 'package:poker_tracker/features/game/presentation/screens/game_history_screen.dart';
import 'package:poker_tracker/features/game/presentation/screens/game_settlement_summary_screen.dart';
import 'package:poker_tracker/features/game/presentation/screens/game_setup_screen.dart';
import 'package:poker_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:poker_tracker/features/home/presentation/screens/poker_reference_screen.dart';
import 'package:poker_tracker/features/team/presentation/screens/team_list_screen.dart';
import 'package:poker_tracker/features/team/presentation/screens/team_management_screen.dart';
import 'package:provider/provider.dart';

import '../../features/home/presentation/screens/author_credit_screen.dart';
// ... other imports remain the same

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static CustomTransitionPage<void> _buildPageTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  static GoRouter router(BuildContext context) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable:
          context.read<AppAuthProvider>(), // Refresh on auth changes
      redirect: (context, state) {
        final auth = context.read<AppAuthProvider>();
        final consent = context.read<ConsentProvider>();
        final isLoggedIn = auth.isAuthenticated;
        final hasAcceptedConsent = consent.hasAcceptedForSession;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        final isConsentRoute = state.matchedLocation == '/consent';

        // Not logged in -> login screen
        if (!isLoggedIn) {
          // Instead of immediately resetting, schedule it for next frame
          if (hasAcceptedConsent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              consent.reset();
            });
          }
          return isAuthRoute ? null : '/login';
        }

        // Logged in but no consent -> consent screen
        if (isLoggedIn && !hasAcceptedConsent && !isConsentRoute) {
          return '/consent';
        }

        // Logged in with consent, trying to go to auth/consent -> home
        if (isLoggedIn &&
            hasAcceptedConsent &&
            (isAuthRoute || isConsentRoute)) {
          return '/';
        }

        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/consent',
          name: 'consent',
          builder: (context, state) => const ConsentScreen(),
        ),

        // Home Route
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            // Nested Routes under Home
            GoRoute(
              path: 'game-setup',
              builder: (context, state) {
                // Verify provider availability
                return const GameSetupScreen();
              },
            ),
            GoRoute(
              path: 'game/:id',
              name: 'game',
              builder: (context, state) {
                final gameId = state.pathParameters['id'];
                if (gameId == null) {
                  return ErrorScreen(
                    message: 'Invalid Game ID',
                    onAction: () => context.go('/'),
                  );
                }
                return ActiveGameScreen(gameId: gameId);
              },
            ),
            GoRoute(
              path: 'game/:id/settlement',
              name: 'game-settlement',
              builder: (context, state) {
                final game = state.extra as Game?;
                if (game == null) {
                  return ErrorScreen(
                    message: 'Game data not found',
                    onAction: () => context.go('/'),
                  );
                }
                return GameSettlementSummaryScreen(game: game);
              },
            ),
            GoRoute(
                path: 'analytics',
                name: 'analytics',
                builder: (context, state) => const AnalyticsScreen()),
            GoRoute(
              path: 'poker-reference',
              builder: (context, state) => const PokerReferenceScreen(),
            ),
            GoRoute(
              path: 'teams',
              builder: (context, state) =>
                  const TeamListScreen(), // List of teams
            ),
            GoRoute(
              path: 'teams/new',
              builder: (context, state) => const TeamManagementScreen(),
            ),
            GoRoute(
              path: 'teams/:id',
              builder: (context, state) {
                final teamId = state.pathParameters['id']!;
                return TeamManagementScreen(teamId: teamId);
              },
            ),
            GoRoute(
              path: 'reset-password/:code',
              pageBuilder: (context, state) => _buildPageTransition(
                context: context,
                state: state,
                child: ResetPasswordScreen(
                  resetCode: state.pathParameters['code']!,
                ),
              ),
            ),
            GoRoute(
              path: 'history',
              name: 'history',
              builder: (context, state) => const GameHistoryScreen(),
            ),
            GoRoute(
              path: 'credits',
              builder: (context, state) => const AuthorCreditsScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => ErrorScreen(
        message: 'Page not found: ${state.matchedLocation}',
        onAction: () => context.go('/'),
      ),
    );
  }
}

// Updated Error Screen with more functionality
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onAction;
  final String actionLabel;

  const ErrorScreen({
    super.key,
    required this.message,
    required this.onAction,
    this.actionLabel = 'Go Home',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a), // Dark background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        const Color(0xFF4ade80), // AppColors.primary
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
