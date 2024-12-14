// Remove the general Firebase import and keep the specific one with prefix
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/core/presentation/widgets/poker_logo.dart';
import 'package:provider/provider.dart';
// Import your auth provider with a specific name
import 'package:poker_tracker/features/auth/providers/auth_provider.dart'
    show AppAuthProvider;
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';

enum GoogleSignInError {
  cancelled,
  networkError,
  alreadyInUse,
  invalidCredential,
  unknown;

  String get message {
    switch (this) {
      case GoogleSignInError.cancelled:
        return 'Sign in was cancelled';
      case GoogleSignInError.networkError:
        return 'A network error occurred. Please check your connection';
      case GoogleSignInError.alreadyInUse:
        return 'An account already exists with this email';
      case GoogleSignInError.invalidCredential:
        return 'Invalid credentials. Please try again';
      case GoogleSignInError.unknown:
        return 'An unknown error occurred';
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AppAuthProvider>().signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login failed: ${e.toString()}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontM,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSizes.paddingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    }
  }

  // Add this method to your _LoginScreenState class
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter your email address first',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontM,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSizes.paddingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      );
      return;
    }

    try {
      await context.read<AppAuthProvider>().sendPasswordResetEmail(
            _emailController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to ${_emailController.text}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontM,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSizes.paddingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reset email: ${e.toString()}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontM,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSizes.paddingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await context.read<AppAuthProvider>().signInWithGoogle();
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final error = _mapFirebaseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontM,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSizes.paddingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              GoogleSignInError.unknown.message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontM,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSizes.paddingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    }
  }

  GoogleSignInError _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'sign_in_canceled':
      case 'canceled':
        return GoogleSignInError.cancelled;
      case 'network-request-failed':
        return GoogleSignInError.networkError;
      case 'account-exists-with-different-credential':
      case 'email-already-in-use':
        return GoogleSignInError.alreadyInUse;
      case 'invalid-credential':
        return GoogleSignInError.invalidCredential;
      default:
        return GoogleSignInError.unknown;
    }
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF87CEEB).withOpacity(0.1), // Sky blue tint
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF87CEEB).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppAuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Darker background
      body: Stack(
        children: [
          // Background gradient circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF87CEEB).withOpacity(0.3), // Sky blue
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00BFFF).withOpacity(0.3), // Deep sky blue
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: size.height - MediaQuery.of(context).padding.top,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.padding2XL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 160,
                        child: PokerLogo(),
                      ),
                      const SizedBox(height: AppSizes.spacing3XL),

                      // Glass container for inputs
                      _buildGlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Email Field
                              TextField(
                                controller: _emailController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.8)),
                                  prefixIcon: Icon(Icons.mail_outline,
                                      color: const Color(0xFF87CEEB)
                                          .withOpacity(0.8)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: const Color(0xFF87CEEB)
                                            .withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: const Color(0xFF87CEEB)
                                            .withOpacity(0.6)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacingL),

                              // Password Field
                              TextField(
                                controller: _passwordController,
                                enabled: !isLoading,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.8)),
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: const Color(0xFF87CEEB)
                                          .withOpacity(0.8)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF87CEEB)
                                          .withOpacity(0.8),
                                    ),
                                    onPressed: () => setState(() =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: const Color(0xFF87CEEB)
                                            .withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: const Color(0xFF87CEEB)
                                            .withOpacity(0.6)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingM),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : _handleForgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: const Color(0xFF87CEEB).withOpacity(0.8),
                              fontSize: AppSizes.fontM,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingL),

                      // Login Button with glass effect
                      _buildGlassContainer(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF87CEEB).withOpacity(0.2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingL),

                      // Google Sign-In Button with glass effect
                      _buildGlassContainer(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF87CEEB).withOpacity(0.2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isLoading) ...[
                                  Image.asset('assets/google_logo.png',
                                      height: 94),
                                  const SizedBox(width: AppSizes.spacingM),
                                ],
                                if (isLoading)
                                  const CircularProgressIndicator(
                                      color: Colors.white)
                                else
                                  const Text(
                                    'Login with Google',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacing2XL),

                      // Register Link
                      Center(
                        child: TextButton(
                          onPressed:
                              isLoading ? null : () => context.go('/register'),
                          child: Text(
                            'Don\'t have an account? Register',
                            style: TextStyle(
                              color: const Color(0xFF87CEEB).withOpacity(0.8),
                              fontSize: AppSizes.fontM,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
