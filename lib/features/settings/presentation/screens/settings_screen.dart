import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:poker_tracker/features/auth/providers/auth_provider.dart';
import 'package:poker_tracker/features/settings/providers/settings_provider.dart';
import 'package:poker_tracker/shared/widgets/custom_text_field.dart';
import 'package:poker_tracker/shared/widgets/loading_overlay.dart';
// ignore: unused_import
import 'package:poker_tracker/shared/widgets/custom_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AuthProvider>().signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Return to Home',
        ),
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;
          final isLoading = settingsProvider.isLoading;

          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return LoadingOverlay(
            isLoading: isLoading,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account Section
                _buildSection(
                  title: 'Account',
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final user = authProvider.user;
                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                backgroundImage: user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null,
                                child: user?.photoURL == null
                                    ? Icon(Icons.person,
                                        color: theme.colorScheme.primary)
                                    : null,
                              ),
                              title: Text(
                                user?.displayName ?? 'User',
                                style: theme.textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                user?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                // Appearance Section
                _buildSection(
                  title: 'Appearance',
                  children: [
                    SwitchListTile(
                      title: const Text('Use System Theme'),
                      subtitle: const Text('Match system dark/light mode'),
                      value: settings.useSystemTheme,
                      onChanged: (value) {
                        settingsProvider.updateThemeMode(
                          settings.isDarkMode,
                          value,
                        );
                      },
                    ),
                    if (!settings.useSystemTheme)
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle:
                            const Text('Switch between light and dark theme'),
                        value: settings.isDarkMode,
                        onChanged: (value) {
                          settingsProvider.updateThemeMode(
                            value,
                            settings.useSystemTheme,
                          );
                        },
                      ),
                  ],
                ),

                // Game Defaults Section
                _buildSection(
                  title: 'Game Defaults',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Default Buy-in Amount'),
                      subtitle: Text('\$${settings.defaultBuyIn}'),
                      onTap: () => _showBuyInDialog(
                        context,
                        settings.defaultBuyIn,
                        settingsProvider,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.currency_exchange),
                      title: const Text('Currency'),
                      subtitle: Text(settings.currency),
                      onTap: () => _showCurrencyDialog(
                        context,
                        settings.currency,
                        settingsProvider,
                      ),
                    ),
                  ],
                ),

                // Notifications Section
                _buildSection(
                  title: 'Notifications',
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Get notified about game updates'),
                      value: settings.enableNotifications,
                      onChanged: (value) {
                        settingsProvider.updateNotifications(value);
                      },
                    ),
                  ],
                ),

                // Account Actions Section
                _buildSection(
                  title: 'Account Actions',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => _handleLogout(context),
                    ),
                  ],
                ),

                // App Info Section
                _buildSection(
                  title: 'About',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Version'),
                      subtitle:
                          const Text('1.0.0'), // Replace with your app version
                    ),
                    ListTile(
                      leading: const Icon(Icons.policy_outlined),
                      title: const Text('Privacy Policy'),
                      onTap: () {
                        // Add privacy policy navigation
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      onTap: () {
                        // Add terms of service navigation
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _showBuyInDialog(
    BuildContext context,
    double currentAmount,
    SettingsProvider provider,
  ) async {
    final controller = TextEditingController(
      text: currentAmount.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Buy-in Amount'),
        content: CustomTextField(
          label: 'Amount',
          controller: controller,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.attach_money,
          onSubmitted: (_) {},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      final amount = double.tryParse(controller.text);
      if (amount != null && amount > 0) {
        await provider.updateDefaultBuyIn(amount);
      }
    }
  }

  Future<void> _showCurrencyDialog(
    BuildContext context,
    String currentCurrency,
    SettingsProvider provider,
  ) async {
    const currencies = ['USD', 'EUR', 'GBP', 'INR', 'AUD', 'CAD'];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Currency'),
        children: currencies.map((currency) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, currency),
            child: Text(currency),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      await provider.updateCurrency(result);
    }
  }
}
