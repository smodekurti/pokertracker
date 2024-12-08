import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:poker_tracker/config/env_config.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';
import 'package:poker_tracker/features/consent/providers/consent_provider.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/team/providers/team_provider.dart';
import 'package:poker_tracker/firebase_options.dart';
import 'package:poker_tracker/core/app.dart';
import 'package:poker_tracker/core/database/database_initializer.dart';
import 'package:provider/provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize environment with error handling
    try {
      await EnvironmentConfig.init();
    } catch (e) {
      debugPrint('Error initializing environment: $e');
      rethrow;
    }

    // Initialize SQLite database
    try {
      await DatabaseInitializer.initDatabase();
    } catch (e) {
      debugPrint('Error initializing SQLite database: $e');
      rethrow;
    }

    // Initialize Firebase with error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }

    runApp(
      ErrorBoundary(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppAuthProvider()),
            ChangeNotifierProvider(create: (_) => ConsentProvider()),
            ChangeNotifierProxyProvider<AppAuthProvider, TeamProvider>(
              create: (context) {
                final auth = context.read<AppAuthProvider>();
                final userId = auth.currentUser?.uid ?? '';
                return TeamProvider(userId);
              },
              update: (context, authProvider, teamProvider) {
                final userId = authProvider.currentUser?.uid ?? '';
                teamProvider?.dispose();
                return TeamProvider(userId);
              },
            ),
            ChangeNotifierProxyProvider<AppAuthProvider, GameProvider?>(
              create: (_) => null,
              update: (context, authProvider, previousGameProvider) {
                final userId = authProvider.currentUser?.uid;
                if (userId != null) {
                  previousGameProvider?.dispose();
                  return GameProvider(userId);
                }
                return null;
              },
            ),
          ],
          child: const PokerTrackerApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Fatal error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    runApp(
      MaterialApp(
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingL.dp),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: AppSizes.iconXL.dp,
                      ),
                      SizedBox(height: AppSizes.spacingL.dp),
                      Text(
                        'Application Error',
                        style: TextStyle(
                          fontSize: AppSizes.font2XL.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSizes.spacingS.dp),
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: AppSizes.fontM.sp,
                        ),
                      ),
                      SizedBox(height: AppSizes.spacingL.dp),
                      SizedBox(
                        width: 200.dp,
                        child: ElevatedButton(
                          onPressed: () => main(),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingXL.dp,
                              vertical: AppSizes.paddingM.dp,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusM.dp),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(fontSize: AppSizes.fontL.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, widget) {
        Responsive.init(context);

        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingL.dp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: AppSizes.iconXL.dp,
                    ),
                    SizedBox(height: AppSizes.spacingL.dp),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: AppSizes.font2XL.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingS.dp),
                    Text(
                      errorDetails.exceptionAsString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: AppSizes.fontM.sp,
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingL.dp),
                    SizedBox(
                      width: 200.dp,
                      child: ElevatedButton(
                        onPressed: () => main(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingXL.dp,
                            vertical: AppSizes.paddingM.dp,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusM.dp),
                          ),
                        ),
                        child: Text(
                          'Restart App',
                          style: TextStyle(fontSize: AppSizes.fontL.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return widget ?? const SizedBox.shrink();
      },
      home: child,
    );
  }
}
