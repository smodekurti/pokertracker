import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/top_notification.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/providers/game_provider.dart';
import 'package:poker_tracker/features/team/data/team.dart';
import 'package:poker_tracker/features/team/providers/team_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _gameNameController = TextEditingController();
  final _buyInController = TextEditingController(text: '20');
  final _cutPercentageController = TextEditingController(text: '0');
  final Set<Team> _selectedTeams = {};
  final Set<Player> _selectedPlayers = {};
  final Set<Player> _players = {};
  final _playerNameController = TextEditingController();

  @override
  void dispose() {
    _gameNameController.dispose();
    _buyInController.dispose();
    _cutPercentageController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGameDetailsSection(),
                      const SizedBox(height: 32),
                      _buildPlayersSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildStartGameButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: AppColors.primaryGradient,
            ).createShader(bounds),
            child: const Text(
              'New Game Setup',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Game Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2232),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                label: 'Game Name',
                controller: _gameNameController,
                icon: Icons.casino,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Buy-in Amount',
                controller: _buyInController,
                icon: Icons.attach_money,
                prefix: '\$',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Cut Percentage',
                controller: _cutPercentageController,
                icon: Icons.percent,
                prefix: '',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? prefix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1120),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType ?? TextInputType.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            // Add input formatters for numeric fields
            inputFormatters: keyboardType == TextInputType.number
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ]
                : null,
            // Add validation on change
            onChanged: (value) {
              if (keyboardType == TextInputType.number) {
                if (value.isNotEmpty) {
                  try {
                    final number = double.parse(value);
                    if (label.contains('Cut')) {
                      // Validate cut percentage
                      if (number > 100) {
                        controller.text = '100';
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    }
                  } catch (_) {
                    // Reset to default if invalid
                    controller.text = label.contains('Cut') ? '0' : '20';
                  }
                }
              }
            },
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
              prefixText: prefix,
              prefixStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Players',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_players.length} players',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.person_add,
                label: 'Add Player',
                onTap: () => _showAddPlayerDialog(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.group_add,
                label: 'Import Team',
                onTap: () => _showTeamSelectionDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._players.map(_buildPlayerTile).toList(),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1A2232),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerTile(Player player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2232),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                player.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            player.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              color: Colors.red[400],
            ),
            onPressed: () => setState(() => _players.remove(player)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartGameButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _players.length >= 2 ? _startGame : null,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Start Game',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Add Player',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: _playerNameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Player Name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _addPlayer(_playerNameController.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showTeamSelectionDialog() {
    final currentContext = context;
    Team? selectedTeam;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: AppColors.backgroundMedium,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Team',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Builder(
                  builder: (builderContext) {
                    final teamProvider = currentContext.watch<TeamProvider?>();

                    if (teamProvider == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final teams = teamProvider.teams;

                    if (teams.isEmpty) {
                      return const Center(
                        child: Text(
                          'No teams available',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return StatefulBuilder(
                      builder: (context, setDialogState) {
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: teams.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final team = teams[index];
                                  final isSelected =
                                      selectedTeam?.id == team.id;

                                  return InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedTeam = team;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withOpacity(0.1)
                                            : AppColors.backgroundMedium,
                                        border: isSelected
                                            ? Border.all(
                                                color: AppColors.primary,
                                                width: 2,
                                              )
                                            : null,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors:
                                                    AppColors.primaryGradient,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.group,
                                              color: AppColors.textPrimary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  team.name,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${team.players.length} players',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.success,
                                              size: 20,
                                            )
                                          else
                                            const Icon(
                                              Icons.chevron_right,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (selectedTeam != null) ...[
                              const Divider(color: AppColors.backgroundDark),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Players in ${selectedTeam!.name}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: selectedTeam!.players.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final player = selectedTeam!.players[index];
                                    final isAlreadyAdded = _players.any(
                                      (p) =>
                                          p.name.toLowerCase() ==
                                          player.name.toLowerCase(),
                                    );

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundMedium,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors:
                                                    AppColors.primaryGradient,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Center(
                                              child: Text(
                                                player.name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              player.name,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (isAlreadyAdded)
                                            const Icon(
                                              Icons.check,
                                              color: AppColors.success,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (mounted && selectedTeam != null) {
                                      setState(() {
                                        for (final player
                                            in selectedTeam!.players) {
                                          if (!_players.any((p) =>
                                              p.name.toLowerCase() ==
                                              player.name.toLowerCase())) {
                                            _players.add(Player(
                                              id: player.id,
                                              name: player.name,
                                            ));
                                          }
                                        }
                                      });
                                    }
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text(
                                      'Add ${selectedTeam!.players.length} Players'),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPlayer(String name) {
    final playerName = name.trim();
    if (playerName.isEmpty) return;

    if (_players.any((p) => p.name.toLowerCase() == playerName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player already exists')),
      );
      return;
    }

    setState(() {
      _players.add(Player(
        id: const Uuid().v4(),
        name: playerName,
      ));
      _playerNameController.clear();
    });
  }

  void _addAllPlayersFromTeam(Team team) {
    setState(() {
      for (final player in team.players) {
        if (!_players
            .any((p) => p.name.toLowerCase() == player.name.toLowerCase())) {
          _players.add(Player(
            id: player.id,
            name: player.name,
          ));
        }
      }
    });

    TopNotification.show(
      context,
      message: 'Added all players from ${team.name}',
      type: NotificationType.success,
      icon: Icons.group_add,
    );
  }

  void _removeTeam(Team team) {
    setState(() {
      _selectedTeams.remove(team);
      _players.removeWhere(
        (player) => team.players.any((p) => p.id == player.id),
      );
    });
  }

  Future<void> _startGame() async {
    // Validate game name
    final gameName = _gameNameController.text.trim();
    if (gameName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game name is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate buy-in amount
    double? buyInAmount;
    try {
      buyInAmount = double.parse(_buyInController.text);
      if (buyInAmount <= 0) {
        throw const FormatException('Buy-in must be greater than 0');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid buy-in amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate cut percentage
    double? cutPercentage;
    try {
      cutPercentage = double.parse(_cutPercentageController.text);
      if (cutPercentage < 0 || cutPercentage > 100) {
        throw const FormatException('Cut percentage must be between 0 and 100');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid cut percentage (0-100)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Double check player count
    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 players are required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final gameProvider = context.read<GameProvider>();
      await gameProvider.createGame(
        gameName,
        buyInAmount,
        _players.toList(),
        cutPercentage,
      );

      if (!mounted) return;

      final game = gameProvider.currentGame;
      if (game != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game "${game.name}" created successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        context.go('/game/${game.id}');
      } else {
        throw Exception('Failed to create game');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create game: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
