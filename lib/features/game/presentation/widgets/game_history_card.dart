import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/shared/widgets/custom_button.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';

class GameHistoryCard extends StatelessWidget {
  final Game game;

  const GameHistoryCard({
    super.key,
    required this.game,
  });

  List<PlayerResult> get _playerResults {
    return game.players.map((player) {
      final totalBuyIn = player.calculateTotalIn(game.buyInAmount);
      final cashOutAmount = player.cashOut ?? 0.0;
      final netPosition = cashOutAmount - totalBuyIn;

      return PlayerResult(
        player: player,
        totalBuyIn: totalBuyIn,
        cashOutAmount: cashOutAmount,
        netPosition: netPosition,
      );
    }).toList();
  }

  List<PlayerResult> get _winners {
    return _playerResults.where((result) => result.netPosition > 0).toList()
      ..sort((a, b) => b.netPosition.compareTo(a.netPosition));
  }

  List<PlayerResult> get _losers {
    return _playerResults.where((result) => result.netPosition < 0).toList()
      ..sort((a, b) => a.netPosition.compareTo(b.netPosition));
  }

  List<PlayerResult> get _breakEven {
    return _playerResults
        .where((result) => result.netPosition.abs() < 0.01)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        cardColor: Colors.transparent,
      ),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: AppColors.primaryGradient,
              ).createShader(bounds),
              child: Text(
                game.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.font2XL.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.share,
                color: AppColors.textPrimary,
                size: AppSizes.iconM.dp,
              ),
              onPressed: () => shareGameSummary(context),
              tooltip: 'Share Game Summary',
            ),
            SizedBox(height: AppSizes.spacingXS.dp),
            Text(
              DateFormat('MMM dd, yyyy').format(game.date),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
            Text(
              'Total Pot: \$${game.totalPot.toStringAsFixed(2)}',
              style: TextStyle(
                color: AppColors.info,
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconColor: AppColors.textPrimary,
        collapsedIconColor: AppColors.textPrimary,
        children: [
          _buildExpandedContent(context),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSizes.radiusL.dp),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.info.withOpacity(0.05),
          ],
        ),
      ),
      padding: EdgeInsets.all(AppSizes.paddingL.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_winners.isNotEmpty)
            _buildSection(
              context: context,
              title: 'Winners',
              results: _winners,
              isWinners: true,
            ),
          if (_winners.isNotEmpty) SizedBox(height: AppSizes.spacingL.dp),
          if (_breakEven.isNotEmpty)
            _buildSection(
              context: context,
              title: 'Break Even',
              results: _breakEven,
              isBreakEven: true,
            ),
          if (_breakEven.isNotEmpty) SizedBox(height: AppSizes.spacingL.dp),
          if (_losers.isNotEmpty)
            _buildSection(
              context: context,
              title: 'Losers',
              results: _losers,
              isWinners: false,
            ),
          if (_losers.isNotEmpty) SizedBox(height: AppSizes.spacingL.dp),
          // Add payment instructions section here
          if (game.isPotBalanced && !game.hasUnsettledLoans()) ...[
            PaymentInstructionSection(game: game),
            SizedBox(height: AppSizes.spacingL.dp),
          ],
          _buildGameDetails(context),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<PlayerResult> results,
    bool isWinners = false,
    bool isBreakEven = false,
  }) {
    final titleColor = isBreakEven
        ? AppColors.info
        : (isWinners ? AppColors.success : AppColors.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontL.sp,
          ),
        ),
        SizedBox(height: AppSizes.spacingS.dp),
        ...results.map((result) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.spacingXS.dp),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.player.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: AppSizes.fontM.sp,
                        ),
                      ),
                      Text(
                        'Buy-in: \$${result.totalBuyIn.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: AppSizes.fontM.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.netPosition > 0 ? '+' : ''}\$${result.netPosition.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontM.sp,
                      ),
                    ),
                    Text(
                      'Cash out: \$${result.cashOutAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: AppSizes.fontM.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        if (results.isEmpty)
          Text(
            'None',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
      ],
    );
  }

  Widget _buildGameDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontL.sp,
          ),
        ),
        SizedBox(height: AppSizes.spacingS.dp),
        _buildDetailRow('Buy-in Amount:', '\$${game.buyInAmount}'),
        _buildDetailRow('Players:', '${game.players.length}'),
        _buildDetailRow('Duration:', _calculateDuration()),
        _buildDetailRow(
          'Average Stack:',
          '\$${(game.totalPot / game.players.length).toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.spacingXS.dp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    if (game.endedAt == null) return 'N/A';

    final duration = game.endedAt!.difference(game.createdAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes} min';
    } else {
      return '$minutes min';
    }
  }
}

