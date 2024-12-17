import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/home/presentation/widgets/active_game_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FocusNode _focusNode;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGames();
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _refreshGames();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshGames() async {
    if (!mounted) return;
    await context.read<GameProvider?>()?.refreshGames();
  }

  Future<void> _handleLogout() async {
    try {
      await context.read<AppAuthProvider>().signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: ${e.toString()}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontM,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSizes.paddingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Consumer<GameProvider?>(
            builder: (context, gameProvider, child) {
              if (gameProvider == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                );
              }

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMainContent(gameProvider),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundMedium,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: AppColors.primaryGradient,
            ).createShader(bounds),
            child: const Text(
              'Poker Tracker',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.thumb_up_sharp,
                    color: AppColors.textSecondary),
                onPressed: () => context.go('/credits'),
                tooltip: 'Credits',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                onPressed: _handleLogout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(GameProvider gameProvider) {
    return RefreshIndicator(
      onRefresh: _refreshGames,
      color: AppColors.secondary,
      backgroundColor: AppColors.backgroundMedium,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewStats(gameProvider),
            const SizedBox(height: 16),
            if (gameProvider.activeGames.isNotEmpty) ...[
              _buildActiveGamesList(gameProvider),
              const SizedBox(height: 16),
            ],
            _buildTopPlayers(gameProvider),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats(GameProvider gameProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Games',
            gameProvider.gameHistory.length.toString(),
            const Icon(
              Icons.history,
              color: AppColors.secondary,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Pot',
            '\$${_calculateTotalPot(gameProvider).toStringAsFixed(2)}',
            const Icon(
              Icons.trending_up,
              color: AppColors.primary,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  double _calculateTotalPot(GameProvider gameProvider) {
    double totalPot = 0;
    for (final game in gameProvider.gameHistory) {
      double gameTotal = game.totalPot;
      if (game.cutPercentage > 0) {
        gameTotal = game.totalPot * (1 - game.cutPercentage / 100);
      }
      totalPot += gameTotal;
    }
    return totalPot;
  }

  Widget _buildStatCard(String title, String value, Icon icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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

  Widget _buildActiveGamesList(GameProvider gameProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.primaryGradient,
          ).createShader(bounds),
          child: const Text(
            'Active Games',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.font2XL,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...gameProvider.activeGames
            .map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ActiveGameCard(
                    key: ValueKey(game.id),
                    game: game,
                    onDeleted: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Game deleted successfully',
                            style: TextStyle(
                              fontSize: AppSizes.fontM,
                            ),
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(AppSizes.paddingL),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusM),
                          ),
                        ),
                      );
                    },
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildTopPlayers(GameProvider gameProvider) {
    final playerStats = _calculatePlayerStats(gameProvider);
    final topPlayers = playerStats.entries.toList()
      ..sort((a, b) => b.value.earnings.compareTo(a.value.earnings));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppColors.rankGold,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ...topPlayers.take(3).map((player) => _buildPlayerCard(
              rank: topPlayers.indexOf(player) + 1,
              name: player.key,
              stats: player.value,
            )),
      ],
    );
  }

  Map<String, PlayerStats> _calculatePlayerStats(GameProvider gameProvider) {
    final stats = <String, PlayerStats>{};

    for (var game in gameProvider.gameHistory) {
      for (var player in game.players) {
        final netAmount = game.getPlayerNetAmount(player.id);
        final currentStats = stats[player.name];

        // Calculate wins (positive net amount counts as a win)
        final isWin = netAmount > 0;

        if (currentStats == null) {
          stats[player.name] = PlayerStats(
            earnings: netAmount,
            gamesPlayed: 1,
            winRate: isWin ? 100 : 0,
          );
        } else {
          final newGamesPlayed = currentStats.gamesPlayed + 1;
          final totalWins =
              (currentStats.winRate * currentStats.gamesPlayed / 100) +
                  (isWin ? 1 : 0);

          stats[player.name] = PlayerStats(
            earnings: currentStats.earnings + netAmount,
            gamesPlayed: newGamesPlayed,
            winRate: (totalWins / newGamesPlayed) * 100,
          );
        }
      }
    }

    return stats;
  }

  Widget _buildPlayerCard({
    required int rank,
    required String name,
    required PlayerStats stats,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank Circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRankColor(rank),
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.gamesPlayed} games • ${stats.winRate.toStringAsFixed(0)}% win rate',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Earnings
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${stats.earnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        stats.earnings > 0 ? AppColors.primary : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'lifetime',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.rankGold;
      case 2:
        return AppColors.rankSilver;
      case 3:
        return AppColors.rankBronze;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAdditionalStats(GameProvider gameProvider) {
    final totalPot = _calculateTotalPot(gameProvider);
    final gamesCount = gameProvider.gameHistory.length;
    final averagePot = gamesCount > 0 ? totalPot / gamesCount : 0.0;

    final largestPot = gameProvider.gameHistory.fold<double>(
      0,
      (max, game) => game.totalPot > max ? game.totalPot : max,
    );

    final currentMonthGames = gameProvider.gameHistory
        .where((game) =>
            game.date.month == DateTime.now().month &&
            game.date.year == DateTime.now().year)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Average Pot Size',
            '\$${averagePot.toStringAsFixed(2)}',
            Icons.bar_chart,
          ),
          _buildStatRow(
            'Largest Pot',
            '\$${largestPot.toStringAsFixed(2)}',
            Icons.trending_up,
          ),
          _buildStatRow(
            'Games This Month',
            currentMonthGames.toString(),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/game-setup'),
          borderRadius: BorderRadius.circular(100),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.add,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
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
              _buildNavItem(Icons.home, 'Home', 0,
                  () => setState(() => _currentIndex = 0)),
              _buildNavItem(
                  Icons.group, 'Teams', 1, () => context.go('/teams')),
              _buildNavItem(Icons.bar_chart, 'Game Stats', 2,
                  () => context.go('/analytics')),
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

class PlayerStats {
  final double earnings;
  final int gamesPlayed;
  final double winRate;

  PlayerStats({
    required this.earnings,
    required this.gamesPlayed,
    required this.winRate,
  });
}
