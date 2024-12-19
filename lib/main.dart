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
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize environment variables
    try {
      await EnvironmentConfig.init();
    } catch (e) {
      debugPrint('Error initializing environment: $e');
      rethrow; // Re-throw the error to propagate it up
    }

    // Initialize SQLite database
    try {
      await DatabaseInitializer.initDatabase();
    } catch (e) {
      debugPrint('Error initializing SQLite database: $e');
      rethrow; // Re-throw the error to propagate it up
    }

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow; // Re-throw the error to propagate it up
    }

    // Run the app with error boundary and providers
    runApp(
      ErrorBoundary(
        // Wrap the app with an error boundary to catch runtime errors
        child: MultiProvider(
          // Provide multiple providers for state management
          providers: [
            // Auth provider
            ChangeNotifierProvider(create: (_) => AppAuthProvider()),
            // Consent provider
            ChangeNotifierProvider(create: (_) => ConsentProvider()),
            // Team provider (depends on auth)
            ChangeNotifierProxyProvider<AppAuthProvider, TeamProvider>(
              create: (context) {
                final auth = context.read<AppAuthProvider>();
                final userId = auth.currentUser?.uid ?? '';
                return TeamProvider(userId);
              },
              update: (context, authProvider, teamProvider) {
                final userId = authProvider.currentUser?.uid ?? '';
                teamProvider?.dispose(); // Dispose of the old provider
                return TeamProvider(userId); // Create a new provider
              },
            ),
            // Game provider (depends on auth)
            ChangeNotifierProxyProvider<AppAuthProvider, GameProvider?>(
              create: (_) => null,
              update: (context, authProvider, previousGameProvider) {
                final userId = authProvider.currentUser?.uid;
                if (userId != null) {
                  previousGameProvider
                      ?.dispose(); // Dispose of the old provider
                  return GameProvider(userId); // Create a new provider
                }
                return null; // Return null if not authenticated
              },
            ),
          ],
          child: const PokerTrackerApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    // Catch and display fatal errors during initialization
    debugPrint('Fatal error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show an error screen if initialization fails
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
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
                      // Error icon
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: AppSizes.iconXL.dp,
                      ),
                      SizedBox(height: AppSizes.spacingL.dp),
                      // Error title
                      const Text(
                        'Application Error',
                        style: TextStyle(
                          fontSize: 28, // Adjust font size as needed
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSizes.spacingS.dp),
                      // Error message
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16, // Adjust font size as needed
                        ),
                      ),
                      SizedBox(height: AppSizes.spacingL.dp),
                      // Retry button
                      SizedBox(
                        width: 200.dp,
                        child: ElevatedButton(
                          onPressed: () => main(), // Retry initialization
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
                          child: const Text('Retry'), // Button text
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

// Widget for handling runtime errors
class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, widget) {
        Responsive.init(context);

        // Custom error widget builder
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingL.dp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Warning icon
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: AppSizes.iconXL.dp,
                    ),
                    SizedBox(height: AppSizes.spacingL.dp),
                    // Error title
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 28, // Adjust font size as needed

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingS.dp),
                    // Error message
                    Text(
                      errorDetails.exceptionAsString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 16, // Adjust font size as needed
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingL.dp),
                    // Restart button
                    SizedBox(
                      width: 200.dp,
                      child: ElevatedButton(
                        onPressed: () => main(), // Restart the app
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
                        child: const Text('Restart App'), // Button text
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
