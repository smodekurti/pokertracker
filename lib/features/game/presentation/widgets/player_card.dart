import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/shared/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final double buyInAmount;
  final Function(double amount)? onReEntry; // Update callback type
  final Function(String recipientId, double amount)? onLoan;
  final Function(double)? onSettle;
  final VoidCallback? onRemoveEntry;
  final bool isSettled; // Add this parameter

  const PlayerCard({
    super.key,
    required this.player,
    required this.buyInAmount,
    this.onReEntry,
    this.onLoan,
    this.onSettle,
    this.onRemoveEntry,
    required this.isSettled, // Add this to constructor
  });

  @override
  Widget build(BuildContext context) {
    // Override text scaling to maintain consistent sizing
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(12.dp),
        ),
        margin: EdgeInsets.only(bottom: 8.dp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _buildPlayerInfo()),
                if (!isSettled) _buildOptionsMenu(context),
              ],
            ),
            _buildTransactionInfo(),
            SizedBox(height: 16.dp),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 24.dp,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.dp),
      ),
      color: AppColors.backgroundDark,
      itemBuilder: (context) => [
        if (player.buyIns > 1)
          PopupMenuItem(
            value: 'remove_entry',
            child: Row(
              children: [
                Icon(Icons.remove_circle, color: AppColors.error, size: 20.dp),
                SizedBox(width: 12.dp),
                Text(
                  'Remove Entry',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.dp,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'give_loan',
          child: Row(
            children: [
              Icon(Icons.account_balance,
                  color: Colors.purple[300], size: 20.dp),
              SizedBox(width: 12.dp),
              Text(
                'Give Loan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.dp,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'remove_entry':
            final confirmed = await _showRemoveEntryConfirmation(context);
            if (confirmed == true && onRemoveEntry != null) {
              onRemoveEntry!();
            }
            break;
          case 'give_loan':
            await _showLoanDialog(context);
            break;
        }
      },
    );
  }

  Widget _buildPlayerInfo() {
    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: Row(
        children: [
          _buildAvatar(),
          SizedBox(width: 12.dp),
          _buildPlayerDetails(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40.dp,
      height: 40.dp,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          player.name[0].toUpperCase(),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20.dp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerDetails() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18, // Fixed size instead of responsive
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            player.isSettled ? 'Settled' : 'Active',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14, // Fixed size
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.dp),
      child: Column(
        children: [
          _buildTransactionRow(
            icon: Icons.shopping_cart,
            label: 'Buy-ins',
            value: '${player.buyIns}x \$${buyInAmount.toStringAsFixed(2)}',
            valueColor: AppColors.textPrimary,
          ),
          if (player.loans != 0) ...[
            SizedBox(height: 8.dp),
            _buildTransactionRow(
              icon: Icons.account_balance_wallet,
              label: 'Loans',
              value:
                  '${player.loans > 0 ? '+' : ''}\$${player.loans.toStringAsFixed(2)}',
              valueColor:
                  player.loans > 0 ? AppColors.success : AppColors.error,
              iconColor: player.loans > 0 ? AppColors.success : AppColors.error,
            ),
          ],
          if (player.isSettled) ...[
            SizedBox(height: 8.dp),
            _buildTransactionRow(
              icon: Icons.money_off,
              label: 'Cash-out',
              value: '\$${player.cashOut?.toStringAsFixed(2) ?? ''}',
              valueColor: AppColors.textPrimary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor ?? AppColors.textSecondary,
          size: 16, // Fixed size
        ),
        SizedBox(width: 8.dp),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14, // Fixed size
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14, // Fixed size
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSlideBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.dp),
      ),
      margin: EdgeInsets.only(bottom: 8.dp),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            SizedBox(width: 20.dp),
            Icon(icon, color: Colors.white),
            SizedBox(width: 8.dp),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
          ] else ...[
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
            SizedBox(width: 8.dp),
            Icon(icon, color: Colors.white),
            SizedBox(width: 20.dp),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showRemoveEntryConfirmation(BuildContext context) async {
    HapticFeedback.heavyImpact();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Remove Re-Entry?',
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
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontM.sp,
                ),
                children: [
                  TextSpan(text: 'Remove entry for '),
                  TextSpan(
                    text: player.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' with buy-in amount '),
                  TextSpan(
                    text: '\$${buyInAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: AppSizes.iconM.dp,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The entry will be permanently removed.',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: AppSizes.fontS.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
            ),
            child: TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                ),
              ),
              child: Text(
                'Remove',
                style: TextStyle(
                  fontSize: AppSizes.fontM.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return result;
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.dp),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth - 8.dp) / 2;
          return Row(
            children: [
              SizedBox(
                width: buttonWidth,
                child: _buildActionButton(
                  label: 'Re-Entry',
                  icon: Icons.refresh,
                  color: AppColors.secondary,
                  isDisabled: isSettled,
                  onPressed: onReEntry == null
                      ? null
                      : () {
                          _showReEntryConfirmation(context);
                        },
                ),
              ),
              SizedBox(width: 8.dp),
              SizedBox(
                width: buttonWidth,
                child: _buildActionButton(
                  label: 'Settle',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  onPressed: isSettled
                      ? null
                      : () =>
                          _showSettleDialog(context), // Use the new parameter
                  isDisabled: isSettled, // Use the new parameter
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool isDisabled = false,
  }) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? AppColors.backgroundDark : color,
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textSecondary,
        disabledBackgroundColor: AppColors.backgroundDark,
        padding: EdgeInsets.symmetric(vertical: 12.dp),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.dp),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.dp),
          SizedBox(width: 8.dp),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.dp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReEntryConfirmation(BuildContext context) async {
    HapticFeedback.heavyImpact();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Confirm Re-Entry',
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
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontM.sp,
                ),
                children: [
                  const TextSpan(text: 'Add another buy-in for '),
                  TextSpan(
                    text: player.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' with amount '),
                  TextSpan(
                    text: '\$${buyInAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
            ),
            child: TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                ),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontSize: AppSizes.fontM.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && onReEntry != null) {
      onReEntry!(buyInAmount);
    }
  }

  Future<void> _showLoanDialog(BuildContext context) async {
    String? selectedRecipientId;
    final amountController = TextEditingController();

    final recipients = Provider.of<GameProvider>(context, listen: false)
            .currentGame
            ?.players
            .where((p) => p.id != player.id)
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
            'Loan from ${player.name}',
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

    if (result != null && onLoan != null) {
      onLoan!(result['recipientId'] as String, result['amount']);
    }
  }

  Future<void> _showSettleDialog(BuildContext context) async {
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
          'Settle ${player.name}',
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
              'Total Buy-in: \$${(player.calculateTotalIn(buyInAmount)).toStringAsFixed(2)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
            if (player.loans > 0) ...[
              SizedBox(height: 4.dp),
              Text(
                'Loans: \$${player.loans.toStringAsFixed(2)}',
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

    if (result != null && onSettle != null) {
      onSettle!(result);
    }
  }
}
