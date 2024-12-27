// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/shared/widgets/custom_text_field.dart';

class PlayerCard extends StatefulWidget {
  final Player player;
  final double buyInAmount;
  final bool isSettled;
  final Future<double> Function(double amount)? onReEntry;
  final Future<void> Function(String recipientId, double amount)? onLoan;
  final Future<double> Function(double amount)? onSettle;
  final VoidCallback? onRemoveEntry;

  const PlayerCard({
    super.key,
    required this.player,
    required this.buyInAmount,
    required this.isSettled,
    this.onReEntry,
    this.onLoan,
    this.onSettle,
    this.onRemoveEntry,
  });

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final activePlayers =
        gameProvider.currentGame?.players.where((p) => !p.isSettled).length ??
            0;
    const minActivePlayers =
        2; // Define the minimum number of active players required

    final totalIn = widget.player.calculateTotalIn(widget.buyInAmount);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar circle with initial
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.player.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: AppSizes.fontXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.player.name,
                      style: const TextStyle(
                        fontSize: AppSizes.fontL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.isSettled ? 'Settled' : 'Active',
                      style: TextStyle(
                        fontSize: AppSizes.fontS,
                        color: widget.isSettled
                            ? AppColors.success
                            : const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${totalIn.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: AppSizes.fontM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              const Icon(Icons.shopping_cart,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: AppSizes.spacingXS),
              const Text(
                'Buy-ins',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${widget.player.buyIns}x \$${widget.buyInAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.player.loans > 0) ...[
            const SizedBox(height: AppSizes.spacingS),
            Row(
              children: [
                const Icon(Icons.attach_money,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: AppSizes.spacingXS),
                const Text(
                  'Loans',
                  style: TextStyle(color: AppColors.warning),
                ),
                const Spacer(),
                Text(
                  '\$${widget.player.loans.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingS),
            ...widget.player.loansDetails.map((loan) {
              final lender = gameProvider.currentGame?.players
                  .firstWhere((p) => p.id == loan.lenderId);
              return Row(
                children: [
                  const SizedBox(width: AppSizes.spacingL),
                  Text(
                    'From: ${lender?.name ?? 'Unknown'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontS,
                    ),
                  ),
                ],
              );
            }),
          ],
          if (!widget.isSettled) ...[
            const SizedBox(height: AppSizes.spacingM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: activePlayers >= minActivePlayers &&
                            widget.onReEntry != null
                        ? () => _handleReEntry()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: AppSizes.spacingXS),
                        Text('Re-Entry'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: activePlayers >= minActivePlayers &&
                            widget.onSettle != null
                        ? () => _handleSettle()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: AppSizes.spacingXS),
                        Text('Settle'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textSecondary),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'loan',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, color: Colors.purple[400]),
                          const SizedBox(width: AppSizes.spacingS),
                          const Text(
                            'Loan',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    if (widget.player.buyIns > 1)
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle, color: AppColors.error),
                            SizedBox(width: AppSizes.spacingS),
                            Text(
                              'Remove Entry',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  color: AppColors.backgroundMedium,
                  onSelected: (value) {
                    if (value == 'loan') {
                      _showLoanDialog();
                    } else if (value == 'remove') {
                      widget.onRemoveEntry?.call();
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleReEntry() async {
    try {
      final amount = await widget.onReEntry!(widget.buyInAmount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Re-entry successful: \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: AppSizes.fontS),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Re-entry failed: $e',
              style: const TextStyle(fontSize: AppSizes.fontS),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {}
  }

  Future<void> _handleSettle() async {
    await _showSettleDialog();
  }

  Future<void> _showLoanDialog() async {
    String? selectedRecipientId;
    final amountController = TextEditingController();

    final recipients = Provider.of<GameProvider>(context, listen: false)
            .currentGame
            ?.players
            .where((p) => p.id != widget.player.id)
            .toList() ??
        [];

    if (recipients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No available players to loan to',
              style: TextStyle(fontSize: AppSizes.fontS),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          title: Text(
            'Loan from ${widget.player.name}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  color: AppColors.backgroundDark,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRecipientId,
                    hint: const Text(
                      'Select Player',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontS,
                      ),
                    ),
                    dropdownColor: AppColors.backgroundDark,
                    isExpanded: true,
                    items: recipients
                        .where((recipient) => !recipient.isSettled)
                        .map((recipient) {
                      return DropdownMenuItem(
                        value: recipient.id,
                        child: Text(
                          recipient.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppSizes.fontS,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedRecipientId = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              CustomTextField(
                controller: amountController,
                label: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money,
                fontSize: AppSizes.fontM,
                prefixIconSize: AppSizes.iconS,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontS,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (selectedRecipientId != null &&
                    amount != null &&
                    amount > 0) {
                  Navigator.pop(context, {
                    'recipientId': selectedRecipientId,
                    'amount': amount,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontSize: AppSizes.fontS,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && widget.onLoan != null) {
      widget.onLoan!(result['recipientId'] as String, result['amount']);
    }
  }

  Future<void> _showSettleDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        title: Text(
          'Settle ${widget.player.name}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontL,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Buy-in: \$${(widget.player.calculateTotalIn(widget.buyInAmount)).toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontS,
              ),
            ),
            if (widget.player.loans > 0) ...[
              const SizedBox(height: AppSizes.spacingXXS),
              Text(
                'Loans: \$${widget.player.loans.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: AppSizes.fontS,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.spacingS),
            CustomTextField(
              controller: controller,
              label: 'Cash-out Amount',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
              fontSize: AppSizes.fontM,
              prefixIconSize: AppSizes.iconS,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontS,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount >= 0) {
                Navigator.pop(context, amount);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text(
              'Settle',
              style: TextStyle(
                fontSize: AppSizes.fontS,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && widget.onSettle != null) {
      try {
        await widget.onSettle!(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully settled ${widget.player.name}',
                style: const TextStyle(fontSize: AppSizes.fontS),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to settle: $e',
                style: const TextStyle(fontSize: AppSizes.fontS),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {}
    }
  }
}
