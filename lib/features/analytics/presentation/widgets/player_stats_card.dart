// lib/features/analytics/presentation/widgets/player_stats_card.dart

import 'package:flutter/material.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';

class PlayerStatsCard extends StatelessWidget {
  final GameProvider gameProvider;

  const PlayerStatsCard({super.key, required this.gameProvider});

  @override
  Widget build(BuildContext context) {
    final playerStats = _calculateDetailedPlayerStats();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          dataTextStyle: TextStyle(
            color: Colors.grey[300],
          ),
          columns: const [
            DataColumn(label: Text('Player')),
            DataColumn(label: Text('Games')),
            DataColumn(label: Text('Win Rate')),
            DataColumn(label: Text('Total Profit')),
            DataColumn(label: Text('Avg. Profit/Game')),
            DataColumn(label: Text('Biggest Win')),
          ],
          rows: playerStats.map((stats) {
            return DataRow(
              cells: [
                DataCell(Text(stats['name'])),
                DataCell(Text(stats['gamesPlayed'].toString())),
                DataCell(Text('${stats['winRate'].toStringAsFixed(1)}%')),
                DataCell(Text(
                  '\$${stats['totalProfit'].toStringAsFixed(0)}',
                  style: TextStyle(
                    color: stats['totalProfit'] >= 0
                        ? Colors.green[300]
                        : Colors.red[300],
                  ),
                )),
                DataCell(Text(
                  '\$${stats['avgProfitPerGame'].toStringAsFixed(0)}',
                  style: TextStyle(
                    color: stats['avgProfitPerGame'] >= 0
                        ? Colors.green[300]
                        : Colors.red[300],
                  ),
                )),
                DataCell(Text('\$${stats['biggestWin'].toStringAsFixed(0)}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateDetailedPlayerStats() {
    final Map<String, Map<String, dynamic>> playerStats = {};

    for (final game in gameProvider.gameHistory) {
      for (final player in game.players) {
        if (!playerStats.containsKey(player.name)) {
          playerStats[player.name] = {
            'name': player.name,
            'gamesPlayed': 0,
            'gamesWon': 0,
            'totalProfit': 0.0,
            'biggestWin': 0.0,
          };
        }

        final profit = game.getPlayerNetAmount(player.id);
        playerStats[player.name]!['gamesPlayed']++;
        playerStats[player.name]!['totalProfit'] += profit;

        if (profit > 0) {
          playerStats[player.name]!['gamesWon']++;
          if (profit > playerStats[player.name]!['biggestWin']) {
            playerStats[player.name]!['biggestWin'] = profit;
          }
        }
      }
    }

    return playerStats.values.map((stats) {
      final winRate = (stats['gamesWon'] / stats['gamesPlayed'] * 100);
      final avgProfitPerGame = stats['totalProfit'] / stats['gamesPlayed'];

      return {
        'name': stats['name'],
        'gamesPlayed': stats['gamesPlayed'],
        'winRate': winRate,
        'totalProfit': stats['totalProfit'],
        'avgProfitPerGame': avgProfitPerGame,
        'biggestWin': stats['biggestWin'],
      };
    }).toList();
  }
}
