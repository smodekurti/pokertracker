import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';

import '../widgets/game_history_card.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  int _currentIndex = 3; // Set to History tab index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.primaryGradient,
          ).createShader(bounds),
          child: const Text(
            'Game History',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: _buildContent(context),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final games = gameProvider.gameHistory;

        if (games.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSizes.paddingL.dp),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppSizes.paddingM.dp),
              child: GameHistoryCard(game: game),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino_outlined,
            size: AppSizes.iconXL.dp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSizes.spacingL.dp),
          Text(
            'No completed games yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.spacingS.dp),
          Text(
            'Start a new game to see your history here',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          SizedBox(height: AppSizes.spacing2XL.dp),
          ElevatedButton(
            onPressed: () => context.go('/game-setup'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.padding2XL.dp,
                vertical: AppSizes.paddingM.dp,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              ),
            ),
            child: Text(
              'Start New Game',
              style: TextStyle(
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundMedium,
        border: Border(
          top: BorderSide(
            color: AppColors.backgroundMedium,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, () => context.go('/')),
              _buildNavItem(
                  Icons.group, 'Teams', 1, () => context.go('/teams')),
              _buildNavItem(Icons.bar_chart, 'Game Stats', 2,
                  () => context.go('/analytics')),
              _buildNavItem(Icons.history, 'Game History', 3, () {}),
              _buildNavItem(Icons.tips_and_updates, 'Tips', 4,
                  () => context.go('/poker-reference')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, VoidCallback onTap) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
