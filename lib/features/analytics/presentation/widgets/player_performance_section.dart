import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';

enum SortOption { profit, winRate, gamesPlayed, recentActivity }

class FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class PlayerPerformanceSection extends StatefulWidget {
  final List<Game> games;

  const PlayerPerformanceSection({
    super.key,
    required this.games,
  });

  @override
  State<PlayerPerformanceSection> createState() =>
      _PlayerPerformanceSectionState();
}

class _PlayerPerformanceSectionState extends State<PlayerPerformanceSection> {
  SortOption _currentSort = SortOption.profit;
  String _searchQuery = '';
  bool _showOnlyWinners = false;

  @override
  Widget build(BuildContext context) {
    final playerStats = _getFilteredAndSortedStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Performance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Search Bar
        TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search players...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filter Options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: 'Profit',
                isSelected: _currentSort == SortOption.profit,
                onTap: () => setState(() => _currentSort = SortOption.profit),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: 'Win Rate',
                isSelected: _currentSort == SortOption.winRate,
                onTap: () => setState(() => _currentSort = SortOption.winRate),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: 'Games',
                isSelected: _currentSort == SortOption.gamesPlayed,
                onTap: () =>
                    setState(() => _currentSort = SortOption.gamesPlayed),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: 'Recent',
                isSelected: _currentSort == SortOption.recentActivity,
                onTap: () =>
                    setState(() => _currentSort = SortOption.recentActivity),
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: 'Winners',
                isSelected: _showOnlyWinners,
                onTap: () =>
                    setState(() => _showOnlyWinners = !_showOnlyWinners),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          '${playerStats.length} players',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        if (playerStats.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No players found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: playerStats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildPlayerCard(playerStats[index]),
          ),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with name and profit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                player['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '\$${player['totalProfit'].toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: player['totalProfit'] >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats Grid
          Row(
            children: [
              _buildStatItem(
                Icons.casino,
                'Games',
                player['gamesPlayed'].toString(),
                AppColors.secondary,
              ),
              _buildStatItem(
                Icons.emoji_events,
                'Wins',
                player['wins'].toString(),
                AppColors.rankGold,
              ),
              _buildStatItem(
                Icons.trending_up,
                'Win Rate',
                '${(player['winRate']).toStringAsFixed(0)}%',
                AppColors.primary,
              ),
              _buildStatItem(
                Icons.star,
                'Best Win',
                '\$${player['biggestWin'].toStringAsFixed(0)}',
                AppColors.rankSilver,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Win Rate Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Performance',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${player['winRate'].toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (player['winRate'] as num) / 100,
                  backgroundColor: AppColors.backgroundDark,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredAndSortedStats() {
    final stats = _calculatePlayerStats(widget.games);

    // Apply search filter
    var filteredStats = stats.where((player) {
      return player['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Apply winners filter
    if (_showOnlyWinners) {
      filteredStats = filteredStats.where((player) {
        return player['totalProfit'] > 0;
      }).toList();
    }

    // Apply sorting
    switch (_currentSort) {
      case SortOption.profit:
        filteredStats
            .sort((a, b) => b['totalProfit'].compareTo(a['totalProfit']));
      case SortOption.winRate:
        filteredStats.sort((a, b) => b['winRate'].compareTo(a['winRate']));
      case SortOption.gamesPlayed:
        filteredStats
            .sort((a, b) => b['gamesPlayed'].compareTo(a['gamesPlayed']));
      case SortOption.recentActivity:
        filteredStats
            .sort((a, b) => b['lastPlayed'].compareTo(a['lastPlayed']));
    }

    return filteredStats;
  }

  List<Map<String, dynamic>> _calculatePlayerStats(List<Game> games) {
    final stats = <String, Map<String, dynamic>>{};

    for (final game in games) {
      for (final player in game.players) {
        if (!stats.containsKey(player.name)) {
          stats[player.name] = {
            'name': player.name,
            'gamesPlayed': 0,
            'wins': 0,
            'totalProfit': 0.0,
            'biggestWin': 0.0,
            'lastPlayed': game.date,
          };
        }

        // Update last played date if more recent
        if (game.date.isAfter(stats[player.name]!['lastPlayed'])) {
          stats[player.name]!['lastPlayed'] = game.date;
        }

        final profit = game.getPlayerNetAmount(player.id);
        stats[player.name]!['gamesPlayed']++;
        stats[player.name]!['totalProfit'] += profit;

        if (profit > 0) {
          stats[player.name]!['wins']++;
          if (profit > stats[player.name]!['biggestWin']) {
            stats[player.name]!['biggestWin'] = profit;
          }
        }
      }
    }

    return stats.values.map((stat) {
      final winRate = (stat['wins'] / stat['gamesPlayed'] * 100);
      return {
        ...stat,
        'winRate': winRate,
      };
    }).toList();
  }
}
