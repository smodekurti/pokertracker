import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

class GameHistoryScreen extends StatelessWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Column(
            children: [
              SizedBox(
                height: 56.dp,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 24.dp,
                      ),
                    ),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ).createShader(bounds),
                        child: Text(
                          'Game History',
                          style: TextStyle(
                            fontSize: AppSizes.font2XL.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final games = gameProvider.gameHistory;

        if (games.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSizes.paddingL.dp),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppSizes.paddingM.dp),
              child: GameHistoryExpandableCard(game: game),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino_outlined,
            size: AppSizes.iconXL.dp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSizes.spacingL.dp),
          Text(
            'No completed games yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontXL.sp,
            ),
          ),
          SizedBox(height: AppSizes.spacingS.dp),
          Text(
            'Start a new game to see your history here',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          SizedBox(height: AppSizes.spacing2XL.dp),
          ElevatedButton(
            onPressed: () => context.go('/game-setup'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.padding2XL.dp,
                vertical: AppSizes.paddingM.dp,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              ),
            ),
            child: Text(
              'Start New Game',
              style: TextStyle(
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameHistoryExpandableCard extends StatefulWidget {
  final Game game;

  const GameHistoryExpandableCard({
    super.key,
    required this.game,
  });

  @override
  State<GameHistoryExpandableCard> createState() =>
      _GameHistoryExpandableCardState();
}

class _GameHistoryExpandableCardState extends State<GameHistoryExpandableCard> {
  bool isExpanded = false;
  bool showOriginalPot = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
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
            blurRadius: 8.dp,
            offset: Offset(0, 2.dp),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Padding(
              padding: EdgeInsets.all(16.dp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: AppColors.primaryGradient,
                              ).createShader(bounds),
                              child: Text(
                                widget.game.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSizes.font2XL.sp,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.dp),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(widget.game.date),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppSizes.fontM.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.share,
                          color: AppColors.textPrimary,
                          size: AppSizes.iconM.dp,
                        ),
                        onPressed: () => _shareGameSummary(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.dp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        !isExpanded
                            ? 'Total Pot:'
                            : (showOriginalPot
                                ? 'Original Pot:'
                                : 'Final Pot:'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.fontM.sp,
                        ),
                      ),
                      Text(
                        '\$${_getDisplayPot().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: AppSizes.fontL.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (widget.game.cutPercentage > 0 && !isExpanded)
                    Text(
                      'Cut: ${widget.game.cutPercentage}%',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: AppSizes.fontS.sp,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Toggle bar - only shown when expanded and has cut percentage
          if (isExpanded && widget.game.cutPercentage > 0)
            Container(
              color: Colors.black.withOpacity(0.3),
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS.dp,
                vertical: AppSizes.paddingXS.dp,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleChip(
                    icon: Icons.account_balance_wallet,
                    label: 'Original',
                    isSelected: showOriginalPot,
                    onTap: () => setState(() => showOriginalPot = true),
                  ),
                  SizedBox(width: 8.dp),
                  _buildToggleChip(
                    icon: Icons.percent,
                    label: 'After Cut',
                    isSelected: !showOriginalPot,
                    onTap: () => setState(() => showOriginalPot = false),
                  ),
                ],
              ),
            ),
          // Expanded content
          if (isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.dp,
          vertical: 6.dp,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6.dp),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.dp,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: 4.dp),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12.dp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculatePayments(
      List<Player> winners, List<Player> losers) {
    final payments = <Map<String, dynamic>>[];
    const double minimumPayment = 0.01;

    final remainingLosses = losers.map((loser) {
      final netAmount = _getPlayerAmount(loser);
      return MapEntry(loser, netAmount.abs());
    }).toList();

    final remainingWins = winners.map((winner) {
      final netAmount = _getPlayerAmount(winner);
      return MapEntry(winner, netAmount);
    }).toList();

    remainingLosses.sort((a, b) => b.value.compareTo(a.value));
    remainingWins.sort((a, b) => b.value.compareTo(a.value));

    while (remainingLosses.isNotEmpty && remainingWins.isNotEmpty) {
      final currentLoser = remainingLosses.first;
      final currentWinner = remainingWins.first;

      final paymentAmount = math.min(
        currentLoser.value,
        currentWinner.value,
      );

      if (paymentAmount > minimumPayment) {
        payments.add({
          'from': currentLoser.key,
          'to': currentWinner.key,
          'amount': double.parse(paymentAmount.toStringAsFixed(2)),
        });

        final remainingLoss = currentLoser.value - paymentAmount;
        final remainingWin = currentWinner.value - paymentAmount;

        if (remainingLoss <= minimumPayment) {
          remainingLosses.removeAt(0);
        } else {
          remainingLosses[0] = MapEntry(
              currentLoser.key, double.parse(remainingLoss.toStringAsFixed(2)));
        }

        if (remainingWin <= minimumPayment) {
          remainingWins.removeAt(0);
        } else {
          remainingWins[0] = MapEntry(
              currentWinner.key, double.parse(remainingWin.toStringAsFixed(2)));
        }
      } else {
        if (currentLoser.value <= minimumPayment) remainingLosses.removeAt(0);
        if (currentWinner.value <= minimumPayment) remainingWins.removeAt(0);
      }
    }

    return payments;
  }

  Widget _buildPaymentInstructions(List<Player> winners, List<Player> losers) {
    final payments = _calculatePayments(winners, losers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Instructions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.dp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.dp),
        if (payments.isEmpty)
          Text(
            'No payments needed',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontM.sp,
            ),
          )
        else
          Column(
            children: payments.map((payment) {
              final from = payment['from'] as Player;
              final to = payment['to'] as Player;
              final amount = payment['amount'] as double;

              return Container(
                margin: EdgeInsets.only(bottom: 8.dp),
                padding: EdgeInsets.all(12.dp),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.dp),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            _formatPlayerName(from.name),
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: AppSizes.fontM.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingM.dp,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: AppColors.textSecondary,
                              size: AppSizes.iconS.dp,
                            ),
                          ),
                          Text(
                            _formatPlayerName(to.name),
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: AppSizes.fontM.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSizes.spacingM.dp),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontM.sp,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _formatPlayerName(String fullName) {
    final nameParts = fullName.trim().split(' ');
    if (nameParts.length == 1) return nameParts[0];

    final firstName = nameParts[0];
    final secondPart = nameParts[1];
    return '$firstName ${secondPart.length > 3 ? secondPart.substring(0, 3) : secondPart}';
  }

  Widget _buildExpandedContent() {
    final winners = widget.game.players
        .where((p) => _getPlayerAmount(p) > 0)
        .toList()
      ..sort((a, b) => _getPlayerAmount(b).compareTo(_getPlayerAmount(a)));

    final breakEven = widget.game.players
        .where((p) => _getPlayerAmount(p).abs() < 0.01)
        .toList();

    final losers = widget.game.players
        .where((p) => _getPlayerAmount(p) < 0)
        .toList()
      ..sort((a, b) => _getPlayerAmount(a).compareTo(_getPlayerAmount(b)));

    return Column(
      children: [
        _buildGameDetails(), // Move game details to the top
        Padding(
          padding: EdgeInsets.all(16.dp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (winners.isNotEmpty) ...[
                _buildPlayerSection(
                  title: 'Winners',
                  icon: Icons.trending_up,
                  iconColor: AppColors.success,
                  players: winners,
                  isWinners: true,
                ),
                SizedBox(height: 16.dp),
              ],
              if (breakEven.isNotEmpty) ...[
                _buildPlayerSection(
                  title: 'Break Even',
                  icon: Icons.remove,
                  iconColor: Colors.grey,
                  players: breakEven,
                ),
                SizedBox(height: 16.dp),
              ],
              if (losers.isNotEmpty) ...[
                _buildPlayerSection(
                  title: 'Losers',
                  icon: Icons.trending_down,
                  iconColor: AppColors.error,
                  players: losers,
                  isWinners: false,
                ),
                SizedBox(height: 16.dp),
              ],
              if (widget.game.isPotBalanced &&
                  !widget.game.hasUnsettledLoans()) ...[
                _buildPaymentInstructions(winners, losers),
                SizedBox(height: 16.dp),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Player> players,
    bool? isWinners,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20.dp),
            SizedBox(width: 8.dp),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.dp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.dp),
        ...players
            .map((player) => _buildPlayerRow(player, isWinners: isWinners)),
      ],
    );
  }

  Widget _buildPlayerRow(Player player, {bool? isWinners}) {
    final amount = _getPlayerAmount(player);
    final originalAmount = widget.game.getPlayerOriginalAmount(player.id);
    final totalBuyIn = player.calculateTotalIn(widget.game.buyInAmount);

    return Container(
      margin: EdgeInsets.only(bottom: 8.dp),
      padding: EdgeInsets.all(12.dp),
      decoration: BoxDecoration(
        color: _getPlayerRowColor(isWinners),
        borderRadius: BorderRadius.circular(8.dp),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.dp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Buy-in: \$${totalBuyIn.toStringAsFixed(2)} • Cash-out: \$${(player.cashOut ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.dp,
                  ),
                ),
                if (widget.game.cutPercentage > 0 &&
                    !showOriginalPot &&
                    amount != 0)
                  Text(
                    'Original: ${_formatAmount(originalAmount)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.dp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              color: _getAmountColor(isWinners),
              fontSize: 20.dp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameDetails() {
    final displayPot =
        showOriginalPot ? widget.game.totalPot : widget.game.actualPot;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS.dp,
        vertical: AppSizes.paddingS.dp,
      ),
      padding: EdgeInsets.all(AppSizes.paddingL.dp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoColumn(
            'Players',
            '${widget.game.players.length}',
            Icons.group,
            AppColors.info,
          ),
          Container(
            width: 1.dp,
            height: 40.dp,
            color: Colors.grey[700],
          ),
          _buildInfoColumn(
            'Buy-in',
            '\$${widget.game.buyInAmount.toStringAsFixed(2)}',
            Icons.monetization_on,
            AppColors.success,
          ),
          Container(
            width: 1.dp,
            height: 40.dp,
            color: Colors.grey[700],
          ),
          _buildInfoColumn(
            showOriginalPot ? 'Original Pot' : 'Final Pot',
            '\$${displayPot.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.paddingM.dp),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: AppSizes.iconM.dp,
          ),
        ),
        SizedBox(height: AppSizes.spacingS.dp),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontS.sp,
          ),
        ),
        SizedBox(height: AppSizes.spacingXS.dp),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getPlayerRowColor(bool? isWinners) {
    if (isWinners == null) return Colors.grey.shade700.withOpacity(0.1);
    return (isWinners ? AppColors.success : AppColors.error).withOpacity(0.1);
  }

  Color _getAmountColor(bool? isWinners) {
    if (isWinners == null) return Colors.grey.shade400;
    return isWinners ? AppColors.success : AppColors.error;
  }

  String _calculateDuration() {
    if (widget.game.endedAt == null) return 'N/A';

    final duration = widget.game.endedAt!.difference(widget.game.createdAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes} min';
    } else {
      return '$minutes min';
    }
  }

  double _getDisplayPot() {
    if (showOriginalPot) return widget.game.totalPot;
    return widget.game.totalPot * (1 - widget.game.cutPercentage / 100);
  }

  double _getPlayerAmount(Player player) {
    if (showOriginalPot) return widget.game.getPlayerOriginalAmount(player.id);
    return widget.game.getPlayerNetAmount(player.id);
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '\$0.00';
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix\$${amount.abs().toStringAsFixed(2)}';
  }

  Future<void> _shareGameSummary(BuildContext context) async {
    final StringBuffer summary = StringBuffer();

    // Game Header
    summary.writeln('🎲 ${widget.game.name}');
    summary
        .writeln('📅 ${DateFormat('MMM dd, yyyy').format(widget.game.date)}');
    summary.writeln(
        '💰 ${showOriginalPot ? 'Original' : 'Final'} Pot: \$${_getDisplayPot().toStringAsFixed(2)}');
    if (widget.game.cutPercentage > 0) {
      summary.writeln('✂️ Cut: ${widget.game.cutPercentage}%');
    }
    summary.writeln('');

    // Game Details
    summary.writeln('🎮 Game Details:');
    summary.writeln('• Buy-in: \$${widget.game.buyInAmount}');
    summary.writeln('• Players: ${widget.game.players.length}');
    summary.writeln('• Duration: ${_calculateDuration()}');
    summary.writeln(
        '• Average Stack: \$${(_getDisplayPot() / widget.game.players.length).toStringAsFixed(2)}');
    summary.writeln('');

    // Players Sections
    final winners = widget.game.players
        .where((p) => _getPlayerAmount(p) > 0)
        .toList()
      ..sort((a, b) => _getPlayerAmount(b).compareTo(_getPlayerAmount(a)));

    final breakEven = widget.game.players
        .where((p) => _getPlayerAmount(p).abs() < 0.01)
        .toList();

    final losers = widget.game.players
        .where((p) => _getPlayerAmount(p) < 0)
        .toList()
      ..sort((a, b) => _getPlayerAmount(a).compareTo(_getPlayerAmount(b)));

    if (winners.isNotEmpty) {
      summary.writeln('🏆 Winners:');
      for (var player in winners) {
        final amount = _getPlayerAmount(player);
        final originalAmount = widget.game.getPlayerOriginalAmount(player.id);
        summary.writeln('• ${player.name}: ${_formatAmount(amount)}');
        if (widget.game.cutPercentage > 0 && !showOriginalPot) {
          summary.writeln('  Original: ${_formatAmount(originalAmount)}');
        }
      }
      summary.writeln('');
    }

    if (breakEven.isNotEmpty) {
      summary.writeln('🤝 Break Even:');
      for (var player in breakEven) {
        summary.writeln('• ${player.name}: \$0.00');
      }
      summary.writeln('');
    }

    if (losers.isNotEmpty) {
      summary.writeln('📉 Losers:');
      for (var player in losers) {
        final amount = _getPlayerAmount(player);
        final originalAmount = widget.game.getPlayerOriginalAmount(player.id);
        summary.writeln('• ${player.name}: ${_formatAmount(amount)}');
        if (widget.game.cutPercentage > 0 && !showOriginalPot) {
          summary.writeln('  Original: ${_formatAmount(originalAmount)}');
        }
      }
      summary.writeln('');
    }

    // App branding
    summary.writeln('Generated by Poker Tracker 🎲');

    try {
      await Share.share(
        summary.toString(),
        subject: '${widget.game.name} - Game Summary',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share game summary: ${e.toString()}',
              style: TextStyle(fontSize: AppSizes.fontM.sp),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
