import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/background_service.dart';

// Provider for background monitoring settings
final backgroundMonitoringProvider = StateProvider<bool>((ref) => false);
final monitoringIntervalProvider = StateProvider<int>((ref) => 10); // Default 10 minutes (updated from 30)
final showBackgroundFeedbackProvider = StateProvider<bool>((ref) => false); // Whether to show feedback after background tests

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isBackgroundMonitoringEnabled = ref.watch(backgroundMonitoringProvider);
    final monitoringInterval = ref.watch(monitoringIntervalProvider);
    final showBackgroundFeedback = ref.watch(showBackgroundFeedbackProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern app bar with gradient
          SliverAppBar(
            expandedHeight: 120.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.settings,
                    size: 40,
                    color: colorScheme.onPrimary.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          
          // Settings content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Appearance section
                _buildSectionHeader(context, 'Appearance'),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Mode',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        // Theme selector with toggle buttons
                        _buildThemeSelector(context, ref, themeMode),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Background monitoring section
                _buildSectionHeader(context, 'Background Monitoring'),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Enable Monitoring', style: theme.textTheme.titleMedium),
                        subtitle: const Text('Automatically run tests periodically'),
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isBackgroundMonitoringEnabled ? 
                              colorScheme.primary.withOpacity(0.1) : 
                              colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.speed_rounded,
                            color: isBackgroundMonitoringEnabled ? 
                              colorScheme.primary : 
                              colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: isBackgroundMonitoringEnabled,
                        onChanged: (value) async {
                          ref.read(backgroundMonitoringProvider.notifier).state = value;
                          if (value) {
                            // Register background tasks
                            final interval = ref.read(monitoringIntervalProvider);
                            await BackgroundService.registerPeriodicSpeedTest(interval);
                            await BackgroundService.registerNetworkMonitor();
                          } else {
                            // Cancel background tasks
                            await BackgroundService.cancelPeriodicSpeedTest();
                          }
                        },
                      ),
                      const Divider(),
                      ListTile(
                        enabled: isBackgroundMonitoringEnabled,
                        title: Text('Test Interval', style: theme.textTheme.titleSmall),
                        subtitle: Text('$monitoringInterval minutes'),
                        trailing: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isBackgroundMonitoringEnabled ? 
                              colorScheme.primary.withOpacity(0.1) : 
                              colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.timer_outlined,
                            color: isBackgroundMonitoringEnabled ? 
                              colorScheme.primary : 
                              colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        onTap: isBackgroundMonitoringEnabled ? 
                          () => _showIntervalDialog(context, ref) : null,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: Text('Show Notifications', style: theme.textTheme.titleSmall),
                        subtitle: const Text('Get feedback after background tests'),
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isBackgroundMonitoringEnabled && showBackgroundFeedback) ? 
                              colorScheme.primary.withOpacity(0.1) : 
                              colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: (isBackgroundMonitoringEnabled && showBackgroundFeedback) ? 
                              colorScheme.primary : 
                              colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        value: showBackgroundFeedback,
                        onChanged: isBackgroundMonitoringEnabled ? 
                          (value) async {
                            ref.read(showBackgroundFeedbackProvider.notifier).state = value;
                            await BackgroundService.setShowBackgroundFeedback(value);
                          } : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Data management section
                _buildSectionHeader(context, 'Data Management'),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text('Clear Test History', style: theme.textTheme.titleMedium),
                    subtitle: const Text('Delete all saved test results'),
                    trailing: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
                      ),
                    ),
                    onTap: () => _showClearDataDialog(context),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App info section
                _buildSectionHeader(context, 'About'),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text('Version', style: theme.textTheme.titleSmall),
                          trailing: Text('1.0.0', style: theme.textTheme.bodyMedium),
                        ),
                        ListTile(
                          title: Text('Build Number', style: theme.textTheme.titleSmall),
                          trailing: Text('001', style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: _themeOptionCard(
            context,
            title: 'System',
            icon: Icons.brightness_auto,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).useSystemTheme(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _themeOptionCard(
            context,
            title: 'Light',
            icon: Icons.light_mode,
            isSelected: currentMode == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _themeOptionCard(
            context,
            title: 'Dark',
            icon: Icons.dark_mode,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
          ),
        ),
      ],
    );
  }
  
  Widget _themeOptionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, WidgetRef ref) {
    final intervals = [15, 30, 60, 120]; // Minutes (enforcing Android's minimum 15-minute interval)
    final colorScheme = Theme.of(context).colorScheme;
    final currentInterval = ref.read(monitoringIntervalProvider);
    int selectedInterval = intervals.contains(currentInterval) ? currentInterval : intervals[0];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient app bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Background Test Interval',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Interval selection
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select how often background tests should run:',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Android requires a minimum interval of 15 minutes for background tasks.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Interval options with modern design
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: intervals.map((interval) {
                            final isSelected = selectedInterval == interval;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  selectedInterval = interval;
                                });
                              },
                              child: Container(
                                width: 80,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? colorScheme.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$interval min',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            ref.read(monitoringIntervalProvider.notifier).state = selectedInterval;
                            Navigator.pop(context);
                            // Update background task interval
                            await BackgroundService.registerPeriodicSpeedTest(selectedInterval);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('SAVE'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Test History'),
          content: const Text('Are you sure you want to delete all test results? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                final storageService = StorageService();
                await storageService.clearTestResults();
                await storageService.clearFeedbackResults();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test history cleared')),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('CLEAR'),
            ),
          ],
        );
      },
    );
  }
}
