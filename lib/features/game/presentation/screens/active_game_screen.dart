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

        final baseName = result; // Store original name

        // Check if this name exists in the game
        final existingEntries = game.players
            .where((player) => player.name.startsWith(baseName))
            .toList();

        if (existingEntries.isNotEmpty && !existingEntries.last.isSettled) {
          // If latest entry is not settled, show error
          if (mounted) {
            _showErrorSnackbar(
              context,
              'This player has an active unsettled entry',
            );
          }
          return;
        }

        // Create new entry with incremented count
        final entryCount = existingEntries.length + 1;
        final playerName =
            entryCount > 1 ? '$baseName (Entry $entryCount)' : baseName;

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
    // Group players by base name (name without entry number)
    final Map<String, List<Player>> playerGroups = {};

    for (var player in game.players) {
      final baseName = player.name.split(' (Entry').first;
      if (!playerGroups.containsKey(baseName)) {
        playerGroups[baseName] = [];
      }
      playerGroups[baseName]!.add(player);
    }

    // Calculate consolidated settlements
    final settlements = playerGroups.entries.map((entry) {
      final players = entry.value;
      final totalBuyIn = players.fold<double>(
        0,
        (sum, player) => sum + player.calculateTotalIn(game.buyInAmount),
      );
      final totalCashOut = players.fold<double>(
        0,
        (sum, player) => sum + (player.cashOut ?? 0.0),
      );
      final netPosition = totalCashOut - totalBuyIn;

      final displayName = players.length > 1
          ? '${entry.key} (${players.length} entries)'
          : entry.key;

      return PlayerSettlementDisplay(
        name: displayName,
        totalBuyIn: totalBuyIn,
        cashOut: totalCashOut,
        netPosition: netPosition,
      );
    }).toList();

    // Sort by net position (highest to lowest)
    settlements.sort((a, b) => b.netPosition.compareTo(a.netPosition));

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
                    'Total Buy-in: \$${settlement.totalBuyIn.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontM.sp,
                    ),
                  ),
                  Text(
                    'Total Cash-out: \$${settlement.cashOut.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontM.sp,
                    ),
                  ),
                ],
              ),
              _buildNetPositionBadge(settlement.netPosition),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetPositionBadge(double netPosition) {
    final isPositive = netPosition > 0;
    final backgroundColor = isPositive
        ? AppColors.success.withOpacity(0.2)
        : (netPosition < 0
            ? AppColors.error.withOpacity(0.2)
            : Colors.grey[800]);
    final textColor = isPositive
        ? AppColors.success
        : (netPosition < 0 ? AppColors.error : AppColors.textPrimary);

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

  Widget _buildPlayerList(Game game, GameProvider gameProvider) {
    // Create initial settlements map
    final initialSettlements = {
      for (var player in game.players) player.id: player.cashOut ?? 0.0
    };

    return ChangeNotifierProvider(
      create: (context) {
        final settlementState = SettlementState(
          settlements: initialSettlements,
          totalPot: game.totalPot,
        );

        // Initialize each player's settlement state
        for (var player in game.players) {
          settlementState.updateSettlement(
            player.id,
            player.cashOut ?? 0.0,
            isSettled: player.isSettled,
          );
        }

        return settlementState;
      },
      child: Consumer<SettlementState>(
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
                            _showErrorSnackbar(context, e.toString());
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                          }
                        }
                      },
                isSettled: settlementState.isPlayerSettled(player.id),
              );
            },
          );
        },
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

  Future<void> _handleUniversalSettle() async {
    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      final gameProvider = context.read<GameProvider>();
      final game = gameProvider.currentGame;
      if (game == null) return;

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

      await _showSettlementFlow(game);
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
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (error != null) {
            return Scaffold(
              body: Center(
                child: Text('Error: $error'),
              ),
            );
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
                      _buildHeader(game.name),
                      Expanded(
                        child: Column(
                          children: [
                            GameInfoCard(game: game),
                            Expanded(
                              child: game.players.isEmpty
                                  ? const Center(
                                      child: Text('No players yet'),
                                    )
                                  : _buildPlayerList(game, gameProvider),
                            ),
                            if (game.players.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.all(AppSizes.paddingM.dp),
                                child: ElevatedButton(
                                  onPressed: _handleUniversalSettle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSizes.paddingM.dp,
                                    ),
                                    minimumSize: Size(double.infinity, 48.dp),
                                  ),
                                  child: Text(
                                    isPotBalanced
                                        ? 'Modify Settlements'
                                        : 'Settle All Players',
                                    style: TextStyle(
                                      fontSize: AppSizes.fontL.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              if (isPotBalanced)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSizes.paddingM.dp,
                                    vertical: AppSizes.paddingS.dp,
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        _isProcessing ? null : _handleEndGame,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSizes.paddingM.dp,
                                      ),
                                      minimumSize: Size(double.infinity, 48.dp),
                                    ),
                                    child: Text(
                                      'End Game',
                                      style: TextStyle(
                                        fontSize: AppSizes.fontL.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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

  Widget _buildHeader(String title) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM.dp),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onWillPop(),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.font2XL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettlementFlow(Game game) async {
    // Create initial settlements map
    final initialSettlements = {
      for (var player in game.players) player.id: player.cashOut ?? 0.0
    };

    // Create settlement state
    final settlementState = SettlementState(
      settlements: initialSettlements,
      totalPot: game.totalPot,
    );

    // Initialize settlement states with all players unsettled
    // Initialize settlement states by keeping the settled status from the game
    for (var player in game.players) {
      settlementState.updateSettlement(
        player.id,
        player.cashOut ?? 0.0,
        isSettled:
            player.isSettled, // Use the actual settled status from the game
      );
    }

    int currentIndex = 0;

    while (true) {
      if (!mounted) return;

      final player = game.players[currentIndex];
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async {
            if (settlementState.isTallied) {
              Navigator.pop(context);
              return false;
            }

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
            return false;
          },
          child: ChangeNotifierProvider.value(
            value: settlementState,
            child: SettlementDialog(
              player: player,
              buyInAmount: game.buyInAmount,
              playerName: player.name,
              currentIndex: currentIndex,
              totalPlayers: game.players.length,
              state: settlementState,
              initialAmount: settlementState.settlements[player.id] ?? 0.0,
              recommendedAmount: _calculateRecommendedAmount(
                settlementState,
                player.id,
              ),
              isLastPlayer: currentIndex == game.players.length - 1,
              playerId: player.id,
            ),
          ),
        ),
      );

      if (result == null) {
        if (!settlementState.isTallied) {
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
          try {
            final amount = result['amount'] as double;
            // Only update if player isn't already settled
            if (!player.isSettled) {
              settlementState.updateSettlement(
                player.id,
                amount,
                isSettled: false,
              );
            }

            if (currentIndex < game.players.length - 1) {
              currentIndex++;
            }
          } catch (e) {
            if (!mounted) return;
            _showErrorSnackbar(context, e.toString());
          }
          break;

        case 'finalize':
          if (settlementState.isBalanced()) {
            try {
              setState(() => _isProcessing = true);

              if (mounted) {
                final gameProvider = context.read<GameProvider>();

                // Update current player's amount in settlement state
                final currentAmount = result['amount'] as double;
                settlementState.updateSettlement(
                  player.id,
                  currentAmount,
                  isSettled: false,
                );

                // First settle all players in the database
                for (var p in game.players) {
                  final settledAmount =
                      settlementState.settlements[p.id] ?? 0.0;
                  await gameProvider.settlePlayer(p.id, settledAmount);
                }

                // Wait for all settlements to be processed
                await Future.delayed(const Duration(milliseconds: 100));

                // Reload game to verify settlements
                await gameProvider.loadGame(game.id);
                final updatedGame = gameProvider.currentGame;

                // Verify all players are settled with correct amounts
                if (updatedGame?.players.every((p) =>
                        p.isSettled &&
                        (p.cashOut == settlementState.settlements[p.id])) ??
                    false) {
                  // End the game
                  await gameProvider.endGame();
                  await gameProvider.refreshGames();

                  if (mounted) {
                    context.go('/game/${game.id}/settlement',
                        extra: updatedGame);
                  }
                } else {
                  throw Exception(
                      'Failed to verify settlements. Please try again.');
                }
              }
              return;
            } catch (e) {
              if (mounted) {
                setState(() => _isProcessing = false);
                _showErrorSnackbar(context, e.toString());
              }
              continue;
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Winners and losers must balance before finalizing',
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

  double _calculateRecommendedAmount(SettlementState state, String playerId) {
    final currentTotal =
        state.totalSettled - (state.settlements[playerId] ?? 0.0);
    return state.totalPot - currentTotal;
  }
}
