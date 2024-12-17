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
  double _selectedCutPercentage = 0;
  final Set<Team> _selectedTeams = {};
  final Set<Player> _players = {};
  final _playerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh teams when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeamProvider>().refreshTeams();
      }
    });
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _buyInController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  Widget _buildCutPercentageSelector() {
    final cutOptions = [
      (0.0, 'No Cut', Icons.block),
      (25.0, '25%', Icons.percent),
      (50.0, '50%', Icons.percent),
      (75.0, '75%', Icons.warning_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cut Percentage',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: cutOptions.map((option) {
            final isSelected = _selectedCutPercentage == option.$1;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCutPercentage = option.$1),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 200),
                      tween: Tween(begin: 1.0, end: isSelected ? 1.1 : 1.0),
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFF0B1120),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            option.$3,
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.$2,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: _selectedCutPercentage > 0
                      ? 'House cut will be '
                      : 'No house cut will be applied to this game',
                ),
                if (_selectedCutPercentage > 0) ...[
                  TextSpan(
                    text: '${_selectedCutPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' of the total pot'),
                  if (_selectedCutPercentage == 75)
                    TextSpan(
                      text: ' (High percentage!)',
                      style: TextStyle(
                        color: Colors.amber[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                prefix: '',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildCutPercentageSelector(),
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
            inputFormatters: keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : null,
            onChanged: (value) {
              if (keyboardType == TextInputType.number && value.isNotEmpty) {
                try {
                  final number = double.parse(value);
                  if (label.contains('Buy-in') && number <= 0) {
                    controller.text = '20';
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                } catch (_) {
                  controller.text = '20';
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
    final bool canStartGame = _players.length >= 2 &&
        _gameNameController.text.trim().isNotEmpty &&
        (double.tryParse(_buyInController.text) ?? 0) > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: canStartGame
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : LinearGradient(colors: [Colors.grey[800]!, Colors.grey[700]!]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canStartGame ? _startGame : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Start Game',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: canStartGame ? Colors.white : Colors.grey[400],
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
                    final teamProvider = currentContext.watch<TeamProvider>();
                    final isLoading = teamProvider.isLoading;
                    final teams = teamProvider.teams;

                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_off,
                              color: AppColors.textSecondary.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No teams available',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a team first to import players',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                                                width: 1,
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
                                          const SizedBox(width: 10),
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
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${team.players.length} players',
                                                  style: const TextStyle(
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
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 18,
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
                                        color: AppColors.backgroundLight,
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
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              player.name,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 16,
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
                                      vertical: 12,
                                    ),
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
                                    'Add ${selectedTeam!.players.length} Players',
                                  ),
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
      TopNotification.show(
        context,
        message: 'Player already exists',
        type: NotificationType.error,
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

  Future<void> _startGame() async {
    // Validate game name
    final gameName = _gameNameController.text.trim();
    if (gameName.isEmpty) {
      TopNotification.show(
        context,
        message: 'Game name is required',
        type: NotificationType.error,
      );
      return;
    }

    // Check for duplicate game names
    final gameProvider = context.read<GameProvider>();
    final activeGames = gameProvider.activeGames;

    if (activeGames
        .any((game) => game.name.toLowerCase() == gameName.toLowerCase())) {
      TopNotification.show(
        context,
        message: 'A game with this name already exists',
        type: NotificationType.error,
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
      TopNotification.show(
        context,
        message: 'Please enter a valid buy-in amount',
        type: NotificationType.error,
      );
      return;
    }

    // Double check player count
    if (_players.length < 2) {
      TopNotification.show(
        context,
        message: 'At least 2 players are required',
        type: NotificationType.error,
      );
      return;
    }

    try {
      await gameProvider.createGame(
        gameName,
        buyInAmount,
        _players.toList(),
        _selectedCutPercentage,
      );

      if (!mounted) return;

      final game = gameProvider.currentGame;
      if (game != null) {
        TopNotification.show(
          context,
          message: 'Game "${game.name}" created successfully',
          type: NotificationType.success,
        );

        context.go('/game/${game.id}');
      } else {
        throw Exception('Failed to create game');
      }
    } catch (e) {
      if (!mounted) return;

      TopNotification.show(
        context,
        message: 'Failed to create game: ${e.toString()}',
        type: NotificationType.error,
      );
    }
  }
}
