import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/config/theme_config.dart';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/settings/providers/settings_provider.dart';
import 'package:poker_tracker/features/team/providers/team_provider.dart';
import 'package:poker_tracker/core/routes/app_router.dart';

class PokerTrackerApp extends StatelessWidget {
  const PokerTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        // Team Provider - depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, TeamProvider?>(
          create: (_) => null,
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) return null;
            if (auth.user?.uid != null) {
              // Reuse previous instance if userId hasn't changed
              if (previous != null) {
                return previous;
              }
              return TeamProvider(auth.user!.uid);
            }
            return null;
          },
        ),

        // Game Provider - depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, GameProvider?>(
          create: (_) => null,
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) return null;
            return auth.user?.uid != null ? GameProvider(auth.user!.uid) : null;
          },
        ),

        // Settings Provider - depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider?>(
          create: (_) => null,
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) return null;
            return auth.user?.uid != null
                ? SettingsProvider(auth.user!.uid)
                : null;
          },
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          title: 'Poker Tracker',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router(context),
        ),
      ),
    );
  }
}
