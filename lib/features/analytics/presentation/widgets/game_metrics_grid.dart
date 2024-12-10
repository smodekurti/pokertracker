import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';

class GameMetricsGrid extends StatelessWidget {
  final GameProvider gameProvider;
  const GameMetricsGrid({super.key, required this.gameProvider});

  @override
  Widget build(BuildContext context) {
    final metrics = _calculateMetrics();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: metrics.map((metric) => _buildMetricCard(metric)).toList(),
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> metric) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              metric['label'],
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              metric['value'],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateMetrics() {
    final totalGames = gameProvider.gameHistory.length;
    final totalPlayers = gameProvider.gameHistory
        .expand((game) => game.players)
        .map((player) => player.name)
        .toSet()
        .length;
    double totalPot = 0;
    double maxPot = 0;
    for (final game in gameProvider.gameHistory) {
      totalPot += game.totalPot;
      if (game.totalPot > maxPot) maxPot = game.totalPot;
    }
    return [
      {'label': 'Total Games', 'value': totalGames.toString()},
      {'label': 'Unique Players', 'value': totalPlayers.toString()},
      {
        'label': 'Total Money Played',
        'value': '\$${totalPot.toStringAsFixed(0)}'
      },
      {'label': 'Biggest Pot', 'value': '\$${maxPot.toStringAsFixed(0)}'},
    ];
  }
}
