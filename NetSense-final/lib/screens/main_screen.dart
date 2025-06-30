import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/app_router.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(navigationProvider);
    
    return Scaffold(
      body: _buildBody(currentRoute),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).navigateTo(
                AppRoute.values[index],
              );
        },
        selectedIndex: currentRoute.index,
        destinations: AppRoute.values.map((route) {
          return NavigationDestination(
            icon: Icon(route.icon),
            label: route.name,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(AppRoute route) {
    switch (route) {
      case AppRoute.home:
        return const HomeScreen();
      case AppRoute.history:
        return const HistoryScreen();
      case AppRoute.settings:
        return const SettingsScreen();
    }
  }
}
