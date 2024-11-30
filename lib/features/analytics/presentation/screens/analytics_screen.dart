// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:poker_tracker/features/analytics/presentation/widgets/player_performance_section.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:go_router/go_router.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = context.watch<GameProvider>().gameHistory;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${games.length} games',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStatsOverview(games),
                const SizedBox(height: 24),
                // _buildProfitChart(games),
                const SizedBox(height: 24),
                PlayerPerformanceSection(games: games),
              ],
            ),
          ),
        ),
      ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[850]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
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
      totalPot += game.totalPot;
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
}