class GameHistoryDetailDialog extends StatelessWidget {
  final Game game;

  const GameHistoryDetailDialog({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingL.dp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game History Details',
              style: TextStyle(
                fontSize: AppSizes.font2XL.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.spacingL.dp),
            Expanded(
              child: ListView.builder(
                itemCount: game.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = game.transactions[index];
                  final player = game.players.firstWhere(
                    (p) => p.id == transaction.playerId,
                  );

                  return Container(
                    margin: EdgeInsets.only(bottom: AppSizes.spacingS.dp),
                    padding: EdgeInsets.all(AppSizes.paddingM.dp),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSizes.fontL.sp,
                                ),
                              ),
                              if (transaction.note != null) ...[
                                SizedBox(height: AppSizes.spacingXS.dp),
                                Text(
                                  transaction.note!,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: AppSizes.fontM.sp,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '\$${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: transaction.amount > 0
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.fontL.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppSizes.spacingL.dp),
            CustomButton(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerResult {
  final Player player;
  final double totalBuyIn;
  final double cashOutAmount;
  final double netPosition;

  PlayerResult({
    required this.player,
    required this.totalBuyIn,
    required this.cashOutAmount,
    required this.netPosition,
  });

  bool get isWinner => netPosition > 0;
  bool get isLoser => netPosition < 0;
  bool get isBreakEven => netPosition.abs() < 0.01;

  @override
  String toString() {
    final prefix = isWinner ? '+' : '';
    return '${player.name}: $prefix\$${netPosition.toStringAsFixed(2)} '
        '(In: \$${totalBuyIn.toStringAsFixed(2)}, '
        'Out: \$${cashOutAmount.toStringAsFixed(2)})';
  }
}

class PaymentInstructionSection extends StatelessWidget {
  final Game game;

  const PaymentInstructionSection({
    super.key,
    required this.game,
  });

  String formatName(String name) {
    if (name.length <= 10) {
      return name;
    } else {
      List<String> words = name.split(' ');
      if (words.length == 1) {
        return words[0].substring(0, 10);
      } else {
        String firstWord =
            words[0].length <= 10 ? words[0] : words[0].substring(0, 10);
        String secondWord = words.length > 1 && words[1].length >= 3
            ? words[1].substring(0, 3)
            : '';
        return '$firstWord$secondWord';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final winners = _playerResults
        .where((result) => result.netPosition > 0)
        .map((result) => result.player)
        .toList();

    final losers = _playerResults
        .where((result) => result.netPosition < 0)
        .map((result) => result.player)
        .toList();

    final payments = _calculatePayments(winners, losers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Instructions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontL.sp,
          ),
        ),
        SizedBox(height: AppSizes.spacingM.dp),
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
                margin: EdgeInsets.only(bottom: AppSizes.spacingS.dp),
                padding: EdgeInsets.all(AppSizes.paddingM.dp),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            formatName(from.name),
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
                            formatName(to.name),
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

  List<PlayerResult> get _playerResults {
    return game.players.map((player) {
      final totalBuyIn = player.calculateTotalIn(game.buyInAmount);
      final cashOutAmount = player.cashOut ?? 0.0;
      final netPosition = cashOutAmount - totalBuyIn;

      return PlayerResult(
        player: player,
        totalBuyIn: totalBuyIn,
        cashOutAmount: cashOutAmount,
        netPosition: netPosition,
      );
    }).toList();
  }

  List<Map<String, dynamic>> _calculatePayments(
      List<Player> winners, List<Player> losers) {
    final payments = <Map<String, dynamic>>[];
    const double minimumPayment = 0.01;

    // Create mutable copies of amounts to track
    final remainingLosses = losers.map((loser) {
      final netAmount =
          loser.cashOut! - loser.calculateTotalIn(game.buyInAmount);
      return MapEntry(loser, netAmount.abs());
    }).toList();

    final remainingWins = winners.map((winner) {
      final netAmount =
          winner.cashOut! - winner.calculateTotalIn(game.buyInAmount);
      return MapEntry(winner, netAmount);
    }).toList();

    // Sort by amount for optimal matching
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

        // Update remaining amounts
        final remainingLoss = currentLoser.value - paymentAmount;
        final remainingWin = currentWinner.value - paymentAmount;

        // Remove or update loser entry
        if (remainingLoss <= minimumPayment) {
          remainingLosses.removeAt(0);
        } else {
          remainingLosses[0] = MapEntry(
              currentLoser.key, double.parse(remainingLoss.toStringAsFixed(2)));
        }

        // Remove or update winner entry
        if (remainingWin <= minimumPayment) {
          remainingWins.removeAt(0);
        } else {
          remainingWins[0] = MapEntry(
              currentWinner.key, double.parse(remainingWin.toStringAsFixed(2)));
        }
      } else {
        // Handle remaining small amounts
        if (currentLoser.value <= minimumPayment) remainingLosses.removeAt(0);
        if (currentWinner.value <= minimumPayment) remainingWins.removeAt(0);
      }
    }

    return payments;
  }
}

extension GameHistoryShare on GameHistoryCard {
  Future<void> shareGameSummary(BuildContext context) async {
    final StringBuffer summary = StringBuffer();

    // Game Header
    summary.writeln('🎲 ${game.name}');
    summary.writeln('📅 ${DateFormat('MMM dd, yyyy').format(game.date)}');
    summary.writeln('💰 Total Pot: \$${game.totalPot.toStringAsFixed(2)}');
    summary.writeln('');

    // Game Details
    summary.writeln('🎮 Game Details:');
    summary.writeln('• Buy-in: \$${game.buyInAmount}');
    summary.writeln('• Players: ${game.players.length}');
    summary.writeln('• Duration: ${_calculateDuration()}');
    summary.writeln(
        '• Average Stack: \$${(game.totalPot / game.players.length).toStringAsFixed(2)}');
    summary.writeln('');

    // Winners Section
    if (_winners.isNotEmpty) {
      summary.writeln('🏆 Winners:');
      for (var result in _winners) {
        summary.writeln(
            '• ${result.player.name}: +\$${result.netPosition.toStringAsFixed(2)}');
        summary.writeln(
            '  In: \$${result.totalBuyIn.toStringAsFixed(2)} | Out: \$${result.cashOutAmount.toStringAsFixed(2)}');
      }
      summary.writeln('');
    }

    // Break Even Section
    if (_breakEven.isNotEmpty) {
      summary.writeln('🤝 Break Even:');
      for (var result in _breakEven) {
        summary.writeln('• ${result.player.name}');
        summary.writeln(
            '  In: \$${result.totalBuyIn.toStringAsFixed(2)} | Out: \$${result.cashOutAmount.toStringAsFixed(2)}');
      }
      summary.writeln('');
    }

    // Losers Section
    if (_losers.isNotEmpty) {
      summary.writeln('📉 Losers:');
      for (var result in _losers) {
        summary.writeln(
            '• ${result.player.name}: -\$${result.netPosition.abs().toStringAsFixed(2)}');
        summary.writeln(
            '  In: \$${result.totalBuyIn.toStringAsFixed(2)} | Out: \$${result.cashOutAmount.toStringAsFixed(2)}');
      }
      summary.writeln('');
    }

    // Payment Instructions
    if (game.isPotBalanced && !game.hasUnsettledLoans()) {
      final winners = _winners.map((result) => result.player).toList();
      final losers = _losers.map((result) => result.player).toList();
      final payments = _calculatePayments(winners, losers);

      if (payments.isNotEmpty) {
        summary.writeln('💸 Payment Instructions:');
        for (var payment in payments) {
          summary.writeln(
              '• ${payment['from'].name} ➡️ ${payment['to'].name}: \$${payment['amount'].toStringAsFixed(2)}');
        }
        summary.writeln('');
      }
    }

    // Add app branding
    summary.writeln('Generated by Poker Tracker 🎲');

    try {
      await Share.share(
        summary.toString(),
        subject: '${game.name} - Game Summary',
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

  List<Map<String, dynamic>> _calculatePayments(
      List<Player> winners, List<Player> losers) {
    final payments = <Map<String, dynamic>>[];
    const double minimumPayment = 0.01;

    // Create mutable copies of amounts to track
    final remainingLosses = losers.map((loser) {
      final netAmount =
          loser.cashOut! - loser.calculateTotalIn(game.buyInAmount);
      return MapEntry(loser, netAmount.abs());
    }).toList();

    final remainingWins = winners.map((winner) {
      final netAmount =
          winner.cashOut! - winner.calculateTotalIn(game.buyInAmount);
      return MapEntry(winner, netAmount);
    }).toList();

    // Sort by amount for optimal matching
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
            currentLoser.key,
            double.parse(remainingLoss.toStringAsFixed(2)),
          );
        }

        if (remainingWin <= minimumPayment) {
          remainingWins.removeAt(0);
        } else {
          remainingWins[0] = MapEntry(
            currentWinner.key,
            double.parse(remainingWin.toStringAsFixed(2)),
          );
        }
      } else {
        if (currentLoser.value <= minimumPayment) remainingLosses.removeAt(0);
        if (currentWinner.value <= minimumPayment) remainingWins.removeAt(0);
      }
    }

    return payments;
  }
}
