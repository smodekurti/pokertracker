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
  final VoidCallback? onReEntry;
  final Function(String recipientId, double amount)? onLoan; // Updated type
  final Function(double)? onSettle;
  final VoidCallback? onRemoveEntry;

  const PlayerCard({
    super.key,
    required this.player,
    required this.buyInAmount,
    this.onReEntry,
    this.onLoan,
    this.onSettle,
    this.onRemoveEntry,
    required bool isSettled,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final isPlayerSettled = player.isSettled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(12.dp),
      ),
      margin: EdgeInsets.only(bottom: 8.dp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player Info
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: Row(
              children: [
                // Avatar
                Container(
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
                ),
                SizedBox(width: 12.dp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18.dp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        (player.isSettled) ? 'Settled' : 'Active',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14.dp,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildOptionsMenu(context, player.isSettled),
              ],
            ),
          ),

          // Buy-ins and Loans info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.dp),
            child: Column(
              children: [
                // Buy-ins Row
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: AppColors.textSecondary,
                      size: 16.dp,
                    ),
                    SizedBox(width: 8.dp),
                    Text(
                      'Buy-ins',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.dp,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${player.buyIns}x \$${buyInAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.dp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Only show Loans row if there are loans
                if (player.loans != 0) ...[
                  SizedBox(height: 8.dp),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: player.loans > 0
                            ? AppColors.success
                            : AppColors.error,
                        size: 16.dp,
                      ),
                      SizedBox(width: 8.dp),
                      Text(
                        'Loans',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.dp,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${player.loans > 0 ? '+' : ''}\$${player.loans.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: player.loans > 0
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 14.dp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                // Add Cash-out row if the player has settled
                if (player.isSettled) ...[
                  SizedBox(height: 8.dp),
                  Row(
                    children: [
                      Icon(
                        Icons.money_off,
                        color: AppColors.textSecondary,
                        size: 16.dp,
                      ),
                      SizedBox(width: 8.dp),
                      Text(
                        'Cash-out',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.dp,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${player.cashOut?.toStringAsFixed(2) ?? ''}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.dp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          SizedBox(height: 16.dp),

          // Action Buttons
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - 16.dp) / 3;
                return Row(
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        label: 'Re-Entry',
                        icon: Icons.refresh,
                        color: AppColors.secondary,
                        isDisabled: isPlayerSettled,
                        onPressed: onReEntry != null
                            ? () => _showReEntryConfirmation(context)
                            : null,
                      ),
                    ),
                    SizedBox(width: 8.dp),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        label: 'Loan',
                        icon: Icons.account_balance,
                        color: Colors.purple,
                        isDisabled: isPlayerSettled,
                        onPressed: onLoan != null
                            ? () => _showLoanDialog(context)
                            : null,
                      ),
                    ),
                    SizedBox(width: 8.dp),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildActionButton(
                        label: 'Settle',
                        icon: Icons.check_circle,
                        color: AppColors.success,
                        onPressed: isPlayerSettled
                            ? null
                            : () => _showSettleDialog(
                                context), // Disable button if player is settled
                        isDisabled:
                            isPlayerSettled, // Pass isPlayerSettled to _buildActionButton
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemoveEntryConfirmation(BuildContext context) async {
    HapticFeedback.heavyImpact();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Remove Entry?',
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

    if (result == true && onRemoveEntry != null) {
      onRemoveEntry!();
    }
  }

  // Add options menu to player info section
  Widget _buildOptionsMenu(BuildContext context, bool isPlayerSettled) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: AppSizes.iconM.dp,
      ),
      onSelected: (String choice) {
        if (choice == 'remove') {
          _showRemoveEntryConfirmation(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'remove',
          enabled: !isPlayerSettled && player.buyIns > 0,
          child: Row(
            children: [
              Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: AppSizes.iconM.dp,
              ),
              SizedBox(width: 8.dp),
              Text(
                'Remove Entry',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: AppSizes.fontM.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showReEntryConfirmation(BuildContext context) async {
    HapticFeedback.heavyImpact(); // Add haptic feedback

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
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
            children: [
              const TextSpan(
                text: 'Add another buy-in for ',
              ),
              TextSpan(
                text: player.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                text: ' with amount ',
              ),
              TextSpan(
                text: '\$${buyInAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                text: '?',
              ),
            ],
          ),
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
      onReEntry!();
    }
  }

// Update _buildActionButton to handle constrained space
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool isDisabled = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.dp),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isDisabled
            ? null
            : () {
                HapticFeedback.lightImpact();
                if (onPressed != null) {
                  onPressed();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey[800] : color,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: Colors.grey[800],
          padding: EdgeInsets.symmetric(
            vertical: 12.dp,
            horizontal: 4.dp,
          ),
          elevation: isDisabled ? 0 : 4,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.dp),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.dp,
              ),
              SizedBox(width: 4.dp),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.dp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLoanDialog(BuildContext context) async {
    String? selectedRecipientId;
    final amountController = TextEditingController();

    // Get all players except the current player (lender)
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
        // Use StatefulBuilder for dropdown
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
              // Recipient Dropdown
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
              // Amount Input
              CustomTextField(
                controller: amountController,
                label: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money,
                fontSize: AppSizes.fontL.sp,
                prefixIconSize: AppSizes.iconM.dp,
                style: const TextStyle(
                  // Add this
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
      // We need to modify PlayerCard's onLoan type to handle both recipientId and amount
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
                // Add this
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
