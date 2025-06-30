import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation destinations
enum AppRoute {
  home,
  history,
  settings,
}

// Navigation state notifier
class NavigationNotifier extends StateNotifier<AppRoute> {
  NavigationNotifier() : super(AppRoute.home);

  void navigateTo(AppRoute route) {
    state = route;
  }
}

// Navigation provider
final navigationProvider = StateNotifierProvider<NavigationNotifier, AppRoute>(
  (ref) => NavigationNotifier(),
);

// Extension to get route name
extension AppRouteExtension on AppRoute {
  String get name {
    switch (this) {
      case AppRoute.home:
        return 'Home';
      case AppRoute.history:
        return 'History';
      case AppRoute.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRoute.home:
        return Icons.home;
      case AppRoute.history:
        return Icons.history;
      case AppRoute.settings:
        return Icons.settings;
    }
  }
}
