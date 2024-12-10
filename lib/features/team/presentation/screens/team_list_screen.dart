import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/features/team/providers/team_provider.dart';
import 'package:provider/provider.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  int _currentIndex = 1; // Set to Teams tab index

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
              // Header remains unchanged
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
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ).createShader(bounds),
                      child: const Text(
                        'Team Management',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient:
                              LinearGradient(colors: AppColors.primaryGradient),
                          shape: BoxShape.circle,
                        ),
                        child:
                            const Icon(Icons.add, color: AppColors.textPrimary),
                      ),
                      onPressed: () => context.push('/teams/new'),
                      tooltip: 'Create New Team',
                    ),
                  ],
                ),
              ),

              // Teams List - Existing implementation remains unchanged
              Expanded(
                child: Consumer<TeamProvider?>(
                  builder: (context, teamProvider, child) {
                    if (teamProvider == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final teams = teamProvider.teams;

                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Teams Created',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a team to get started',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => context.push('/teams/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Team'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Existing team list implementation
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppColors.backgroundMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => context.push('/teams/${team.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: AppColors.primaryGradient,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.group,
                                          color: AppColors.textPrimary,
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
                                                color: AppColors.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${team.players.length} players',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () =>
                                            context.push('/teams/${team.id}'),
                                      ),
                                    ],
                                  ),
                                  if (team.players.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(
                                        color: AppColors.backgroundDark),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 40,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: team.players.length,
                                        itemBuilder: (context, index) {
                                          final player = team.players[index];
                                          return Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            child: Chip(
                                              backgroundColor:
                                                  AppColors.backgroundDark,
                                              label: Text(
                                                player.name,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              avatar: CircleAvatar(
                                                backgroundColor:
                                                    AppColors.primary,
                                                child: Text(
                                                  player.name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundMedium,
        border: Border(
          top: BorderSide(color: AppColors.backgroundMedium, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, () => context.go('/')),
              _buildNavItem(Icons.group, 'Teams', 1, () {}),
              _buildNavItem(Icons.bar_chart, 'Game Stats', 2,
                  () => context.go('/analytics')),
              _buildNavItem(Icons.history, 'Game History', 3,
                  () => context.go('/history')),
              _buildNavItem(Icons.tips_and_updates, 'Tips', 4,
                  () => context.go('/poker-reference')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, VoidCallback onTap) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
