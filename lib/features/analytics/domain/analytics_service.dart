// lib/features/analytics/domain/analytics_service.dart

import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';

class AnalyticsService {
  final List<Game> games;

  AnalyticsService(this.games);

  Map<String, List<Map<String, dynamic>>> getTimeBasedStats() {
    final hourlyStats = List.generate(
        24,
        (hour) => {
              'hour': hour,
              'gamesPlayed': 0.0,
              'totalProfit': 0.0,
              'avgPlayersPerGame': 0.0,
              'totalPlayers': 0.0, // Added for average calculation
            });

    final weekdayStats = List.generate(
        7,
        (day) => {
              'day': day,
              'gamesPlayed': 0.0,
              'totalProfit': 0.0,
              'avgPlayersPerGame': 0.0,
              'totalPlayers': 0.0, // Added for average calculation
            });

    for (final game in games) {
      final hour = game.date.hour;
      final weekday = game.date.weekday - 1;

      // Update hourly stats
      hourlyStats[hour]['gamesPlayed'] =
          (hourlyStats[hour]['gamesPlayed'] as double) + 1;
      hourlyStats[hour]['totalProfit'] =
          (hourlyStats[hour]['totalProfit'] as double) + game.totalPot;
      hourlyStats[hour]['totalPlayers'] =
          (hourlyStats[hour]['totalPlayers'] as double) + game.players.length;

      // Calculate average players per game for hourly stats
      hourlyStats[hour]['avgPlayersPerGame'] =
          (hourlyStats[hour]['totalPlayers'] as double) /
              (hourlyStats[hour]['gamesPlayed'] as double);

      // Update weekly stats
      weekdayStats[weekday]['gamesPlayed'] =
          (weekdayStats[weekday]['gamesPlayed'] as double) + 1;
      weekdayStats[weekday]['totalProfit'] =
          (weekdayStats[weekday]['totalProfit'] as double) + game.totalPot;
      weekdayStats[weekday]['totalPlayers'] =
          (weekdayStats[weekday]['totalPlayers'] as double) +
              game.players.length;

      // Calculate average players per game for weekly stats
      weekdayStats[weekday]['avgPlayersPerGame'] =
          (weekdayStats[weekday]['totalPlayers'] as double) /
              (weekdayStats[weekday]['gamesPlayed'] as double);
    }

    // Clean up by removing the temporary totalPlayers field
    for (var stats in [...hourlyStats, ...weekdayStats]) {
      stats.remove('totalPlayers');
    }

    return {
      'hourly': hourlyStats,
      'weekly': weekdayStats,
    };
  }

  // Rest of the methods remain the same...
  Map<String, dynamic> getOverallStats() {
    double totalPot = 0;
    double maxPot = 0;
    double avgBuyIn = 0;
    int totalPlayers = 0;
    final uniquePlayers = <String>{};

    for (final game in games) {
      totalPot += game.totalPot;
      maxPot = maxPot < game.totalPot ? game.totalPot : maxPot;
      avgBuyIn += game.buyInAmount;
      uniquePlayers.addAll(game.players.map((p) => p.name));
      totalPlayers += game.players.length;
    }

    return {
      'totalGames': games.length,
      'totalPot': totalPot,
      'maxPot': maxPot,
      'avgBuyIn': games.isEmpty ? 0 : avgBuyIn / games.length,
      'uniquePlayers': uniquePlayers.length,
      'avgPlayersPerGame': games.isEmpty ? 0 : totalPlayers / games.length,
    };
  }

  List<Map<String, dynamic>> getPlayerPerformanceMetrics() {
    final playerStats = <String, Map<String, dynamic>>{};

    for (final game in games) {
      for (final player in game.players) {
        if (!playerStats.containsKey(player.name)) {
          playerStats[player.name] = {
            'name': player.name,
            'gamesPlayed': 0.0,
            'totalProfit': 0.0,
            'totalBuyIns': 0.0,
            'wins': 0.0,
            'biggestWin': 0.0,
            'biggestLoss': 0.0,
            'totalLoans': 0.0,
          };
        }

        final stats = playerStats[player.name]!;
        stats['gamesPlayed'] = (stats['gamesPlayed'] as double) + 1;
        stats['totalBuyIns'] = (stats['totalBuyIns'] as double) + player.buyIns;
        stats['totalLoans'] = (stats['totalLoans'] as double) + player.loans;

        final profit = game.getPlayerNetAmount(player.id);
        stats['totalProfit'] = (stats['totalProfit'] as double) + profit;

        if (profit > 0) {
          stats['wins'] = (stats['wins'] as double) + 1;
          if (profit > (stats['biggestWin'] as double)) {
            stats['biggestWin'] = profit;
          }
        } else if (profit < (stats['biggestLoss'] as double)) {
          stats['biggestLoss'] = profit;
        }
      }
    }

    // Calculate derived metrics
    return playerStats.values.map((stats) {
      final gamesPlayed = stats['gamesPlayed'] as double;
      final winRate = gamesPlayed > 0
          ? ((stats['wins'] as double) / gamesPlayed * 100)
          : 0.0;
      final avgProfitPerGame = gamesPlayed > 0
          ? ((stats['totalProfit'] as double) / gamesPlayed)
          : 0.0;

      return {
        ...stats,
        'winRate': winRate,
        'avgProfitPerGame': avgProfitPerGame,
        'roi': _calculateROI(
            stats['totalProfit'] as double, stats['totalBuyIns'] as double),
      };
    }).toList();
  }

  double _calculateROI(double profit, double investment) {
    if (investment == 0) return 0;
    return (profit / investment) * 100;
  }
}
