import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/top_notification.dart';
import 'package:poker_tracker/features/team/data/team.dart';
import 'package:poker_tracker/features/team/providers/team_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class TeamManagementScreen extends StatefulWidget {
  final String? teamId;
  const TeamManagementScreen({super.key, this.teamId});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _playerNameController = TextEditingController();
  final List<TeamPlayer> _players = [];
  bool _isLoading = false;
  Team? _existingTeam;

  @override
  void initState() {
    super.initState();
    if (widget.teamId != null) {
      _loadExistingTeam();
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.backgroundDark.withOpacity(0.3),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.textPrimary,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        _existingTeam != null ? 'Edit Team' : 'Create Team',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_existingTeam != null)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: AppColors.error,
                          onPressed: _showDeleteConfirmation,
                        ),
                    ],
                  ),
                ),

                if (_isLoading)
                  const LinearProgressIndicator()
                else
                  const SizedBox(height: 1),

                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTeamDetailsCard(),
                      const SizedBox(height: 16),
                      _buildPlayersCard(),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                          child: const Text(
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
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
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
                            onPressed: _isLoading ? null : _saveTeam,
                            child: Text(
                              _existingTeam != null
                                  ? 'Update Team'
                                  : 'Create Team',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDetailsCard() {
    return Card(
      color: AppColors.backgroundMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teamNameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Team Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon:
                    const Icon(Icons.group, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              readOnly: (_existingTeam != null) ? true : false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Team name is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersCard() {
    return Card(
      color: AppColors.backgroundMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Players',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_players.length} players',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _playerNameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Player Name',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.person_add,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.primaryGradient),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: AppColors.textPrimary),
                    onPressed: _addPlayer,
                  ),
                ),
              ],
            ),
            if (_players.isNotEmpty) ...[
              const SizedBox(height: 16),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  return Padding(
                    key: ValueKey(player.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: AppColors.primaryGradient),
                            shape: BoxShape.circle,
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
                        title: Text(
                          player.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.drag_handle,
                                  color: AppColors.textSecondary),
                              onPressed: null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.error),
                              onPressed: () => _removePlayer(player),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _players.removeAt(oldIndex);
                    _players.insert(newIndex, item);
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _removePlayer(TeamPlayer player) {
    setState(() => _players.remove(player));
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _teamNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team name is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one player to the team'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teamProvider = context.read<TeamProvider>();

      if (_existingTeam != null) {
        await teamProvider.updateTeam(_existingTeam!.copyWith(
          name: name,
          players: _players,
        ));
      } else {
        await teamProvider.createTeam(name, _players);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_existingTeam != null
              ? 'Team updated successfully'
              : 'Team created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        title: const Text(
          'Delete Team?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone. The team will be permanently deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        final teamProvider = context.read<TeamProvider>();
        await teamProvider.deleteTeam(_existingTeam!.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete team: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadExistingTeam() async {
    setState(() => _isLoading = true);

    try {
      final teamProvider = context.read<TeamProvider>();
      final team = await teamProvider.getTeamById(widget.teamId!);

      if (team == null) {
        throw Exception('Team not found');
      }

      _existingTeam = team;
      _teamNameController.text = team.name;
      setState(() {
        _players.clear();
        _players.addAll(team.players);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading team: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        // Navigate back if team can't be loaded
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addPlayer() {
    final name = _playerNameController.text.trim();
    if (name.isEmpty) return;

    if (_players
        .any((player) => player.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player already exists in team'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _players.add(TeamPlayer(name: name));
      _playerNameController.clear();
    });
  }
}
