import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:share_plus/share_plus.dart';

class GameHistoryCard extends StatelessWidget {
  final Game game;

  const GameHistoryCard({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(8),
        //border: Border.all(color: AppColors.rankSilver, width: .5),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: _buildHeader(context),
        children: [
          _buildGameInfo(),
          _buildPlayerList('Winners', Icons.emoji_events, AppColors.success),
          _buildPlayerList('Break Even', Icons.balance, Colors.grey),
          _buildPlayerList('Losers', Icons.trending_down, AppColors.error),
          if (game.isPotBalanced) _buildPaymentInstructions(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                game.name,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.primary),
              onPressed: () => _shareGameSummary(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(game.date),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Final Pot: \$${game.totalPot.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.primary, fontSize: 16),
            ),
          ],
        ),
        if (game.cutPercentage > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.cut, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'After Cut: \$${game.actualPot.toStringAsFixed(2)} (${game.cutPercentage}% cut)',
                  style:
                      const TextStyle(color: AppColors.warning, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
              Icons.group, 'Players', game.players.length.toString()),
          _buildInfoItem(Icons.attach_money, 'Buy-in',
              '\$${game.buyInAmount.toStringAsFixed(2)}'),
          _buildInfoItem(Icons.account_balance_wallet, 'Final Pot',
              '\$${game.actualPot.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPlayerList(String category, IconData icon, Color color) {
    List<Player> players = [];

    switch (category) {
      case 'Winners':
        players = game.players
            .where((p) => game.getPlayerNetAmount(p.id) > 0)
            .toList();
        players.sort((a, b) => game
            .getPlayerNetAmount(b.id)
            .compareTo(game.getPlayerNetAmount(a.id)));
        break;
      case 'Break Even':
        players = game.players
            .where((p) => game.getPlayerNetAmount(p.id) == 0)
            .toList();
        break;
      case 'Losers':
        players = game.players
            .where((p) => game.getPlayerNetAmount(p.id) < 0)
            .toList();
        players.sort((a, b) => game
            .getPlayerNetAmount(a.id)
            .compareTo(game.getPlayerNetAmount(b.id)));
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...players.map((player) => _buildPlayerItem(player, color)),
      ],
    );
  }

  Widget _buildPlayerItem(Player player, Color color) {
    final netAmount = game.getPlayerNetAmount(player.id);
    final originalAmount = game.getPlayerOriginalAmount(player.id);
    final buyIn = player.calculateTotalIn(game.buyInAmount);
    final cashOut = player.cashOut ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(
                    'Buy-in: \$${buyIn.toStringAsFixed(2)} • Cash-out: \$${cashOut.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (game.cutPercentage > 0 && originalAmount != netAmount)
                  Text('Original: ${_formatAmount(originalAmount)}',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 12)),
              ],
            ),
          ),
          Text(
            _formatAmount(netAmount),
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount >= 0
        ? '+\$${amount.toStringAsFixed(2)}'
        : '-\$${amount.abs().toStringAsFixed(2)}';
  }

  Widget _buildPaymentInstructions() {
    final winners =
        game.players.where((p) => game.getPlayerNetAmount(p.id) > 0).toList();
    final losers =
        game.players.where((p) => game.getPlayerNetAmount(p.id) < 0).toList();
    final payments = _calculatePayments(winners, losers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payment, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...payments.map((payment) => _buildPaymentItem(payment)),
      ],
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  _formatName(payment['from'].name),
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                Text(
                  _formatName(payment['to'].name),
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            '\$${payment['amount'].toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatName(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts.first} ${parts.last[0]}.';
    }
    return name;
  }

  List<Map<String, dynamic>> _calculatePayments(
      List<Player> winners, List<Player> losers) {
    final payments = <Map<String, dynamic>>[];
    for (final loser in losers) {
      var amountToPayBack = game.getPlayerNetAmount(loser.id).abs();
      for (final winner in winners) {
        if (amountToPayBack <= 0) break;
        final winnerAmount = game.getPlayerNetAmount(winner.id);
        if (winnerAmount <= 0) continue;
        final paymentAmount =
            amountToPayBack < winnerAmount ? amountToPayBack : winnerAmount;
        payments.add({
          'from': loser,
          'to': winner,
          'amount': paymentAmount,
        });
        amountToPayBack -= paymentAmount;
      }
    }
    return payments;
  }

  // Only showing the modified _shareGameSummary method as other code remains unchanged
  Future<void> _shareGameSummary(BuildContext context) async {
    final summary = StringBuffer();

    // Header
    summary.writeln('🎲 ${game.name.toUpperCase()}');
    summary.writeln('📅 ${DateFormat('MMM dd, yyyy').format(game.date)}');
    summary.writeln('');

    // Game Info
    summary.writeln('Game Details:');
    summary.writeln('👥 Players: ${game.players.length}');
    summary.writeln('💰 Buy-in: \$${game.buyInAmount.toStringAsFixed(2)}');
    summary.writeln('💵 Final Pot: \$${game.totalPot.toStringAsFixed(2)}');
    if (game.cutPercentage > 0) {
      summary.writeln('✂️ House Cut: ${game.cutPercentage}%');
      summary.writeln('🏦 After Cut: \$${game.actualPot.toStringAsFixed(2)}');
    }
    summary.writeln('');

    // Winners
    final winners =
        game.players.where((p) => game.getPlayerNetAmount(p.id) > 0).toList();
    if (winners.isNotEmpty) {
      summary.writeln('🏆 Winners:');
      for (final player in winners) {
        final netAmount = game.getPlayerNetAmount(player.id);
        final originalAmount = game.getPlayerOriginalAmount(player.id);
        final buyIn = player.calculateTotalIn(game.buyInAmount);
        final cashOut = player.cashOut ?? 0;

        summary.writeln('${player.name}');
        summary.writeln(
            '   Buy-in: \$${buyIn.toStringAsFixed(2)} • Cash-out: \$${cashOut.toStringAsFixed(2)}');
        summary.writeln('   Net: ${_formatAmount(netAmount)}');
        if (game.cutPercentage > 0 && originalAmount != netAmount) {
          summary.writeln('   Original: ${_formatAmount(originalAmount)}');
        }
      }
      summary.writeln('');
    }

    // Break Even
    final breakEven =
        game.players.where((p) => game.getPlayerNetAmount(p.id) == 0).toList();
    if (breakEven.isNotEmpty) {
      summary.writeln('⚖️ Break Even:');
      for (final player in breakEven) {
        final buyIn = player.calculateTotalIn(game.buyInAmount);
        final cashOut = player.cashOut ?? 0;

        summary.writeln('${player.name}');
        summary.writeln(
            '   Buy-in: \$${buyIn.toStringAsFixed(2)} • Cash-out: \$${cashOut.toStringAsFixed(2)}');
        summary.writeln('   Net: \$0.00');
      }
      summary.writeln('');
    }

    // Losers
    final losers =
        game.players.where((p) => game.getPlayerNetAmount(p.id) < 0).toList();
    if (losers.isNotEmpty) {
      summary.writeln('📉 Losers:');
      for (final player in losers) {
        final netAmount = game.getPlayerNetAmount(player.id);
        final originalAmount = game.getPlayerOriginalAmount(player.id);
        final buyIn = player.calculateTotalIn(game.buyInAmount);
        final cashOut = player.cashOut ?? 0;

        summary.writeln('${player.name}');
        summary.writeln(
            '   Buy-in: \$${buyIn.toStringAsFixed(2)} • Cash-out: \$${cashOut.toStringAsFixed(2)}');
        summary.writeln('   Net: ${_formatAmount(netAmount)}');
        if (game.cutPercentage > 0 && originalAmount != netAmount) {
          summary.writeln('   Original: ${_formatAmount(originalAmount)}');
        }
      }
      summary.writeln('');
    }

    // Payment Instructions
    if (game.isPotBalanced) {
      final payments = _calculatePayments(winners, losers);
      if (payments.isNotEmpty) {
        summary.writeln('💸 Payment Instructions:');
        for (final payment in payments) {
          summary.writeln(
              '${_formatName(payment['from'].name)} ➡️ ${_formatName(payment['to'].name)}: \$${payment['amount'].toStringAsFixed(2)}');
        }
      }
    }

    try {
      await Share.share(summary.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share game summary')),
      );
    }
  }
}
