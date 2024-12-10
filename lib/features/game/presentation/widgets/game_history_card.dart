import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:share_plus/share_plus.dart';

class GameHistoryCard extends StatefulWidget {
  final Game game;

  const GameHistoryCard({
    super.key,
    required this.game,
  });

  @override
  State<GameHistoryCard> createState() => _GameHistoryCardState();
}

class _GameHistoryCardState extends State<GameHistoryCard> {
  bool isExpanded = false;
  bool showAfterCut = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.dp, horizontal: 16.dp),
      color: AppColors.backgroundMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (!isExpanded) _buildCollapsedHighlights(),
            if (isExpanded) ...[
              _buildGameDetails(),
              _buildToggleButtons(),
              _buildPlayersList(),
              _buildPaymentInstructions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.dp),
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
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontXL.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(widget.game.date),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontM.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textSecondary),
            onPressed: _shareGameSummary,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedHighlights() {
    _getWinner();
    _getWinnerProfit();
    final totalPot = showAfterCut
        ? widget.game.totalPot * (1 - widget.game.cutPercentage / 100)
        : widget.game.totalPot;

    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightRow('Total Pot', '\$${totalPot.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.dp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontM.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameDetails() {
    final totalPot = showAfterCut
        ? widget.game.totalPot * (1 - widget.game.cutPercentage / 100)
        : widget.game.totalPot;

    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                  Icons.group, 'Players', '${widget.game.players.length}'),
              _buildDetailItem(Icons.attach_money, 'Buy-in',
                  '\$${widget.game.buyInAmount.toStringAsFixed(2)}'),
              _buildDetailItem(Icons.account_balance_wallet, 'Final Pot',
                  '\$${totalPot.toStringAsFixed(2)}'),
            ],
          ),
          if (widget.game.cutPercentage > 0) ...[
            SizedBox(height: 8.dp),
            Text(
              'Cut: ${widget.game.cutPercentage}%',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: AppSizes.fontS.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary),
        SizedBox(height: 4.dp),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontS.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontM.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => showAfterCut = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !showAfterCut
                    ? AppColors.primary
                    : AppColors.backgroundMedium,
              ),
              child: const Text('Original'),
            ),
          ),
          SizedBox(width: 8.dp),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => showAfterCut = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: showAfterCut
                    ? AppColors.primary
                    : AppColors.backgroundMedium,
              ),
              child: const Text('After Cut'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlayerCategory(
            'Winners', (p) => _getPlayerAmount(p.id) > 0, AppColors.success),
        _buildPlayerCategory('Break Even', (p) => _getPlayerAmount(p.id) == 0,
            AppColors.textSecondary),
        _buildPlayerCategory(
            'Losers', (p) => _getPlayerAmount(p.id) < 0, AppColors.error),
      ],
    );
  }

  Widget _buildPlayerCategory(
      String title, bool Function(Player) filter, Color color) {
    final categoryPlayers = widget.game.players.where(filter).toList()
      ..sort(
          (a, b) => _getPlayerAmount(b.id).compareTo(_getPlayerAmount(a.id)));

    if (categoryPlayers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 8.dp),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: AppSizes.fontL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...categoryPlayers.map(_buildPlayerResultRow),
      ],
    );
  }

  Widget _buildPlayerResultRow(Player player) {
    final netAmount = _getPlayerAmount(player.id);
    final buyIn = widget.game.buyInAmount;
    final cashOut = buyIn + netAmount;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.dp, horizontal: 16.dp),
      padding: EdgeInsets.all(12.dp),
      decoration: BoxDecoration(
        color: _getPlayerResultColor(netAmount),
        borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
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
                    fontSize: AppSizes.fontM.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Buy-in: \$${buyIn.toStringAsFixed(2)} • Cash-out: \$${cashOut.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontS.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount(netAmount),
            style: TextStyle(
              color: _getAmountColor(netAmount),
              fontSize: AppSizes.fontM.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    List<Map<String, dynamic>> debts = _calculateDebts();

    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: AppColors.textSecondary),
              SizedBox(width: 8.dp),
              Text(
                'Payment Instructions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontL.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.dp),
          if (debts.isEmpty)
            Card(
              color: AppColors.success.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(16.dp),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 8.dp),
                    Text(
                      'No payments necessary. Everyone is square!',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: AppSizes.fontM.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: debts.map((debt) {
                return Card(
                  margin: EdgeInsets.only(bottom: 8.dp),
                  color: AppColors.backgroundMedium,
                  child: Padding(
                    padding: EdgeInsets.all(16.dp),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt['from'],
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: AppSizes.fontM.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'pays',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: AppSizes.fontS.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                debt['to'],
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: AppSizes.fontM.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatAmount(debt['amount']),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: AppSizes.fontL.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateDebts() {
    List<Map<String, dynamic>> debts = [];
    List<Map<String, dynamic>> balances = widget.game.players.map((player) {
      return {
        'name': player.name,
        'balance': _getPlayerAmount(player.id),
      };
    }).toList();

    balances.sort((a, b) => a['balance'].compareTo(b['balance']));

    int i = 0;
    int j = balances.length - 1;

    while (i < j) {
      double debt = min(-balances[i]['balance'], balances[j]['balance']);
      if (debt > 0) {
        debts.add({
          'from': balances[i]['name'],
          'to': balances[j]['name'],
          'amount': debt,
        });

        balances[i]['balance'] += debt;
        balances[j]['balance'] -= debt;

        if (balances[i]['balance'] == 0) i++;
        if (balances[j]['balance'] == 0) j--;
      }
    }

    return debts;
  }

  Color _getPlayerResultColor(double amount) {
    if (amount > 0) return AppColors.success.withOpacity(0.1);
    if (amount < 0) return AppColors.error.withOpacity(0.1);
    return AppColors.backgroundMedium;
  }

  Color _getAmountColor(double amount) {
    if (amount > 0) return AppColors.success;
    if (amount < 0) return AppColors.error;
    return AppColors.textPrimary;
  }

  String _formatAmount(double amount) {
    final prefix = amount > 0 ? '+' : '';
    return '$prefix\$${amount.toStringAsFixed(2)}';
  }

  double _getPlayerAmount(String playerId) {
    return showAfterCut
        ? widget.game.getPlayerAmountAfterCut(playerId)
        : widget.game.getPlayerNetAmount(playerId);
  }

  Player _getWinner() {
    return widget.game.players.reduce(
        (a, b) => _getPlayerAmount(a.id) > _getPlayerAmount(b.id) ? a : b);
  }

  double _getWinnerProfit() {
    Player winner = _getWinner();
    return _getPlayerAmount(winner.id);
  }

  Future<void> _shareGameSummary() async {
    final StringBuffer summary = StringBuffer();

    summary.writeln('🎲 ${widget.game.name}');
    summary
        .writeln('📅 ${DateFormat('EEEE, M/d/yyyy').format(widget.game.date)}');
    summary.writeln('');
    summary.writeln('👥 Players: ${widget.game.players.length}');
    summary
        .writeln('💰 Buy-in: \$${widget.game.buyInAmount.toStringAsFixed(2)}');
    summary
        .writeln('🏆 Final Pot: \$${widget.game.totalPot.toStringAsFixed(2)}');
    summary.writeln('');

    final players = List<Player>.from(widget.game.players)
      ..sort((a, b) => widget.game
          .getPlayerNetAmount(b.id)
          .compareTo(widget.game.getPlayerNetAmount(a.id)));

    for (final player in players) {
      final netAmount = widget.game.getPlayerNetAmount(player.id);
      final buyIn = widget.game.buyInAmount;
      final cashOut = player.cashOut;

      summary.writeln('${player.name}:');
      summary.writeln('  Buy-in: \$${buyIn.toStringAsFixed(2)}');
      summary.writeln('  Cash-out: \$${cashOut!.toStringAsFixed(2)}');
      summary.writeln('  Net: ${_formatAmount(netAmount)}');
      summary.writeln('');
    }

    summary.writeln('Generated by Poker Tracker 🎲');

    try {
      await Share.share(
        summary.toString(),
        subject: '${widget.game.name} - Game Summary',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share game summary: ${e.toString()}',
              style: TextStyle(fontSize: AppSizes.fontM.sp),
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
