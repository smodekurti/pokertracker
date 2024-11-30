import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:poker_tracker/features/game/data/models/game.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/settlement_state.dart';
import 'package:poker_tracker/features/game/presentation/widgets/game_info_card.dart';
import 'package:poker_tracker/features/game/presentation/widgets/player_card.dart';
import 'package:poker_tracker/features/game/presentation/widgets/settlement_dialog.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/shared/widgets/loading_overlay.dart';

class ActiveGameScreen extends StatefulWidget {
  final String gameId;

  const ActiveGameScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class PlayerSettlementDisplay {
  final String name;
  final double totalBuyIn;
  final double cashOut;
  final double netPosition;

  PlayerSettlementDisplay({
    required this.name,
    required this.totalBuyIn,
    required this.cashOut,
    required this.netPosition,
  });
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? selectedPlayerId;
  double loanAmount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeGame();
      }
    });
  }

  Future<void> _initializeGame() async {
    if (_isInitialized) return;

    try {
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      await context.read<GameProvider>().loadGame(widget.gameId);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorSnackbar(context, 'Failed to load game: ${e.toString()}');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isProcessing) return false;

    final game = context.read<GameProvider>().currentGame;
    if (game == null) return true;

    if (game.isPotBalanced) {
      await _showFinalSettlementSummary(game);
      return false;
    }

    final result = await _showExitConfirmation();
    if (result == true && mounted) {
      context.go('/');
    }
    return false;
  }

  Future<void> _showFinalSettlementSummary(Game game) async {
    final settlements = game.players.map((player) {
      final totalBuyIn = player.calculateTotalIn(game.buyInAmount);
      final cashOut = player.cashOut ?? 0.0;
      final netPosition = cashOut - totalBuyIn;
      return PlayerSettlementDisplay(
        name: player.name,
        totalBuyIn: totalBuyIn,
        cashOut: cashOut,
        netPosition: netPosition,
      );
    }).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Final Settlement Summary',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font2XL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalPotInfo(game),
              SizedBox(height: AppSizes.spacingL.dp),
              ...settlements
                  .map((settlement) => _buildSettlementItem(settlement)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL.dp,
              ),
            ),
            child: Text(
              'Exit Game',
              style: TextStyle(fontSize: AppSizes.fontM.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPotInfo(Game game) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM.dp),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: AppColors.info,
            size: AppSizes.iconM.dp,
          ),
          SizedBox(width: AppSizes.spacingS.dp),
          Text(
            'Total Pot: \$${game.totalPot.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontL.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementItem(PlayerSettlementDisplay settlement) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spacingS.dp),
      padding: EdgeInsets.all(AppSizes.paddingM.dp),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settlement.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          SizedBox(height: AppSizes.spacingXS.dp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Buy-in: \$${settlement.totalBuyIn.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontS.sp,
                ),
              ),
              Text(
                'Cash-out: \$${settlement.cashOut.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontS.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacingXS.dp),
          _buildNetPosition(settlement.netPosition),
        ],
      ),
    );
  }

  Widget _buildNetPosition(double netPosition) {
    final isPositive = netPosition > 0;
    final color = isPositive
        ? AppColors.success
        : (netPosition < 0 ? AppColors.error : AppColors.textPrimary);

    return Text(
      'Net: ${netPosition >= 0 ? '+' : ''}\$${netPosition.toStringAsFixed(2)}',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: AppSizes.fontM.sp,
      ),
    );
  }

  Future<bool?> _showExitConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Leave Game?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font2XL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This game is not fully settled. Are you sure you want to return to home screen?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontM.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Stay',
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
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                ),
              ),
              child: Text(
                'Leave',
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.textPrimary,
              size: AppSizes.iconM.dp,
            ),
            SizedBox(width: AppSizes.spacingS.dp),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(AppSizes.paddingL.dp),
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL.dp,
          vertical: AppSizes.paddingM.dp,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.textPrimary,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Calculates the new total after updating a player's settlement amount

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final game = gameProvider.currentGame;
          final isLoading = gameProvider.isLoading;
          final error = gameProvider.error;

          if (!_isInitialized || game == null) {
            return _buildLoadingScreen();
          }

          if (error != null) {
            return _buildErrorScreen(error);
          }

          final isPotBalanced = game.isPotBalanced;

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: SafeArea(
                child: LoadingOverlay(
                  isLoading: isLoading || _isProcessing,
                  child: Column(
                    children: [
                      _buildHeader(
                        game.name,
                        showBackButton: true,
                        onBack: _onWillPop,
                        actions: [
                          if (isPotBalanced && !_isProcessing)
                            IconButton(
                              icon: Icon(
                                Icons.calculate,
                                color: AppColors.textPrimary,
                                size: AppSizes.iconM.dp,
                              ),
                              onPressed: _showSettlementDialog,
                              tooltip: 'View Settlements',
                            ),
                          if (!_isProcessing)
                            Padding(
                              padding:
                                  EdgeInsets.only(right: AppSizes.paddingM.dp),
                              child: ElevatedButton.icon(
                                onPressed: _showAddPlayerDialog,
                                icon: Icon(
                                  Icons.person_add,
                                  size: AppSizes.iconM.dp,
                                  color: Colors.black,
                                ),
                                label: Text(
                                  'Add Player',
                                  style: TextStyle(fontSize: AppSizes.fontM.sp),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusM.dp),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _buildGameInfoSection(game),
                            Expanded(
                              child: game.players.isEmpty
                                  ? _buildEmptyState()
                                  : _buildPlayerList(game, gameProvider),
                            ),
                            if (game.players.isNotEmpty)
                              _buildBottomActions(isPotBalanced),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddPlayerDialog() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Add Player',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font2XL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter player name',
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontL.sp,
          ),
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
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        setState(() => _isProcessing = true);
        final gameProvider = context.read<GameProvider>();
        final game = gameProvider.currentGame;
        if (game == null) return;

        String playerName = result;
        int reentryCount = 1;

        // Check if the player name already exists and append "Reentry" postfix
        while (game.players.any((player) => player.name == playerName)) {
          playerName = '$result Reentry ${reentryCount++}';
        }

        final newPlayer = Player(
          id: const Uuid().v4(),
          name: playerName,
          buyIns: 1,
          loans: 0,
          cashOut: null,
          isSettled: false,
        );

        await gameProvider.addPlayer(newPlayer);
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  void _showSettlementDialog() {
    if (_isProcessing) return;

    final game = context.read<GameProvider>().currentGame;
    if (game == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Settlement Overview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font2XL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettlementSummary(game),
              SizedBox(height: AppSizes.spacingL.dp),
              _buildPlayerSettlements(game),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
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
              onPressed: _isProcessing
                  ? null
                  : () {
                      Navigator.pop(context);
                      _handleEndGame();
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                ),
              ),
              child: Text(
                'End Game',
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementSummary(Game game) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM.dp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
              Text(
                'Total Pot:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontM.sp,
                ),
              ),
              Text(
                '\$${game.totalPot.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontL.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSettlements(Game game) {
    return Column(
      children: game.players.map((player) {
        final totalBuyIn = player.calculateTotalIn(game.buyInAmount);
        final cashOut = player.cashOut ?? 0.0;
        final netPosition = cashOut - totalBuyIn;

        return Container(
          margin: EdgeInsets.only(bottom: AppSizes.spacingS.dp),
          padding: EdgeInsets.all(AppSizes.paddingM.dp),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontL.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.spacingXS.dp),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy-in: \$${totalBuyIn.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.fontM.sp,
                        ),
                      ),
                      Text(
                        'Cash-out: \$${cashOut.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.fontM.sp,
                        ),
                      ),
                    ],
                  ),
                  _buildNetPositionBadge(netPosition),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNetPositionBadge(double netPosition) {
    final isPositive = netPosition > 0;
    final isNegative = netPosition < 0;
    final backgroundColor = isPositive
        ? AppColors.success.withOpacity(0.2)
        : (isNegative ? AppColors.error.withOpacity(0.2) : Colors.grey[800]);
    final textColor = isPositive
        ? AppColors.success
        : (isNegative ? AppColors.error : AppColors.textPrimary);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM.dp,
        vertical: AppSizes.paddingXS.dp,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
      ),
      child: Text(
        '${netPosition >= 0 ? '+' : ''}\$${netPosition.toStringAsFixed(2)}',
        style: TextStyle(
          color: textColor,
          fontSize: AppSizes.fontM.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader(
    String title, {
    bool showBackButton = false,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          padding: EdgeInsets.all(AppSizes.paddingL.dp),
          child: Column(
            children: [
              Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      onPressed: onBack,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.textPrimary,
                        size: AppSizes.iconS.dp,
                      ),
                      tooltip: 'Return to Home',
                    ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ).createShader(bounds),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: AppSizes.font2XL.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(
                'Loading Game...',
                showBackButton: true,
                onBack: () => context.go('/'),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: AppSizes.iconXL.dp,
                        height: AppSizes.iconXL.dp,
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.secondary),
                          strokeWidth: 3.dp,
                        ),
                      ),
                      SizedBox(height: AppSizes.spacingL.dp),
                      Text(
                        'Loading game details...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.fontL.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(
                'Error',
                showBackButton: true,
                onBack: () => context.go('/'),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.padding2XL.dp),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSizes.paddingL.dp),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusXL.dp),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                              width: 1.dp,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: AppSizes.iconXL.dp,
                              ),
                              SizedBox(height: AppSizes.spacingL.dp),
                              Text(
                                error,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: AppSizes.fontL.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSizes.spacing2XL.dp),
                        ElevatedButton.icon(
                          onPressed: _initializeGame,
                          icon: Icon(
                            Icons.refresh,
                            size: AppSizes.iconM.dp,
                          ),
                          label: Text(
                            'Try Again',
                            style: TextStyle(fontSize: AppSizes.fontL.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingXL.dp,
                              vertical: AppSizes.paddingM.dp,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusL.dp),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSizes.spacingM.dp),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: Icon(
                            Icons.home,
                            size: AppSizes.iconM.dp,
                          ),
                          label: Text(
                            'Return Home',
                            style: TextStyle(fontSize: AppSizes.fontL.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingXL.dp,
                              vertical: AppSizes.paddingM.dp,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusL.dp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: AppSizes.iconXL.dp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSizes.spacingL.dp),
          Text(
            'No Players Yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.font2XL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.spacingS.dp),
          Text(
            'Add players to start the game',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontL.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(Game game, GameProvider gameProvider) {
    return ChangeNotifierProvider(
      create: (context) => SettlementState(
        settlements: {
          for (var player in game.players) player.id: player.cashOut ?? 0.0
        },
        totalPot: game.totalPot,
      ),
      child: Consumer<SettlementState>(
        // Add Consumer for settlement state
        builder: (context, settlementState, child) {
          return ListView.builder(
            padding: EdgeInsets.all(AppSizes.paddingL.dp),
            itemCount: game.players.length,
            itemBuilder: (context, index) {
              final player = game.players[index];
              return PlayerCard(
                player: player,
                buyInAmount: game.buyInAmount,
                onReEntry: _isProcessing
                    ? null
                    : () {
                        setState(() => _isProcessing = true);
                        gameProvider.handleReEntry(player.id).then((_) {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                            // Update settlement state after re-entry
                            settlementState.updateSettlement(
                              player.id,
                              player.cashOut ?? 0.0,
                              isSettled: player.isSettled,
                            );
                          }
                        }).catchError((e) {
                          if (mounted) {
                            _showErrorSnackbar(context, e.toString());
                            setState(() => _isProcessing = false);
                          }
                        });
                      },
                onLoan: _isProcessing
                    ? null
                    : (recipientId, amount) async {
                        try {
                          setState(() => _isProcessing = true);
                          await gameProvider.handleLoan(
                            lenderId: player.id,
                            recipientId: recipientId,
                            amount: amount,
                          );

                          // Update settlement states for both players after loan
                          if (mounted) {
                            final lender = game.players
                                .firstWhere((p) => p.id == player.id);
                            final recipient = game.players
                                .firstWhere((p) => p.id == recipientId);

                            settlementState.updateSettlement(
                              lender.id,
                              lender.cashOut ?? 0.0,
                              isSettled: lender.isSettled,
                            );

                            settlementState.updateSettlement(
                              recipient.id,
                              recipient.cashOut ?? 0.0,
                              isSettled: recipient.isSettled,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Loan processed successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            _showErrorSnackbar(context, e.toString());
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                          }
                        }
                      },
                onSettle: _isProcessing
                    ? null
                    : (amount) async {
                        try {
                          setState(() => _isProcessing = true);

                          // Update settlement state first
                          settlementState.updateSettlement(
                            player.id,
                            amount,
                            isSettled: true,
                          );

                          // Then update game state
                          await gameProvider.settlePlayer(player.id, amount);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Player settled successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            // Revert settlement state on error
                            settlementState.updateSettlement(
                              player.id,
                              player.cashOut ?? 0.0,
                              isSettled: false,
                            );
                            _showErrorSnackbar(context, e.toString());
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                          }
                        }
                      },
                isSettled: settlementState
                    .isPlayerSettled(player.id), // Use settlement state
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomActions(bool isPotBalanced) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingL.dp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _handleUniversalSettle,
            icon: Icon(
              isPotBalanced ? Icons.edit : Icons.done_all,
              size: AppSizes.iconM.dp,
              color: Colors.black,
            ),
            label: Text(
              isPotBalanced ? 'Modify Settlements' : 'Settle All Players',
              style: TextStyle(
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: AppSizes.paddingM.dp,
              ),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              ),
            ),
          ),
          if (isPotBalanced)
            Padding(
              padding: EdgeInsets.only(top: AppSizes.paddingL.dp),
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleEndGame,
                icon: Icon(
                  Icons.check_circle,
                  size: AppSizes.iconM.dp,
                ),
                label: Text(
                  'End Game',
                  style: TextStyle(
                    fontSize: AppSizes.fontL.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.paddingM.dp,
                  ),
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleEndGame() async {
    if (_isProcessing) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'End Game',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font2XL.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to end the game?\nAll settlements have been verified.',
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
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                ),
              ),
              child: Text(
                'End Game',
                style: TextStyle(fontSize: AppSizes.fontM.sp),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        final gameProvider = context.read<GameProvider>();
        final game = gameProvider.currentGame;
        if (game == null) return;

        await gameProvider.endGame();
        await gameProvider.refreshGames();
        if (mounted) {
          context.go('/game/${game.id}/settlement', extra: game);
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackbar(context, e.toString());
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _handleUniversalSettle() async {
    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
          ),
          title: Text(
            'Settle All Players',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.font2XL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withOpacity(0.1),
                  AppColors.info.withOpacity(0.05),
                ],
              ),
            ),
            padding: EdgeInsets.all(AppSizes.paddingL.dp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter cash-out amounts for all players. You can adjust amounts until the total matches the pot.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontM.sp,
                  ),
                ),
                SizedBox(height: AppSizes.spacingS.dp),
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.info,
                  size: AppSizes.iconM.dp,
                ),
              ],
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
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL.dp,
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: AppSizes.fontM.sp),
                ),
              ),
            ),
          ],
        ),
      );

      if (result != true || !mounted) return;

      final gameProvider = context.read<GameProvider>();
      final game = gameProvider.currentGame;
      if (game == null) return;

      final settlementState = SettlementState(
        settlements: {
          for (var player in game.players) player.id: player.cashOut ?? 0
        },
        totalPot: game.totalPot,
      );

      await _showSettlementFlow(game, settlementState);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildGameInfoSection(Game game) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL.dp,
        vertical: AppSizes.paddingS.dp,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.dp,
            offset: Offset(0, 4.dp),
          ),
        ],
      ),
      child: GameInfoCard(game: game),
    );
  }

  Future<void> _showSettlementFlow(Game game, SettlementState state) async {
    int currentIndex = 0;

    while (true) {
      if (!mounted) return;

      final player = game.players[currentIndex];
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async {
            if (!state.isTallied) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
                  ),
                  title: Text(
                    'Exit Settlement?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.font2XL.sp,
                    ),
                  ),
                  content: Text(
                    'Settlements have not been finalized. You can continue later.\nDo you want to exit?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontM.sp,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Continue Settling',
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
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusM.dp),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingL.dp,
                          ),
                        ),
                        child: Text(
                          'Exit',
                          style: TextStyle(fontSize: AppSizes.fontM.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                Navigator.pop(context);
              }
            } else {
              Navigator.pop(context);
            }
            return false;
          },
          child: SettlementDialog(
              player: player,
              buyInAmount: game.buyInAmount,
              playerName: player.name,
              currentIndex: currentIndex,
              totalPlayers: game.players.length,
              state: state,
              initialAmount: state.settlements[player.id] ?? 0,
              recommendedAmount: _calculateRecommendedAmount(state, player.id),
              isLastPlayer: currentIndex == game.players.length - 1,
              playerId: player.id),
        ),
      );

      if (result == null) {
        if (!state.isTallied) {
          final confirmExit = await _showExitConfirmation();
          if (confirmExit == true) return;
          continue;
        }
        return;
      }

      switch (result['action']) {
        case 'prev':
          currentIndex = (currentIndex - 1).clamp(0, game.players.length - 1);
          break;
        case 'save':
          state.settlements[player.id] = result['amount'];
          try {
            await context.read<GameProvider>().settlePlayer(
                  player.id,
                  result['amount'],
                );
            if (currentIndex < game.players.length - 1) {
              currentIndex++;
            }
          } catch (e) {
            if (!mounted) return;
            _showErrorSnackbar(context, e.toString());
          }
          break;
        case 'finalize':
          if (state.isBalanced()) {
            if (!state.isPlayerSettled(player.id)) {
              state.settlements[player.id] = result['amount'];
              try {
                await context.read<GameProvider>().settlePlayer(
                      player.id,
                      result['amount'],
                    );
                if (currentIndex < game.players.length - 1) {
                  currentIndex++;
                }
              } catch (e) {
                if (!mounted) return;
                _showErrorSnackbar(context, e.toString());
              }
            }
            state.finalSettlement = true;
            if (mounted) {
              final gameProvider = context.read<GameProvider>();
              final finalizedGame = await gameProvider.settleAllAndEnd();
              await gameProvider.refreshGames();
              if (mounted) {
                // Use the finalized game state for navigation
                context.go('/game/${finalizedGame.id}/settlement',
                    extra: finalizedGame);
              }
            }
            return;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Winners and losers must balance before settling',
                    style: TextStyle(fontSize: AppSizes.fontM.sp),
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(AppSizes.paddingL.dp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
                  ),
                ),
              );
            }
          }
          break;
      }
    }
  }

  double _calculateRecommendedAmount(SettlementState state, String playerId) {
    final currentTotal =
        state.totalSettled - (state.settlements[playerId] ?? 0.0);
    return state.totalPot - currentTotal;
  }
}
