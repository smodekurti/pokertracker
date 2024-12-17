import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:go_router/go_router.dart';

class AuthorCreditsScreen extends StatefulWidget {
  const AuthorCreditsScreen({super.key});

  @override
  State<AuthorCreditsScreen> createState() => _AuthorCreditsScreenState();
}

class _AuthorCreditsScreenState extends State<AuthorCreditsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.backgroundGradient,
                ),
              ),
            ),
            // Back Button
            Positioned(
              top: AppSizes.paddingL,
              left: AppSizes.paddingL,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            // Main Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Author Avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              color: AppColors.textPrimary,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingXL),
                        // Developer Title
                        const Text(
                          'Developer',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontL,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        // Author Name
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ).createShader(bounds),
                          child: const Text(
                            'Vasu Modekurti',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppSizes.font3XL,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingXL),
                        // Divider
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingXL),
                        // App Title
                        const Text(
                          'Poker Tracker',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppSizes.fontXL,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        // Copyright
                        Text(
                          '© ${DateTime.now().year} All rights reserved',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontM,
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
      ),
    );
  }
}
