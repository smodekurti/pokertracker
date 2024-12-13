import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/core/presentation/widgets/poker_logo.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  late AnimationController _dropletController;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dropletController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AppAuthProvider>().registerWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration failed: ${e.toString()}',
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

  @override
  void initState() {
    super.initState();
    _dropletController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool enabled = true,
  }) {
    return _buildGlassContainer(
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText:
            isPassword || isConfirmPassword ? !_isPasswordVisible : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: AppSizes.fontL,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF87CEEB).withOpacity(0.8),
          ),
          suffixIcon: (isPassword || isConfirmPassword)
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF87CEEB).withOpacity(0.8),
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingL,
            vertical: AppSizes.paddingXL,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppAuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Animated background droplets
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _dropletController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    20 * _dropletController.value,
                    10 * _dropletController.value,
                  ),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF87CEEB).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
              animation: _dropletController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -15 * _dropletController.value,
                    -10 * _dropletController.value,
                  ),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00BFFF).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.padding2XL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSizes.spacingXL),
                      const SizedBox(
                        height: 160,
                        child: PokerLogo(),
                      ),
                      const SizedBox(height: AppSizes.spacing2XL),

                      // Input fields with glass effect
                      _buildInputField(
                        controller: _nameController,
                        hint: 'Name',
                        icon: Icons.person_outline,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      _buildInputField(
                        controller: _emailController,
                        hint: 'Email',
                        icon: Icons.mail_outline,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      _buildInputField(
                        controller: _passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      _buildInputField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isConfirmPassword: true,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: AppSizes.spacing2XL),

                      // Register Button with glass effect
                      _buildGlassContainer(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleRegister,
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
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing2XL),

                      // Login link with glass effect
                      Center(
                        child: TextButton(
                          onPressed:
                              isLoading ? null : () => context.go('/login'),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [Color(0xFF87CEEB), Color(0xFF00BFFF)],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                fontSize: AppSizes.fontM,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingXL),
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
