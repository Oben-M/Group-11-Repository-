import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'services/background_service.dart';
import 'services/storage_service.dart';

// Global navigator key for accessing navigator from outside the widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Ensure we have sample test data for the app
  await _ensureSampleData();
  
  // Initialize background tasks with error handling
  try {
    await BackgroundService.initialize();
    debugPrint('Background service initialized successfully');
  } catch (e) {
    // Don't let background service errors prevent the app from starting
    debugPrint('Error initializing background service: $e');
    // This is expected on platforms that don't support the workmanager plugin
  }
  
  // Run app with ProviderScope for state management
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

// Ensure we have sample test data for the app
Future<void> _ensureSampleData() async {
  try {
    final storageService = StorageService();
    final testResults = await storageService.getTestResults();
    
    if (testResults.isEmpty) {
      debugPrint('Main: Creating sample test data on app startup');
      await storageService.createSampleTestResults();
      debugPrint('Main: Sample test data created successfully');
    } else {
      debugPrint('Main: Found ${testResults.length} existing test results');
    }
  } catch (e) {
    debugPrint('Main: Error ensuring sample data: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode changes
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Network Speed Checker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      home: const MainScreen(),
    );
  }
}
