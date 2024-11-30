// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:share_plus/share_plus.dart';

class GameSettlementSummaryScreen extends StatefulWidget {
  final Game game;

  const GameSettlementSummaryScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameSettlementSummaryScreen> createState() =>
      _GameSettlementSummaryScreenState();
}

class _GameSettlementSummaryScreenState
    extends State<GameSettlementSummaryScreen> {
  bool showOriginalPot = false;

  @override
  Widget build(BuildContext context) {
    _verifyCalculations();

    final winners = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) > 0
            : widget.game.getPlayerNetAmount(p.id) > 0)
        .toList()
      ..sort((a, b) => showOriginalPot
          ? widget.game
              .getPlayerOriginalAmount(b.id)
              .compareTo(widget.game.getPlayerOriginalAmount(a.id))
          : widget.game
              .getPlayerNetAmount(b.id)
              .compareTo(widget.game.getPlayerNetAmount(a.id)));

    final breakEven = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) == 0
            : widget.game.getPlayerNetAmount(p.id) == 0)
        .toList();

    final losers = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) < 0
            : widget.game.getPlayerNetAmount(p.id) < 0)
        .toList()
      ..sort((a, b) => showOriginalPot
          ? widget.game
              .getPlayerOriginalAmount(a.id)
              .compareTo(widget.game.getPlayerOriginalAmount(b.id))
          : widget.game
              .getPlayerNetAmount(a.id)
              .compareTo(widget.game.getPlayerNetAmount(b.id)));

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
              if (widget.game.cutPercentage > 0) _buildToggleBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildGameInfoSection(context),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.dp),
                        child: Column(
                          children: [
                            _buildResultsSection(
                                context, winners, breakEven, losers),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.backgroundDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56.dp,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/'),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  iconSize: 24.dp,
                ),
                Expanded(
                  child: Text(
                    'Game Settlement',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16.dp,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _shareSettlementSummary(context),
                  icon: Icon(
                    Icons.share,
                    color: AppColors.textPrimary,
                    size: AppSizes.iconM.dp,
                  ),
                  tooltip: 'Share Settlement Summary',
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 24.dp,
              right: 24.dp,
              bottom: 16.dp,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.game.name,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 28.dp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.dp),
                      Text(
                        '${widget.game.date.day}/${widget.game.date.month}/${widget.game.date.year}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.dp,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 12.dp),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20.dp,
                      ),
                      SizedBox(width: 4.dp),
                      Text(
                        'Balanced',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 14.dp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfoSection(BuildContext context) {
    final displayPot =
        showOriginalPot ? widget.game.totalPot : widget.game.actualPot;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL.dp,
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
      String label, String value, IconData icon, Color color) {
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

  Widget _buildResultsSection(
    BuildContext context,
    List<Player> winners,
    List<Player> breakEven,
    List<Player> losers,
  ) {
    return Column(
      children: [
        if (winners.isNotEmpty) ...[
          _buildWinnersCard(winners),
          SizedBox(height: 16.dp),
        ],
        if (breakEven.isNotEmpty) ...[
          _buildBreakEvenCard(breakEven),
          SizedBox(height: 16.dp),
        ],
        if (losers.isNotEmpty) ...[
          _buildLosersCard(losers),
          SizedBox(height: 16.dp),
        ],
        if (!widget.game.hasUnsettledLoans()) ...[
          _buildPaymentInstructions(winners, losers),
          SizedBox(height: 16.dp),
        ] else
          _buildUnsettledLoansWarning(),
        _buildReturnButton(context),
        SizedBox(height: 32.dp),
      ],
    );
  }

  Widget _buildWinnersCard(List<Player> winners) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF34D399).withOpacity(0.2),
                ),
              ),
            ),
            padding: EdgeInsets.all(16.dp),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: const Color(0xFF34D399),
                  size: 20.dp,
                ),
                SizedBox(width: 8.dp),
                Text(
                  'Winners',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.dp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: Column(
              children: winners
                  .map((player) => _buildPlayerRow(
                        player,
                        isWinner: true,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenCard(List<Player> breakEven) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade600.withOpacity(0.2),
                ),
              ),
            ),
            padding: EdgeInsets.all(16.dp),
            child: Row(
              children: [
                Icon(
                  Icons.remove,
                  color: Colors.grey.shade400,
                  size: 20.dp,
                ),
                SizedBox(width: 8.dp),
                Text(
                  'Break Even',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.dp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: Column(
              children: breakEven
                  .map((player) => _buildPlayerRow(
                        player,
                        isWinner: null,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLosersCard(List<Player> losers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.red.shade400.withOpacity(0.2),
                ),
              ),
            ),
            padding: EdgeInsets.all(16.dp),
            child: Row(
              children: [
                Icon(
                  Icons.trending_down,
                  color: Colors.red.shade400,
                  size: 20.dp,
                ),
                SizedBox(width: 8.dp),
                Text(
                  'Losers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.dp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: Column(
              children: losers
                  .map((player) => _buildPlayerRow(
                        player,
                        isWinner: false,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Player player, {required bool? isWinner}) {
    final amount = showOriginalPot
        ? widget.game.getPlayerOriginalAmount(player.id)
        : widget.game.getPlayerNetAmount(player.id);
    final totalBuyIn = player.buyIns * widget.game.buyInAmount;

    return Container(
      decoration: BoxDecoration(
        color: isWinner == null
            ? Colors.grey.shade700.withOpacity(0.1)
            : (isWinner ? const Color(0xFF34D399) : Colors.red.shade400)
                .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16.dp),
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
                    color: Colors.white,
                    fontSize: 16.dp,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Buy-in: \$${totalBuyIn.toStringAsFixed(2)} • Cash-out: \$${(player.cashOut ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.dp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.game.cutPercentage > 0 &&
                    !showOriginalPot &&
                    amount != 0)
                  Text(
                    'Original: ${_formatAmount(widget.game.getPlayerOriginalAmount(player.id))}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14.dp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 16.dp),
          Text(
            isWinner == null
                ? '\$0.00'
                : '${isWinner ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isWinner == null
                  ? Colors.grey.shade400
                  : (isWinner ? const Color(0xFF34D399) : Colors.red.shade400),
              fontSize: 20.dp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions(List<Player> winners, List<Player> losers) {
    final payments = _calculatePayments(winners, losers);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.all(16.dp),
            child: Text(
              'Payment Instructions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.dp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (payments.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.dp),
              child: const Text(
                'No payments needed',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            _buildPaymentsList(payments),
          if (!widget.game.isPotBalanced) _buildUnbalancedWarning(),
        ],
      ),
    );
  }

  String _formatPlayerName(String fullName) {
    final nameParts = fullName.trim().split(' ');
    if (nameParts.length == 1) return nameParts[0];

    final firstName = nameParts[0];
    final secondPart = nameParts[1];
    return '$firstName ${secondPart.length > 3 ? secondPart.substring(0, 3) : secondPart}';
  }

  Widget _buildPaymentsList(List<Map<String, dynamic>> payments) {
    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: Column(
        children: payments.map((payment) {
          final from = payment['from'] as Player;
          final to = payment['to'] as Player;
          final amount = payment['amount'] as double;

          final fromName = _formatPlayerName(from.name);
          final toName = _formatPlayerName(to.name);

          return Container(
            margin: EdgeInsets.only(bottom: 8.dp),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(16.dp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          fromName,
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 16.dp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.dp),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                          size: 16.dp,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          toName,
                          style: TextStyle(
                            color: const Color(0xFF34D399),
                            fontSize: 16.dp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.dp),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnsettledLoansWarning() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.dp),
      padding: EdgeInsets.all(16.dp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.3),
            Colors.orange.withOpacity(0.2),
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24.dp,
          ),
          SizedBox(width: 12.dp),
          Expanded(
            child: Text(
              'Some players have unsettled loans. Please settle all loans before proceeding with final settlements.',
              style: TextStyle(
                color: Colors.orange.shade300,
                fontSize: 14.dp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnbalancedWarning() {
    return Container(
      margin: EdgeInsets.all(16.dp),
      padding: EdgeInsets.all(12.dp),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20.dp,
            color: Colors.orange,
          ),
          SizedBox(width: 8.dp),
          Expanded(
            child: Text(
              'The pot is not balanced. Please verify all cash-outs and settlements.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14.dp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56.dp,
      margin: EdgeInsets.symmetric(vertical: 16.dp),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () => context.go('/'),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Return to Home',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.dp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '\$0.00';
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix\$${amount.abs().toStringAsFixed(2)}';
  }

  List<Map<String, dynamic>> _calculatePayments(
      List<Player> winners, List<Player> losers) {
    final payments = <Map<String, dynamic>>[];
    const double minimumPayment = 0.01;

    final remainingLosses = losers.map((loser) {
      final netAmount = showOriginalPot
          ? widget.game.getPlayerOriginalAmount(loser.id)
          : widget.game.getPlayerNetAmount(loser.id);
      return MapEntry(loser, netAmount.abs());
    }).toList();

    final remainingWins = winners.map((winner) {
      final netAmount = showOriginalPot
          ? widget.game.getPlayerOriginalAmount(winner.id)
          : widget.game.getPlayerNetAmount(winner.id);
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

  void _verifyCalculations() {
    final totalWinnings = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) > 0
            : widget.game.getPlayerNetAmount(p.id) > 0)
        .map((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id)
            : widget.game.getPlayerNetAmount(p.id))
        .fold(0.0, (sum, amount) => sum + amount);

    final totalLosses = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) < 0
            : widget.game.getPlayerNetAmount(p.id) < 0)
        .map((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id).abs()
            : widget.game.getPlayerNetAmount(p.id).abs())
        .fold(0.0, (sum, amount) => sum + amount);

    print('\nVerification:');
    print('Total Winnings: ${totalWinnings.toStringAsFixed(2)}');
    print('Total Losses: ${totalLosses.toStringAsFixed(2)}');
    print(
        'Difference: ${(totalWinnings - totalLosses).abs().toStringAsFixed(2)}');
  }

  Future<void> _shareSettlementSummary(BuildContext context) async {
    final StringBuffer summary = StringBuffer();

    // Game Header
    summary.writeln('🎲 ${widget.game.name} - Final Settlement');
    summary
        .writeln('📅 ${DateFormat('MMM dd, yyyy').format(widget.game.date)}');
    summary.writeln('');

    // Game Statistics
    summary.writeln('📊 Game Statistics:');
    if (widget.game.cutPercentage > 0) {
      summary.writeln(
          '• Original Pot: \$${widget.game.totalPot.toStringAsFixed(2)}');
      summary.writeln('• Cut Percentage: ${widget.game.cutPercentage}%');
      summary.writeln(
          '• Cut Amount: \$${widget.game.cutAmount.toStringAsFixed(2)}');
      summary.writeln(
          '• Final Pot: \$${widget.game.actualPot.toStringAsFixed(2)}');
    } else {
      summary
          .writeln('• Total Pot: \$${widget.game.totalPot.toStringAsFixed(2)}');
    }
    summary.writeln('• Players: ${widget.game.players.length}');
    summary.writeln('• Buy-in: \$${widget.game.buyInAmount}');
    summary.writeln('');

    // Winners Section
    final winners = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) > 0
            : widget.game.getPlayerNetAmount(p.id) > 0)
        .toList()
      ..sort((a, b) => showOriginalPot
          ? widget.game
              .getPlayerOriginalAmount(b.id)
              .compareTo(widget.game.getPlayerOriginalAmount(a.id))
          : widget.game
              .getPlayerNetAmount(b.id)
              .compareTo(widget.game.getPlayerNetAmount(a.id)));

    if (winners.isNotEmpty) {
      summary.writeln('🏆 Winners:');
      for (var player in winners) {
        final netAmount = showOriginalPot
            ? widget.game.getPlayerOriginalAmount(player.id)
            : widget.game.getPlayerNetAmount(player.id);
        final originalAmount = widget.game.getPlayerOriginalAmount(player.id);
        final totalBuyIn = player.buyIns * widget.game.buyInAmount;
        final cashOut = player.cashOut ?? 0.0;

        summary.writeln('• ${player.name}: +\$${netAmount.toStringAsFixed(2)}');
        if (widget.game.cutPercentage > 0 && !showOriginalPot) {
          summary.writeln(
              '  Original Amount: +\$${originalAmount.toStringAsFixed(2)}');
        }
        summary.writeln(
            '  In: \$${totalBuyIn.toStringAsFixed(2)} | Out: \$${cashOut.toStringAsFixed(2)}');
      }
      summary.writeln('');
    }

    // Break Even Section
    final breakEven = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) == 0
            : widget.game.getPlayerNetAmount(p.id) == 0)
        .toList();

    if (breakEven.isNotEmpty) {
      summary.writeln('🤝 Break Even:');
      for (var player in breakEven) {
        final totalBuyIn = player.buyIns * widget.game.buyInAmount;
        final cashOut = player.cashOut ?? 0.0;
        summary.writeln('• ${player.name}');
        summary.writeln(
            '  In: \$${totalBuyIn.toStringAsFixed(2)} | Out: \$${cashOut.toStringAsFixed(2)}');
      }
      summary.writeln('');
    }

    // Losers Section
    final losers = widget.game.players
        .where((p) => showOriginalPot
            ? widget.game.getPlayerOriginalAmount(p.id) < 0
            : widget.game.getPlayerNetAmount(p.id) < 0)
        .toList()
      ..sort((a, b) => showOriginalPot
          ? widget.game
              .getPlayerOriginalAmount(a.id)
              .compareTo(widget.game.getPlayerOriginalAmount(b.id))
          : widget.game
              .getPlayerNetAmount(a.id)
              .compareTo(widget.game.getPlayerNetAmount(b.id)));

    if (losers.isNotEmpty) {
      summary.writeln('📉 Losers:');
      for (var player in losers) {
        final netAmount = showOriginalPot
            ? widget.game.getPlayerOriginalAmount(player.id)
            : widget.game.getPlayerNetAmount(player.id);
        final originalAmount = widget.game.getPlayerOriginalAmount(player.id);
        final totalBuyIn = player.buyIns * widget.game.buyInAmount;
        final cashOut = player.cashOut ?? 0.0;

        summary.writeln('• ${player.name}: \$${netAmount.toStringAsFixed(2)}');
        if (widget.game.cutPercentage > 0 && !showOriginalPot) {
          summary.writeln(
              '  Original Amount: \$${originalAmount.toStringAsFixed(2)}');
        }
        summary.writeln(
            '  In: \$${totalBuyIn.toStringAsFixed(2)} | Out: \$${cashOut.toStringAsFixed(2)}');
      }
      summary.writeln('');
    }

    // Payment Instructions
    if (widget.game.isPotBalanced && !widget.game.hasUnsettledLoans()) {
      final payments = _calculatePayments(winners, losers);
      if (payments.isNotEmpty) {
        summary.writeln('💸 Payment Instructions:');
        for (var payment in payments) {
          final from = payment['from'] as Player;
          final to = payment['to'] as Player;
          final amount = payment['amount'] as double;
          summary.writeln(
              '• ${from.name} ➡️ ${to.name}: \$${amount.toStringAsFixed(2)}');
        }
        summary.writeln('');
      }
    }

    // Add app branding
    summary.writeln('Generated by Poker Tracker 🎲');

    try {
      await Share.share(
        summary.toString(),
        subject: '${widget.game.name} - Final Settlement',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.textPrimary,
                  size: AppSizes.iconM.dp,
                ),
                SizedBox(width: AppSizes.spacingS.dp),
                Expanded(
                  child: Text(
                    'Failed to share settlement summary: ${e.toString()}',
                    style: TextStyle(fontSize: AppSizes.fontM.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(AppSizes.paddingL.dp),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
            ),
          ),
        );
      }
    }
  }
}
