import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/game.dart';
import '../../data/models/player.dart';

class PaymentInstructionSection extends StatefulWidget {
  final Game game;
  final bool showAfterCut;

  const PaymentInstructionSection({
    super.key,
    required this.game,
    required this.showAfterCut,
  });

  @override
  State<PaymentInstructionSection> createState() =>
      _PaymentInstructionSectionState();
}

class _PaymentInstructionSectionState extends State<PaymentInstructionSection> {
  late List<Map<String, dynamic>> _cachedPayments;

  @override
  void initState() {
    super.initState();
    _cachedPayments = calculatePayments();
  }

  @override
  void didUpdateWidget(PaymentInstructionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAfterCut != widget.showAfterCut) {
      _cachedPayments = calculatePayments();
    }
  }

  List<Map<String, dynamic>> calculatePayments() {
    const double minimumPayment = 0.01;
    final payments = <Map<String, dynamic>>[];

    // Calculate net positions
    final List<_PaymentParticipant> winners = [];
    final List<_PaymentParticipant> losers = [];

    for (var player in widget.game.players) {
      final totalBuyIn = player.calculateTotalIn(widget.game.buyInAmount);
      final cashOutAmount = player.cashOut ?? 0.0;
      double netAmount;

      // Apply cut if needed
      if (widget.showAfterCut) {
        netAmount = (cashOutAmount - totalBuyIn) *
            (1 - widget.game.cutPercentage / 100);
      } else {
        netAmount = cashOutAmount - totalBuyIn;
      }

      if (netAmount.abs() < minimumPayment) continue;

      if (netAmount > 0) {
        winners.add(_PaymentParticipant(player, netAmount));
      } else {
        losers.add(_PaymentParticipant(player, netAmount.abs()));
      }
    }

    // Sort by amount for optimal matching
    winners.sort((a, b) => b.amount.compareTo(a.amount));
    losers.sort((a, b) => b.amount.compareTo(a.amount));

    while (losers.isNotEmpty && winners.isNotEmpty) {
      final currentLoser = losers[0];
      final currentWinner = winners[0];

      final paymentAmount = min(
        currentLoser.amount,
        currentWinner.amount,
      );

      if (paymentAmount > minimumPayment) {
        payments.add({
          'from': currentLoser.player,
          'to': currentWinner.player,
          'amount': double.parse(paymentAmount.toStringAsFixed(2)),
        });

        // Update remaining amounts
        currentLoser.amount -= paymentAmount;
        currentWinner.amount -= paymentAmount;

        // Remove participants with settled amounts
        if (currentLoser.amount <= minimumPayment) losers.removeAt(0);
        if (currentWinner.amount <= minimumPayment) winners.removeAt(0);
      } else {
        // Handle remaining small amounts
        if (currentLoser.amount <= minimumPayment) losers.removeAt(0);
        if (currentWinner.amount <= minimumPayment) winners.removeAt(0);
      }
    }

    return payments;
  }

  String _formatName(String name) {
    const maxLength = 10;
    if (name.length <= maxLength) return name;

    final names = name.split(' ');
    if (names.length == 1) {
      return names[0].substring(0, min(maxLength, names[0].length));
    }

    final firstName = names[0];
    final lastName = names[1];

    return '${firstName.substring(0, min(maxLength - 4, firstName.length))} ${lastName.substring(0, min(3, lastName.length))}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedPayments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'No payments necessary. Everyone is square!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _cachedPayments.map((payment) {
        final from = payment['from'] as Player;
        final to = payment['to'] as Player;
        final amount = payment['amount'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _formatName(from.name),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                    Text(
                      _formatName(to.name),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentParticipant {
  final Player player;
  double amount;

  _PaymentParticipant(this.player, this.amount);
}
