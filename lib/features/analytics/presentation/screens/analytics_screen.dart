import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/analytics/presentation/widgets/player_performance_section.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../game/data/models/game.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _currentIndex = 2; // Analytics tab

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final games = gameProvider.gameHistory;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.primaryGradient,
          ).createShader(bounds),
          child: const Text(
            'Game Analytics',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(gameProvider),
                const SizedBox(height: 24),
                _buildStatsOverview(games),
                const SizedBox(height: 24),
                PlayerPerformanceSection(games: games),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader(GameProvider gameProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Highlights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${gameProvider.gameHistory.length} games',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(List<Game> games) {
    final stats = _calculateOverallStats(games);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
            'Total Pot', '\$${stats['totalPot']?.toStringAsFixed(0)}'),
        _buildStatCard(
            'Biggest Pot', '\$${stats['maxPot']?.toStringAsFixed(0)}'),
        _buildStatCard('Players', stats['uniquePlayers'].toString()),
        _buildStatCard(
            'Avg. Buy-in', '\$${stats['avgBuyIn']?.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateOverallStats(List<Game> games) {
    double totalPot = 0;
    double maxPot = 0;
    double totalBuyIn = 0;
    final uniquePlayers = <String>{};

    for (final game in games) {
      double gameTotal = game.totalPot;
      if (game.cutPercentage! > 0) {
        gameTotal = game.totalPot * (game.cutPercentage / 100);
      }
      totalPot += gameTotal;
      maxPot = maxPot < game.totalPot ? game.totalPot : maxPot;
      totalBuyIn += game.buyInAmount;
      uniquePlayers.addAll(game.players.map((p) => p.name));
    }

    return {
      'totalPot': totalPot,
      'maxPot': maxPot,
      'uniquePlayers': uniquePlayers.length,
      'avgBuyIn': games.isEmpty ? 0 : totalBuyIn / games.length,
    };
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
              _buildNavItem(Icons.bar_chart, 'Game Stats', 2, () {}),
              _buildNavItem(Icons.history, 'Game History', 3,
                  () => context.go('/history')),
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
