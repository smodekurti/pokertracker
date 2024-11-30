import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';

class GameInfoCard extends StatelessWidget {
  final Game game;

  const GameInfoCard({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Container(
      padding: EdgeInsets.all(AppSizes.paddingL.dp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoColumn(
            'Players',
            '${game.players.length}',
            Icons.group,
            AppColors.info,
          ),
          Container(
            width: 1.dp,
            height: 40.dp,
            color: Colors.grey[700],
          ),
          _buildInfoColumn(
            'Buy-in',
            '\$${game.buyInAmount.toStringAsFixed(2)}',
            Icons.monetization_on,
            AppColors.success,
          ),
          Container(
            width: 1.dp,
            height: 40.dp,
            color: Colors.grey[700],
          ),
          _buildInfoColumn(
            'Total Pot',
            '\$${game.totalPot.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.paddingM.dp),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: AppSizes.iconM.dp,
          ),
        ),
        SizedBox(height: AppSizes.spacingS.dp),
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
            fontSize: AppSizes.fontL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
