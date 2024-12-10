import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBuyInsAndLoans(),
                      SizedBox(height: 16.dp),
                      _buildCashOutInput(),
                      SizedBox(height: 16.dp),
                      _buildExpectedBalance(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.dp),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.dp)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              widget.playerName[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12.dp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settle Player',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold)),
                Text(widget.playerName,
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyInsAndLoans() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoBox('Buy-ins',
              '\$${widget.buyInAmount.toStringAsFixed(2)} × ${widget.player.buyIns}'),
        ),
        SizedBox(width: 12.dp),
        Expanded(
          child: _buildInfoBox(
              'Loans', '\$${widget.player.loans.toStringAsFixed(2)} × 1'),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String content) {
    return Container(
      padding: EdgeInsets.all(12.dp),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(8.dp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          SizedBox(height: 4.dp),
          Text(content,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCashOutInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cash-out Amount',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        SizedBox(height: 8.dp),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.dp),
          decoration: BoxDecoration(
            color: AppColors.backgroundMedium,
            borderRadius: BorderRadius.circular(8.dp),
          ),
          child: TextField(
            controller: _controller,
            style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold),
              suffixText: '.00',
              suffixStyle: TextStyle(color: Colors.grey, fontSize: 24.sp),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildExpectedBalance() {
    double cashOut = double.tryParse(_controller.text) ?? 0;
    double totalIn =
        widget.buyInAmount * widget.player.buyIns + widget.player.loans;
    double expectedBalance = cashOut - totalIn;
    Color balanceColor =
        expectedBalance >= 0 ? AppColors.success : AppColors.error;

    return Container(
      padding: EdgeInsets.all(12.dp),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(8.dp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expected Balance',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          SizedBox(height: 4.dp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: expectedBalance.abs() / totalIn,
                  backgroundColor: AppColors.backgroundLight,
                  valueColor: AlwaysStoppedAnimation<Color>(balanceColor),
                ),
              ),
              SizedBox(width: 12.dp),
              Text(
                '${expectedBalance >= 0 ? '+' : '-'}\$${expectedBalance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                    color: balanceColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final bool allPlayersSettled =
        widget.state.isBalanced() && widget.isLastPlayer;

    if (allPlayersSettled) {
      return Padding(
        padding: EdgeInsets.all(16.dp),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          ),
          child: ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_controller.text) ?? 0;
              // if (_errorText != null) return;
              Navigator.pop(context, {
                'action': 'finalize',
                'amount': amount,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                vertical: AppSizes.paddingM.dp,
                horizontal: AppSizes.paddingL.dp,
              ),
            ),
            child: Text(
              'Settle Game',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.currentIndex > 0
              ? ElevatedButton(
                  onPressed: () => Navigator.pop(context, {'action': 'prev'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cancelButton,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.dp)),
                  ),
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontM.sp,
                    ),
                  ),
                )
              : const Spacer(),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_controller.text) ?? 0;
              //if (_errorText != null) return;
              Navigator.pop(context, {
                'action': 'save',
                'amount': amount,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.dp)),
            ),
            child: Text(
              'Next',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontM.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
