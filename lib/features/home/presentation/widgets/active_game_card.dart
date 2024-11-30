import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:intl/intl.dart';

class ActiveGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onDeleted;

  const ActiveGameCard({
    super.key,
    required this.game,
    this.onDeleted,
  });

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Delete Game',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontL.sp,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${game.name}"?\nThis action cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontM.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(fontSize: AppSizes.fontM.sp),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<GameProvider>().deleteGame(game.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Game deleted successfully',
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
              ),
            ),
          );
          onDeleted?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete game: ${e.toString()}',
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final settledPlayers = game.players.where((p) => p.isSettled).length;
    final totalPlayers = game.players.length;
    final settledPercentage =
        totalPlayers > 0 ? (settledPlayers / totalPlayers) * 100 : 0.0;

    return Dismissible(
      key: Key(game.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
          ),
          title: Text(
            'Delete Game',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontL.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${game.name}"?\nThis action cannot be undone.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontM.sp,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[400],
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _handleDelete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSizes.paddingXL.dp),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withOpacity(0.8),
              AppColors.error.withOpacity(0.9),
            ],
          ),
        ),
        child: Icon(
          Icons.delete,
          color: AppColors.textPrimary,
          size: AppSizes.iconL.dp,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.paddingM.dp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[850]!,
              Colors.grey[900]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8.dp,
              offset: Offset(0, 2.dp),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
          child: InkWell(
            onTap: () => context.go('/game/${game.id}'),
            borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingL.dp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: AppColors.primaryGradient,
                              ).createShader(bounds),
                              child: Text(
                                game.name,
                                style: TextStyle(
                                  fontSize: AppSizes.font2XL.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSizes.spacingXS.dp),
                            Text(
                              DateFormat('MMM dd, yyyy – hh:mm a')
                                  .format(game.date),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppSizes.fontM.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                              size: AppSizes.iconM.dp,
                            ),
                            onPressed: () => _handleDelete(context),
                            tooltip: 'Delete Game',
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingL.dp,
                              vertical: AppSizes.paddingS.dp,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.primaryGradient,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radius2XL.dp),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.2),
                                  blurRadius: 8.dp,
                                  offset: Offset(0, 2.dp),
                                ),
                              ],
                            ),
                            child: Text(
                              '\$${game.totalPot.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: AppSizes.fontL.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.paddingL.dp),
                  Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: AppSizes.iconM.dp,
                                  color: AppColors.info,
                                ),
                                SizedBox(width: AppSizes.spacingS.dp),
                                Text(
                                  '$settledPlayers/$totalPlayers players settled',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: AppSizes.fontM.sp,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${settledPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppSizes.fontM.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spacingS.dp),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusS.dp),
                          child: LinearProgressIndicator(
                            value: settledPercentage / 100,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              settledPercentage == 100
                                  ? AppColors.success
                                  : AppColors.info,
                            ),
                            minHeight: 6.dp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSizes.paddingM.dp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: AppSizes.iconM.dp,
                            color: AppColors.success,
                          ),
                          SizedBox(width: AppSizes.spacingS.dp),
                          Text(
                            'Buy-in: \$${game.buyInAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: AppSizes.fontM.sp,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: AppSizes.iconS.dp,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
