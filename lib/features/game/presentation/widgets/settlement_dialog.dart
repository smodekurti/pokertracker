import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/settlement_state.dart';

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

  const SettlementDialog(
      {super.key,
      required this.player,
      required this.buyInAmount,
      required this.playerName,
      required this.currentIndex,
      required this.totalPlayers,
      required this.state,
      required this.initialAmount,
      required this.recommendedAmount,
      required this.isLastPlayer,
      required this.playerId});

  @override
  State<SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<SettlementDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAmount(String value) {
    if (widget.isLastPlayer) {
      final amount = double.tryParse(value) ?? 0;
      final difference = (amount - widget.recommendedAmount).abs();
      setState(() {
        _errorText = difference > 0.01
            ? 'Amount must be ${widget.recommendedAmount.toStringAsFixed(2)}'
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Settle ${widget.playerName}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font2XL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressInfo(),
            SizedBox(height: AppSizes.spacingL.dp),
            _buildSettlementInfo(),
            SizedBox(height: AppSizes.spacingL.dp),
            _buildAmountInput(),
          ],
        ),
        actions: _buildActions(context),
      ),
    );
  }

  Widget _buildProgressInfo() {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM.dp),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Player ${widget.currentIndex + 1} of ${widget.totalPlayers}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM.dp,
              vertical: AppSizes.paddingXS.dp,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
            ),
            child: Text(
              '${((widget.currentIndex + 1) / widget.totalPlayers * 100).toInt()}%',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: AppSizes.fontS.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementInfo() {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM.dp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Total Pot:',
            '\$${widget.state.totalPot.toStringAsFixed(2)}',
          ),
          SizedBox(height: AppSizes.spacingS.dp),
          _buildInfoRow(
            'Current Total:',
            '\$${widget.state.totalSettled.toStringAsFixed(2)}',
          ),
          if (widget.isLastPlayer) ...[
            SizedBox(height: AppSizes.spacingS.dp),
            _buildInfoRow(
              'Recommended:',
              '\$${widget.recommendedAmount.toStringAsFixed(2)}',
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
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
            color: highlight ? AppColors.primary : AppColors.textPrimary,
            fontSize: AppSizes.fontM.sp,
            fontWeight: highlight ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    final bool isPlayerSettled = widget.state.isPlayerSettled(widget.playerId);
    final totalInput = widget.player.calculateTotalIn(widget.buyInAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontL.sp,
          ),
          decoration: InputDecoration(
            labelText: 'Cash-out Amount',
            errorText: _errorText,
            prefixText: '\$',
            labelStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
            prefixStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontL.sp,
            ),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          onChanged: isPlayerSettled ? null : _validateAmount,
          autofocus: !isPlayerSettled,
          readOnly: isPlayerSettled,
        ),
        Padding(
          padding: EdgeInsets.only(
            left: AppSizes.paddingS.dp,
            top: AppSizes.paddingXS.dp,
          ),
          child: Text(
            'Total Input: \$${totalInput.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontS.sp,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final bool allPlayersSettled =
        widget.state.isBalanced() && widget.isLastPlayer;

    if (allPlayersSettled) {
      return [
        Container(
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
              if (_errorText != null) return;
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
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.currentIndex > 0
              ? TextButton(
                  onPressed: () => Navigator.pop(context, {'action': 'prev'}),
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontM.sp,
                    ),
                  ),
                )
              : const Spacer(),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(_controller.text) ?? 0;
              if (_errorText != null) return;
              Navigator.pop(context, {
                'action': 'save',
                'amount': amount,
              });
            },
            child: Text(
              'Next',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppSizes.fontM.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          /*widget.currentIndex < widget.totalPlayers - 1
              ? TextButton(
                  onPressed: () {
                    final amount = double.tryParse(_controller.text) ?? 0;
                    if (_errorText != null) return;
                    Navigator.pop(context, {
                      'action': 'next',
                      'amount': amount,
                    });
                  },
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.fontM.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const Spacer(),*/
        ],
      ),
    ];
  }
}
