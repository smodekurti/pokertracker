import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'dart:math' as math;

class AnalyticsCharts extends StatelessWidget {
  final GameProvider gameProvider;

  const AnalyticsCharts({super.key, required this.gameProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWinRateChart(),
        const SizedBox(height: 24),
        _buildProfitTrendChart(),
      ],
    );
  }

  Widget _buildWinRateChart() {
    final playerStats = _calculatePlayerWinRates();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Win Rates',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey[800]!,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${playerStats[groupIndex]['name']}\n${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            playerStats[value.toInt()]['name'],
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: playerStats.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['winRate'],
                        gradient: _getGradient(entry.value['winRate']),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculatePlayerWinRates() {
    final playerStats = <String, Map<String, dynamic>>{};

    for (final game in gameProvider.gameHistory) {
      for (final player in game.players) {
        if (!playerStats.containsKey(player.name)) {
          playerStats[player.name] = {
            'name': player.name,
            'gamesPlayed': 0,
            'gamesWon': 0,
          };
        }

        playerStats[player.name]!['gamesPlayed'] += 1;
        if (game.getPlayerNetAmount(player.id) > 0) {
          playerStats[player.name]!['gamesWon'] += 1;
        }
      }
    }

    return playerStats.values.map((stats) {
      final winRate = (stats['gamesWon'] / stats['gamesPlayed'] * 100);
      return {
        'name': stats['name'],
        'winRate': winRate,
      };
    }).toList();
  }

  LinearGradient _getGradient(double winRate) {
    if (winRate >= 50) {
      return LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.green[300]!, Colors.green[400]!],
      );
    } else {
      return LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.orange[300]!, Colors.orange[400]!],
      );
    }
  }

  Widget _buildProfitTrendChart() {
    final profitData = _calculateProfitTrends();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profit Trends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval:
                          (profitData['games']!.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= profitData['games']!.length) {
                          return const Text('');
                        }
                        // Format date as MM/DD
                        final date =
                            DateTime.parse(profitData['games']![value.toInt()]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: profitData['maxProfit']! / 5,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (profitData['games']!.length - 1).toDouble(),
                minY: profitData['minProfit']! * 1.1,
                maxY: profitData['maxProfit']! * 1.1,
                lineBarsData: profitData['players']!.map((playerData) {
                  return LineChartBarData(
                    spots: playerData['profits']!.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: _getPlayerColor(playerData['name']),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          _getPlayerColor(playerData['name']).withOpacity(0.1),
                    ),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.grey[800]!,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final playerData =
                            profitData['players']![spot.barIndex];
                        return LineTooltipItem(
                          '${playerData['name']}: \$${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: _getPlayerColor(playerData['name']),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: profitData['players']!.map((playerData) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPlayerColor(playerData['name']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    playerData['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateProfitTrends() {
    // Sort games by date
    final sortedGames = List<Game>.from(gameProvider.gameHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Initialize player data
    final players = <String>{};
    final playerProfits = <String, List<double>>{};
    double maxProfit = double.negativeInfinity;
    double minProfit = double.infinity;

    // Get all unique players
    for (final game in sortedGames) {
      for (final player in game.players) {
        players.add(player.name);
        playerProfits[player.name] ??= List.filled(sortedGames.length, 0);
      }
    }

    // Calculate cumulative profits
    for (final player in players) {
      double cumulativeProfit = 0;
      for (int i = 0; i < sortedGames.length; i++) {
        final game = sortedGames[i];
        final gamePlayer =
            game.players.firstWhereOrNull((p) => p.name == player);

        if (gamePlayer != null) {
          cumulativeProfit += game.getPlayerNetAmount(gamePlayer.id);
        }

        playerProfits[player]![i] = cumulativeProfit;
        maxProfit = math.max(maxProfit, cumulativeProfit);
        minProfit = math.min(minProfit, cumulativeProfit);
      }
    }

    return {
      'games': sortedGames.map((g) => g.date.toIso8601String()).toList(),
      'players': players
          .map((player) => {
                'name': player,
                'profits': playerProfits[player],
              })
          .toList(),
      'maxProfit': maxProfit,
      'minProfit': minProfit,
    };
  }

  Color _getPlayerColor(String playerName) {
    // Generate a consistent color for each player
    final colorOptions = [
      Colors.cyan[400]!,
      Colors.purple[400]!,
      Colors.orange[400]!,
      Colors.green[400]!,
      Colors.pink[400]!,
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.teal[400]!,
    ];

    // Use player name's hash code to consistently assign a color
    final colorIndex = playerName.hashCode.abs() % colorOptions.length;
    return colorOptions[colorIndex];
  }
}
