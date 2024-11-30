import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
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
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Game',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${game.name}"?\nThis action cannot be undone.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14.sp,
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
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final gameProvider = context.read<GameProvider>();
        await gameProvider.deleteGame(game.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Game deleted successfully',
                style: TextStyle(fontSize: 14.sp),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
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
                style: TextStyle(fontSize: 14.sp),
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Delete Game',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${game.name}"?\nThis action cannot be undone.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
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
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _handleDelete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red[700]!.withOpacity(0.8),
              Colors.red[900]!.withOpacity(0.9),
            ],
          ),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
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
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: () => context.go('/game/${game.id}'),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
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
                                colors: [Color(0xFF4ade80), Color(0xFF3b82f6)],
                              ).createShader(bounds),
                              child: Text(
                                game.name,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              DateFormat('MMM dd, yyyy – hh:mm a')
                                  .format(game.date),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14.sp,
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
                              size: 24.sp,
                            ),
                            onPressed: () => _handleDelete(context),
                            tooltip: 'Delete Game',
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ade80), Color(0xFF3b82f6)],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Text(
                              '\$${game.totalPot.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.blue.withOpacity(0.1),
                          Colors.blue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
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
                                  size: 20.sp,
                                  color: Colors.blue[400],
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '$settledPlayers/$totalPlayers players settled',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${settledPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: settledPercentage / 100,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              settledPercentage == 100
                                  ? Colors.green[400]!
                                  : Colors.blue[400]!,
                            ),
                            minHeight: 6.h,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 20.sp,
                            color: Colors.green[400],
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Buy-in: \$${game.buyInAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: Colors.grey[600],
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
