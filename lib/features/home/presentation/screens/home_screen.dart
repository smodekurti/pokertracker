import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/home/presentation/widgets/active_game_card.dart';
import 'dart:ui';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FocusNode _focusNode;

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
      await context.read<AuthProvider>().signOut();
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.backgroundGradient,
            ),
          ),
          child: SafeArea(
            child: Consumer<GameProvider?>(
              builder: (context, gameProvider, child) {
                if (gameProvider == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: _buildMainContent(gameProvider),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: AppColors.primaryGradient,
                ).createShader(bounds),
                child: const Text(
                  'Poker Tracker',
                  style: TextStyle(
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.analytics,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconM,
                ),
                onPressed: () => context.go('/analytics'),
                tooltip: 'Player Analytics',
              ),
              IconButton(
                icon: const Icon(
                  Icons.history,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconM,
                ),
                onPressed: () => context.go('/history'),
                tooltip: 'Game History',
              ),
              IconButton(
                icon: const Icon(
                  Icons.help,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconM,
                ),
                onPressed: () => context.go('/poker-reference'),
                tooltip: 'Poker Reference',
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconM,
                ),
                onPressed: _handleLogout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(GameProvider gameProvider) {
    return RefreshIndicator(
      onRefresh: _refreshGames,
      color: AppColors.secondary,
      backgroundColor: Colors.grey[900],
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: gameProvider.activeGames.isEmpty
                ? _buildEnhancedStats(gameProvider)
                : _buildRegularStats(gameProvider),
          ),
          if (gameProvider.activeGames.isNotEmpty) ...[
            _buildActiveGamesHeader(),
            _buildActiveGamesList(gameProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildRegularStats(GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[850]!,
              Colors.grey[900]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Active Games',
                gameProvider.activeGames.length.toString(),
                Icons.casino,
                AppColors.primaryGradient,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[700],
            ),
            Expanded(
              child: _buildStatItem(
                'Total Games',
                gameProvider.gameHistory.length.toString(),
                Icons.history,
                [Colors.purple[400]!, Colors.purple[600]!],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colors[0].withOpacity(0.2),
                colors[1].withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: colors[0],
            size: AppSizes.iconL,
          ),
        ),
        const SizedBox(height: AppSizes.spacingS),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontL,
          ),
        ),
        const SizedBox(height: AppSizes.spacingXS),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font2XL,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveGamesHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingS,
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.primaryGradient,
          ).createShader(bounds),
          child: const Text(
            'Active Games',
            style: TextStyle(
              fontSize: AppSizes.font2XL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveGamesList(GameProvider gameProvider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = gameProvider.activeGames[index];
            return ActiveGameCard(
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
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                  ),
                );
              },
            );
          },
          childCount: gameProvider.activeGames.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.padding2XL),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue[900]!.withOpacity(0.2),
                  Colors.blue[700]!.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.casino,
              size: AppSizes.iconXL,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: AppSizes.spacingXL),
          const Text(
            'No Active Games',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          const Text(
            'Start a new game to begin tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<GameProvider?>(
      builder: (context, gameProvider, child) {
        if (gameProvider == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/game-setup'),
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: AppColors.textPrimary,
                      size: AppSizes.iconM,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Text(
                      'New Game',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontM,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStats(GameProvider gameProvider) {
    final totalPot = gameProvider.gameHistory.fold<double>(
      0,
      (sum, game) => sum + game.totalPot,
    );

    // Calculate player statistics
    final playerStats = <String, double>{};
    for (var game in gameProvider.gameHistory) {
      for (var player in game.players) {
        final netAmount = game.getPlayerNetAmount(player.id);
        playerStats[player.name] = (playerStats[player.name] ?? 0) + netAmount;
      }
    }

    final topPlayers = playerStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate largest pot
    final largestPot = gameProvider.gameHistory.fold<double>(
      0,
      (max, game) => game.totalPot > max ? game.totalPot : max,
    );

    // Calculate current month's games
    final currentMonthGames = gameProvider.gameHistory
        .where((game) =>
            game.date.month == DateTime.now().month &&
            game.date.year == DateTime.now().year)
        .length;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        children: [
          // Primary Stats Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSizes.paddingXL),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Games',
                        gameProvider.gameHistory.length.toString(),
                        Icons.history,
                        [Colors.purple[400]!, Colors.purple[600]!],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[700],
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Total Pot Size',
                        '\$${totalPot.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        AppColors.primaryGradient,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top Players Card
          if (topPlayers.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacingL),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                color: Colors.grey[850],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.emoji_events,
                            size: AppSizes.iconL,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingM),
                        const Text(
                          'Top Players',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppSizes.fontXL,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...topPlayers.take(3).map((player) => _buildPlayerStatsRow(
                        player.key,
                        player.value,
                        topPlayers.indexOf(player) + 1,
                      )),
                ],
              ),
            ),
          ],

          // Additional Stats
          const SizedBox(height: AppSizes.spacingL),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              color: Colors.grey[850],
            ),
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Column(
              children: [
                if (totalPot > 0)
                  _buildDetailRow(
                    'Average Pot Size',
                    '\$${(totalPot / gameProvider.gameHistory.length).toStringAsFixed(2)}',
                    Icons.casino,
                  ),
                _buildDetailRow(
                  'Largest Pot',
                  '\$${largestPot.toStringAsFixed(2)}',
                  Icons.trending_up,
                ),
                _buildDetailRow(
                  'Games This Month',
                  currentMonthGames.toString(),
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsRow(String playerName, double earnings, int rank) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
        vertical: AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[rank - 1].withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: colors[rank - 1],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Text(
              playerName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontL,
              ),
            ),
          ),
          Text(
            '\$${earnings.toStringAsFixed(2)}',
            style: TextStyle(
              color: earnings >= 0 ? AppColors.success : AppColors.error,
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.iconM,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.spacingM),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
