// game_setup_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: AppColors.backgroundDark.withOpacity(0.3),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => Navigator.pop(context),
                          color: AppColors.textPrimary,
                        ),
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
                  ),
                ),
              ),

              // Main Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildGameDetailsCard(),
                    const SizedBox(height: 16),
                    _buildPlayersCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameDetailsCard() {
    return Card(
      color: AppColors.backgroundMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _gameNameController,
              label: 'Game Name',
              prefixIcon: Icons.casino,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _buyInController,
              label: 'Buy-in Amount',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _cutPercentageController,
              label: 'Cut Percentage',
              prefixIcon: Icons.percent,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTeamsCard() {
    return Card(
      color: AppColors.backgroundMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Teams',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Container(
                    decoration: const BoxDecoration(
                      gradient:
                          LinearGradient(colors: AppColors.primaryGradient),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.textPrimary),
                  ),
                  onPressed: _showTeamSelectionDialog,
                ),
              ],
            ),
            Consumer<TeamProvider?>(
              builder: (context, teamProvider, child) {
                if (teamProvider == null) {
                  print('TeamProvider is null in Consumer');
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (teamProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final availableTeams = teamProvider.teams;
                if (availableTeams.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No teams available',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: availableTeams.length,
                  itemBuilder: (context, index) {
                    final team = availableTeams[index];
                    return _buildTeamTile(team);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // In your GameSetupScreen
  void _showTeamSelectionDialog() {
    final currentContext = context;
    Team? selectedTeam; // Move selectedTeam declaration here

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
                            // Teams List
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: teams.length,
                                itemBuilder: (context, index) {
                                  final team = teams[index];
                                  final isSelected =
                                      selectedTeam?.id == team.id;

                                  return ListTile(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedTeam = team;
                                      });
                                    },
                                    selected: isSelected,
                                    selectedTileColor:
                                        AppColors.primary.withOpacity(0.1),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: AppColors.primaryGradient,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.group,
                                          color: AppColors.textPrimary),
                                    ),
                                    title: Text(
                                      team.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${team.players.length} players',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle,
                                            color: AppColors.success)
                                        : const Icon(Icons.arrow_forward_ios,
                                            color: AppColors.textSecondary),
                                  );
                                },
                              ),
                            ),

                            if (selectedTeam != null) ...[
                              const Divider(color: AppColors.backgroundDark),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Players in ${selectedTeam!.name}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: selectedTeam!.players.length,
                                  itemBuilder: (context, index) {
                                    final player = selectedTeam!.players[index];
                                    final isAlreadyAdded = _players.any((p) =>
                                        p.name.toLowerCase() ==
                                        player.name.toLowerCase());

                                    return ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        radius: 16,
                                        child: Text(
                                          player.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        player.name,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary),
                                      ),
                                      trailing: isAlreadyAdded
                                          ? const Icon(Icons.check,
                                              color: AppColors.success)
                                          : null,
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

  Widget _buildTeamTile(Team team) {
    final isAllPlayersAdded = team.players.every(
      (player) => _selectedPlayers.any((p) => p.id == player.id),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.group, color: AppColors.textPrimary),
        ),
        title: Text(
          team.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${team.players.length} players',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAllPlayersAdded)
              TextButton(
                onPressed: () => _addAllPlayersFromTeam(team),
                child: const Text(
                  'Add All',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              onPressed: () => _removeTeam(team),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersCard() {
    return Card(
      color: AppColors.backgroundMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Players',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_players.length} players',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add player input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerNameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add player',
                      hintStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.person_add),
                      filled: true,
                      fillColor: AppColors.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _addPlayer,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient:
                          LinearGradient(colors: AppColors.primaryGradient),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.textPrimary),
                  ),
                  onPressed: () => _addPlayer(_playerNameController.text),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Import from teams button
            OutlinedButton.icon(
              onPressed: _showTeamSelectionDialog,
              icon: const Icon(Icons.group_add),
              label: const Text('Import from Teams'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Players list
            if (_players.isNotEmpty)
              ...List<Widget>.from(_players.map(_buildPlayerTile)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(Player player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              player.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          player.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
          onPressed: () => setState(() => _players.remove(player)),
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

  /*
  
  void _showTeamSelectionDialog() {
    final currentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
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

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        return ListTile(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                // Add team's players to the game
                                for (final player in team.players) {
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
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: AppColors.primaryGradient),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.group,
                                color: AppColors.textPrimary),
                          ),
                          title: Text(
                            team.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${team.players.length} players',
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primary,
                          ),
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
*/
  Widget _buildActionButtons() {
    // Debug prints to verify player count
    print('Building action buttons');
    print('Current player count: ${_players.length}');
    print('Players: ${_players.map((p) => p.name).join(', ')}');

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _players.length >= 2
                    ? AppColors.primaryGradient
                    : [Colors.grey[700]!, Colors.grey[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                print('Start Game pressed');
                print('Player count at press: ${_players.length}');
                if (_players.length >= 2) {
                  _startGame();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('At least 2 players are required'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Start Game ${_players.isNotEmpty ? "(${_players.length})" : ""}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
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
// Continuation of GameSetupScreen class...

  void _addAllPlayersFromTeam(Team team) {
    setState(() {
      _selectedPlayers.addAll(
        team.players.map((p) => Player(id: p.id, name: p.name)),
      );
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
      // Optionally remove players that were added from this team
      _selectedPlayers.removeWhere(
        (player) => team.players.any((p) => p.id == player.id),
      );
    });
  }

  Future<void> _startGame() async {
    print('_startGame called');
    print('Number of players: ${_players.length}');

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

    // Double check player count
    if (_players.length < 2) {
      print('ERROR: Insufficient players at game start');
      print('Players: ${_players.map((p) => p.name).join(', ')}');
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
        double.parse(_buyInController.text),
        _players.toList(),
        double.parse(_cutPercentageController.text),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create game: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
