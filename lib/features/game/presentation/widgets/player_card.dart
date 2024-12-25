import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final totalIn = widget.player.calculateTotalIn(widget.buyInAmount);

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.paddingM.dp),
      decoration: BoxDecoration(
        color: widget.isSettled
            ? AppColors.backgroundMedium.withOpacity(0.5)
            : AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
        border: widget.isSettled
            ? Border.all(color: AppColors.success.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          // Player Info Section
          Padding(
            padding: EdgeInsets.all(AppSizes.paddingM.dp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.player.name,
                        style: TextStyle(
                          fontSize: AppSizes.fontXL.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.isSettled
                              ? AppColors.textPrimary.withOpacity(0.7)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (widget.isSettled)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS.dp,
                          vertical: AppSizes.paddingXS.dp,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusS.dp),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: AppSizes.iconS.dp,
                            ),
                            SizedBox(width: AppSizes.spacingXS.dp),
                            Text(
                              'Settled',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: AppSizes.fontS.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppSizes.spacingS.dp),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      label: 'Buy-ins',
                      value: widget.player.buyIns.toString(),
                      icon: Icons.attach_money,
                    ),
                    _buildStatItem(
                      label: 'Total In',
                      value: '\$${totalIn.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                    ),
                    if (widget.player.loans > 0)
                      _buildStatItem(
                        label: 'Loans',
                        value: '\$${widget.player.loans.toStringAsFixed(2)}',
                        icon: Icons.swap_horiz,
                        color: AppColors.warning,
                      ),
                    if (widget.player.cashOut != null)
                      _buildStatItem(
                        label: 'Cash Out',
                        value: '\$${widget.player.cashOut!.toStringAsFixed(2)}',
                        icon: Icons.payments,
                        color: AppColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons Section - Only show if not settled
          if (!widget.isSettled) ...[
            Divider(
              color: Colors.grey[700],
              height: 1,
            ),
            Padding(
              padding: EdgeInsets.all(AppSizes.paddingS.dp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.add_circle,
                    label: 'Re-entry',
                    onPressed: widget.onReEntry != null
                        ? () => _handleReEntry()
                        : null,
                  ),
                  _buildActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Loan',
                    onPressed:
                        widget.onLoan != null ? () => _showLoanDialog() : null,
                  ),
                  _buildActionButton(
                    icon: Icons.payments,
                    label: 'Settle',
                    onPressed: widget.onSettle != null
                        ? () => _showSettleDialog()
                        : null,
                  ),
                  if (widget.player.buyIns > 1)
                    _buildActionButton(
                      icon: Icons.remove_circle,
                      label: 'Remove Entry',
                      onPressed: widget.onRemoveEntry,
                      color: AppColors.error,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.textSecondary,
          size: AppSizes.iconM.dp,
        ),
        SizedBox(height: AppSizes.spacingXS.dp),
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
            fontSize: AppSizes.fontM.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.paddingS.dp,
          horizontal: AppSizes.paddingM.dp,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS.dp),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppSizes.iconM.dp),
          SizedBox(height: AppSizes.spacingXS.dp),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontS.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReEntry() async {
    setState(() => _isLoading = true);
    try {
      final amount = await widget.onReEntry!(widget.buyInAmount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Re-entry successful: \$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: AppSizes.fontM.sp),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Re-entry failed: $e',
            style: TextStyle(fontSize: AppSizes.fontM.sp),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No available players to loan to',
            style: TextStyle(fontSize: AppSizes.fontM.sp),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
          ),
          title: Text(
            'Loan from ${widget.player.name}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXL.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.dp),
                  color: AppColors.backgroundDark,
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.dp),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRecipientId,
                    hint: Text(
                      'Select Player',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontM.sp,
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
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppSizes.fontM.sp,
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
              SizedBox(height: 16.dp),
              CustomTextField(
                controller: amountController,
                label: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money,
                fontSize: AppSizes.fontL.sp,
                prefixIconSize: AppSizes.iconM.dp,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontM.sp,
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
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontSize: AppSizes.fontM.sp,
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
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Settle ${widget.player.name}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontXL.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Buy-in: \$${(widget.player.calculateTotalIn(widget.buyInAmount)).toStringAsFixed(2)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
            if (widget.player.loans > 0) ...[
              SizedBox(height: 4.dp),
              Text(
                'Loans: \$${widget.player.loans.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: AppSizes.fontM.sp,
                ),
              ),
            ],
            SizedBox(height: 16.dp),
            CustomTextField(
              controller: controller,
              label: 'Cash-out Amount',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
              fontSize: AppSizes.fontL.sp,
              prefixIconSize: AppSizes.iconM.dp,
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
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontM.sp,
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
            child: Text(
              'Settle',
              style: TextStyle(
                fontSize: AppSizes.fontM.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && widget.onSettle != null) {
      widget.onSettle!(result);
    }
  }
}
