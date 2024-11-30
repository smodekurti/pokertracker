import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/presentation/top_notification.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/shared/widgets/custom_text_field.dart';
import 'package:poker_tracker/shared/widgets/loading_overlay.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameNameController = TextEditingController();
  final _buyInController = TextEditingController(text: '20');
  final _playerNameController = TextEditingController();
  final List<Player> _players = [];
  String? _playerNameError;
  String? _gameNameError;
  String? _buyInError;
  final _cutPercentageController = TextEditingController(text: '0');
  String? _cutPercentageError;

  @override
  void dispose() {
    _gameNameController.dispose();
    _buyInController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_players.isEmpty && _gameNameController.text.trim().isEmpty) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL.dp),
        ),
        title: Text(
          'Cancel Game Setup?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontL.sp,
          ),
        ),
        content: Text(
          'All entered information will be lost. Are you sure you want to cancel?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontM.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, Continue Setup',
              style: TextStyle(
                color: AppColors.info,
                fontSize: AppSizes.fontM.sp,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(fontSize: AppSizes.fontM.sp),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ... existing methods remain the same ...

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isLoading = context.watch<GameProvider>().isLoading;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                // Floating Header
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      padding: EdgeInsets.all(AppSizes.paddingL.dp),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  if (await _onWillPop()) {
                                    if (mounted) context.go('/');
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: AppColors.textPrimary,
                                  size: AppSizes.iconS.dp,
                                ),
                                tooltip: 'Cancel Game Setup',
                              ),
                              Expanded(
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                  ).createShader(bounds),
                                  child: Text(
                                    'New Game Setup',
                                    style: TextStyle(
                                      fontSize: AppSizes.fontM.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
                Expanded(
                  child: LoadingOverlay(
                    isLoading: isLoading,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: EdgeInsets.all(AppSizes.paddingL.dp),
                        children: [
                          _buildGameDetailsSection(),
                          SizedBox(height: AppSizes.spacing2XL.dp),
                          _buildPlayersSection(),
                          SizedBox(height: AppSizes.spacing2XL.dp),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameDetailsSection() {
    return Container(
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
      padding: EdgeInsets.all(AppSizes.paddingL.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Details',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.spacingL.dp),
          Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: AppColors.textPrimary,
                    displayColor: AppColors.textPrimary,
                  ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[850],
                labelStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontM.sp,
                ),
                prefixIconColor: AppColors.textSecondary,
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
                  borderSide: BorderSide(color: AppColors.secondary),
                ),
              ),
            ),
            child: Column(
              children: [
                CustomTextField(
                  label: 'Game Name',
                  controller: _gameNameController,
                  errorText: _gameNameError,
                  prefixIcon: Icons.casino_rounded,
                  prefixIconSize: AppSizes.iconM.dp,
                  fontSize: AppSizes.fontL.sp,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => _gameNameError = null),
                ),
                SizedBox(height: AppSizes.spacingL.dp),
                CustomTextField(
                  label: 'Buy-in Amount',
                  controller: _buyInController,
                  errorText: _buyInError,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money,
                  prefixIconSize: AppSizes.iconM.dp,
                  fontSize: AppSizes.fontL.sp,
                  onChanged: (_) => setState(() => _buyInError = null),
                ),
                SizedBox(height: AppSizes.spacingL.dp),
                CustomTextField(
                  label: 'Pot Cut Percentage',
                  controller: _cutPercentageController,
                  errorText: _cutPercentageError,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.percent,
                  prefixIconSize: AppSizes.iconM.dp,
                  fontSize: AppSizes.fontL.sp,
                  onChanged: (_) => setState(() => _cutPercentageError = null),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

// ... previous code remains same ...

  Widget _buildPlayersSection() {
    return Container(
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
      padding: EdgeInsets.all(AppSizes.paddingL.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Players',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontXL.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM.dp,
                  vertical: AppSizes.paddingXS.dp,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                ),
                child: Text(
                  '${_players.length} ${_players.length == 1 ? 'player' : 'players'}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.fontM.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacingL.dp),
          Row(
            children: [
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.apply(
                          bodyColor: AppColors.textPrimary,
                          displayColor: AppColors.textPrimary,
                        ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.grey[850],
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontM.sp,
                      ),
                      prefixIconColor: AppColors.textSecondary,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusL.dp),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusL.dp),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusL.dp),
                        borderSide: BorderSide(color: AppColors.secondary),
                      ),
                    ),
                  ),
                  child: CustomTextField(
                    label: 'Player Name',
                    controller: _playerNameController,
                    errorText: _playerNameError,
                    prefixIcon: Icons.person,
                    prefixIconSize: AppSizes.iconM.dp,
                    fontSize: AppSizes.fontL.sp,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addPlayer(),
                    onChanged: (_) => setState(() => _playerNameError = null),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.spacingS.dp),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                ),
                child: IconButton(
                  onPressed: _addPlayer,
                  icon: Icon(
                    Icons.add,
                    size: AppSizes.iconM.dp,
                  ),
                  color: AppColors.textPrimary,
                  tooltip: 'Add Player',
                ),
              ),
            ],
          ),
          if (_players.isNotEmpty) SizedBox(height: AppSizes.spacingL.dp),
          ..._buildPlayersList(),
        ],
      ),
    );
  }

  List<Widget> _buildPlayersList() {
    return _players.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      return Container(
        margin: EdgeInsets.only(bottom: AppSizes.spacingS.dp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.info.withOpacity(0.1),
              AppColors.info.withOpacity(0.05),
            ],
          ),
        ),
        child: ListTile(
          leading: Container(
            width: AppSizes.iconXL.dp,
            height: AppSizes.iconXL.dp,
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
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.fontL.sp,
                ),
              ),
            ),
          ),
          title: Text(
            player.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: AppSizes.fontL.sp,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              color: AppColors.error,
              size: AppSizes.iconM.dp,
            ),
            tooltip: 'Remove Player',
            onPressed: () {
              setState(() {
                _players.removeAt(index);
              });
            },
          ),
        ),
      );
    }).toList();
  }

  void _addPlayer() {
    final name = _playerNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _playerNameError = 'Player name is required';
      });
      return;
    }

    if (_players
        .any((player) => player.name.toLowerCase() == name.toLowerCase())) {
      setState(() {
        _playerNameError = 'Player name must be unique';
      });

      TopNotification.show(
        context,
        message: 'Player name must be unique',
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      _players.add(Player(
        id: const Uuid().v4(),
        name: name,
      ));
      _playerNameController.clear();
      _playerNameError = null;
    });

    // Show success notification at the top
    if (mounted) {
      TopNotification.show(
        context,
        message: 'Player "$name" added successfully',
        type: NotificationType.success,
        icon: Icons.person_add,
      );
    }
  }

  Widget _buildActionButtons() {
    if (_players.length >= 2) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                if (await _onWillPop()) {
                  if (mounted) context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                  vertical: AppSizes.paddingM.dp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                  side: BorderSide(
                    color: AppColors.primary,
                    width: 2.dp,
                  ),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: AppSizes.fontL.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSizes.spacingL.dp),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: 8.dp,
                    offset: Offset(0, 2.dp),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL.dp,
                    vertical: AppSizes.paddingM.dp,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: AppSizes.iconM.dp,
                    ),
                    SizedBox(width: AppSizes.spacingS.dp),
                    Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: AppSizes.fontL.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(AppSizes.paddingL.dp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[900]!.withOpacity(0.3),
            Colors.green[600]!.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: AppSizes.iconM.dp,
              ),
              SizedBox(width: AppSizes.paddingM.dp),
              Expanded(
                child: Text(
                  'Add at least ${2 - _players.length} more player${2 - _players.length > 1 ? 's' : ''} to start',
                  style: TextStyle(
                    color: Colors.orange[100],
                    fontSize: AppSizes.fontM.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacingL.dp),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (await _onWillPop()) {
                  if (mounted) context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL.dp,
                  vertical: AppSizes.paddingM.dp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                  side: BorderSide(
                    color: AppColors.primary,
                    width: 2.dp,
                  ),
                ),
              ),
              child: Text(
                'Cancel Setup',
                style: TextStyle(
                  fontSize: AppSizes.fontL.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startGame() async {
    final gameName = _gameNameController.text.trim();
    if (gameName.isEmpty) {
      setState(() {
        _gameNameError = 'Game name is required';
      });
      return;
    }

    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'At least 2 players are required',
            style: TextStyle(
              fontSize: AppSizes.fontM.sp,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(AppSizes.paddingL.dp),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          ),
        ),
      );
      return;
    }

    try {
      final buyInAmount = double.tryParse(_buyInController.text);
      if (buyInAmount == null || buyInAmount <= 0) {
        setState(() {
          _buyInError = 'Invalid buy-in amount';
        });
        return;
      }

      final cutPercentage = double.tryParse(_cutPercentageController.text);
      if (cutPercentage == null || cutPercentage < 0 || cutPercentage > 100) {
        setState(() {
          _cutPercentageError = 'Invalid cut percentage';
        });
        return;
      }

      // Show loading indicator while creating game
      final gameProvider = context.read<GameProvider>();
      await gameProvider.createGame(
        gameName,
        buyInAmount,
        _players,
        cutPercentage,
      );

      final game = gameProvider.currentGame;
      if (game != null && mounted) {
        TopNotification.show(
          context,
          message: 'Game "${game.name}" created successfully',
          type: NotificationType.success,
          icon: Icons.person_add,
        );

        // Navigate to game screen
        context.go('/game/${game.id}');
      } else {
        throw Exception('Failed to create game');
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message
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
                  'Failed to create game: ${e.toString()}',
                  style: TextStyle(
                    fontSize: AppSizes.fontM.sp,
                    color: AppColors.textPrimary,
                  ),
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
        ),
      );
    }
  }
}

  // Update the build method accordingly

