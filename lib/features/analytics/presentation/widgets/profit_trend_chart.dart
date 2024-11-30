// lib/features/analytics/presentation/widgets/profit_trend_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'dart:math' as math;

import 'package:poker_tracker/features/game/data/models/player.dart';

class ProfitTrendChart extends StatelessWidget {
  final List<Game> games;

  const ProfitTrendChart({super.key, required this.games});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return _buildEmptyState();
    }

    final trendData = _calculateTrendData();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
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
                      interval: math.max(
                          1,
                          (trendData['timestamps']!.length / 5)
                              .floor()
                              .toDouble()),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= trendData['timestamps']!.length) {
                          return const Text('');
                        }
                        final date = trendData['timestamps']![value.toInt()];
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
                      interval: 500,
                      reservedSize: 45,
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
                maxX: (trendData['timestamps']!.length - 1).toDouble(),
                minY: trendData['minY']! - 100,
                maxY: trendData['maxY']! + 100,
                lineBarsData:
                    trendData['players']!.map<LineChartBarData>((playerData) {
                  return LineChartBarData(
                    spots:
                        List.generate(trendData['timestamps']!.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        playerData['profits'][index],
                      );
                    }),
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
                        final playerData = trendData['players']![spot.barIndex];
                        return LineTooltipItem(
                          '${playerData['name']}\n\$${spot.y.toStringAsFixed(0)}',
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
          _buildLegend(trendData['players']!),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No game data available',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<Map<String, dynamic>> players) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: players.map((player) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getPlayerColor(player['name']),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              player['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _calculateTrendData() {
    if (games.isEmpty) {
      return {
        'players': [],
        'timestamps': [],
        'minY': 0.0,
        'maxY': 0.0,
      };
    }

    final sortedGames = List<Game>.from(games)
      ..sort((a, b) => a.date.compareTo(b.date));

    final players = <String>{};
    for (final game in sortedGames) {
      for (final player in game.players) {
        players.add(player.name);
      }
    }

    final timestamps = sortedGames.map((g) => g.date).toList();
    final playerData = <Map<String, dynamic>>[];
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final playerName in players) {
      final profits = <double>[];
      double cumulativeProfit = 0;

      for (final game in sortedGames) {
        final player = game.players
            .cast<Player?>()
            .firstWhere((p) => p?.name == playerName, orElse: () => null);

        if (player != null) {
          cumulativeProfit += game.getPlayerNetAmount(player.id);
        }

        profits.add(cumulativeProfit);
        minY = math.min(minY, cumulativeProfit);
        maxY = math.max(maxY, cumulativeProfit);
      }

      playerData.add({
        'name': playerName,
        'profits': profits,
      });
    }

    return {
      'players': playerData,
      'timestamps': timestamps,
      'minY': minY,
      'maxY': maxY,
    };
  }

  Color _getPlayerColor(String playerName) {
    final colors = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.purple[400]!,
      Colors.orange[400]!,
      Colors.pink[400]!,
      Colors.cyan[400]!,
      Colors.amber[400]!,
      Colors.teal[400]!,
    ];

    return colors[playerName.hashCode.abs() % colors.length];
  }
}
