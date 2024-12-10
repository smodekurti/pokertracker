import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/settlement_state.dart';

import '../../../../core/presentation/styles/app_sizes.dart';

class SettlementDialog extends StatefulWidget {
  final Player player;
  final double buyInAmount;
  final String playerName;
  final int currentIndex;
  final int totalPlayers;
  final SettlementState state;
  final double initialAmount;
  final double recommendedAmount;
  final bool isLastPlayer;
  final String playerId;

  const SettlementDialog({
    Key? key,
    required this.player,
    required this.buyInAmount,
    required this.playerName,
    required this.currentIndex,
    required this.totalPlayers,
    required this.state,
    required this.initialAmount,
    required this.recommendedAmount,
    required this.isLastPlayer,
    required this.playerId,
  }) : super(key: key);

  @override
  State<SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<SettlementDialog> {
  late TextEditingController _controller;
  late double remainingBalance;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialAmount.toStringAsFixed(2));
    _updateRemainingBalance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateRemainingBalance() {
    double cashOut = double.tryParse(_controller.text) ?? 0;
    remainingBalance =
        widget.state.totalPot - (widget.state.totalSettled + cashOut);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildBuyInsAndLoans(),
            const SizedBox(height: 16),
            if (widget.isLastPlayer) _buildRecommendedAmount(),
            if (widget.isLastPlayer) const SizedBox(height: 16),
            _buildCashOutInput(),
            const SizedBox(height: 16),
            _buildRemainingPot(),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            widget.playerName[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settle Player',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(widget.playerName,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildBuyInsAndLoans() {
    return Row(
      children: [
        Expanded(
            child: _buildInfoBox('Buy-ins',
                '\$${widget.buyInAmount.toStringAsFixed(2)} × ${widget.player.buyIns}')),
        const SizedBox(width: 12),
        Expanded(
            child: _buildInfoBox(
                'Loans', '\$${widget.player.loans.toStringAsFixed(2)} × 1')),
      ],
    );
  }

  Widget _buildInfoBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecommendedAmount() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        border: Border.all(color: AppColors.success, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text('Recommended Amount',
                  style: TextStyle(color: AppColors.success, fontSize: 16)),
            ],
          ),
          Text('\$${widget.recommendedAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCashOutInput() {
    bool isReadOnly = widget.state.isBalanced() && widget.isLastPlayer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cash-out Amount',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundMedium,
            border: Border.all(color: AppColors.success, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.number,
            readOnly: isReadOnly,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                  color: AppColors.success,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              suffixText: '.00',
              suffixStyle: TextStyle(color: Colors.grey, fontSize: 24),
            ),
            onChanged: (value) {
              _updateRemainingBalance();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRemainingPot() {
    Color balanceColor = remainingBalance > 0 ? Colors.white : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remaining Pot',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text('\$${remainingBalance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                      color: balanceColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1 - (remainingBalance / widget.state.totalPot),
            backgroundColor: AppColors.backgroundLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            remainingBalance == 0 ? 'Amount will balance the pot' : '',
            style: const TextStyle(color: AppColors.success, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final bool allPlayersSettled =
        widget.state.isBalanced() && widget.isLastPlayer;

    if (allPlayersSettled) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
        ),
        child: TextButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text) ?? 0;
            Navigator.pop(context, {
              'action': 'finalize',
              'amount': amount,
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: EdgeInsets.symmetric(
              vertical: AppSizes.paddingM.dp,
              horizontal: AppSizes.paddingL.dp,
            ),
          ),
          child: Text(
            'Settle Game',
            style: TextStyle(
              fontSize: ResponsiveSize(AppSizes.fontL).sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        widget.currentIndex > 0
            ? TextButton(
                onPressed: () => Navigator.pop(context, {'action': 'prev'}),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveSize(AppSizes.fontM).sp,
                  ),
                ),
              )
            : const Spacer(),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text) ?? 0;
            Navigator.pop(context, {
              'action': 'save',
              'amount': amount,
            });
          },
          child: Text(
            'Next',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: ResponsiveSize(AppSizes.fontM).sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
