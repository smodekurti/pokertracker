import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:poker_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:poker_tracker/features/auth/presentation/screens/register_screen.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/presentation/screens/active_game_screen.dart';
import 'package:poker_tracker/features/game/presentation/screens/game_history_screen.dart';
import 'package:poker_tracker/features/game/presentation/screens/game_settlement_summary_screen.dart';
import 'package:poker_tracker/features/game/presentation/screens/game_setup_screen.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:poker_tracker/features/home/presentation/screens/poker_reference_screen.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';
// ... other imports remain the same

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(BuildContext context) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable:
          context.read<AuthProvider>(), // Refresh on auth changes
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isLoggedIn = auth.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // Handle authentication redirects
        if (!isLoggedIn) {
          return isAuthRoute ? null : '/login';
        }

        // Redirect authenticated users away from auth routes
        if (isAuthRoute) {
          return '/';
        }

        // Check if GameProvider is available for game routes
        if (state.matchedLocation.startsWith('/game')) {
          final gameProvider = context.read<GameProvider?>();
          if (gameProvider == null) {
            return '/'; // Redirect to home if GameProvider isn't ready
          }
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

        // Home Route
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            // Nested Routes under Home
            GoRoute(
              path: 'game-setup',
              name: 'game-setup',
              builder: (context, state) => const GameSetupScreen(),
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
              path: 'history',
              name: 'history',
              builder: (context, state) => const GameHistoryScreen(),
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
