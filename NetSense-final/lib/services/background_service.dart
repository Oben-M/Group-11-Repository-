// Background service for periodic speed tests
import 'dart:async';
import 'dart:math' as math;
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
// Removed unused import
import 'package:http/http.dart' as http;
import 'connectivity_service.dart';
import 'speed_test_service.dart';
import 'storage_service.dart';
import 'preferences_service.dart';
import '../models/speed_test_result.dart';
import '../screens/feedback_screen.dart';
import '../main.dart'; // Import for global navigator key

// Background task names
const String periodicSpeedTestTask = 'periodicSpeedTestTask';
const String monitorNetworkPerformanceTask = 'monitorNetworkPerformanceTask';

// Port name for communication between isolate and UI
const String backgroundPortName = 'background_port';

// Callback function that will be called by workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case periodicSpeedTestTask:
          await _performBackgroundSpeedTest();
          break;
        case monitorNetworkPerformanceTask:
          await _monitorNetworkPerformance();
          break;
        default:
          debugPrint('Unknown task: $taskName');
          return Future.value(false);
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}

class BackgroundService {
  // Initialize background tasks
  static Future<void> initialize() async {
    debugPrint('Initializing background service...');
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    try {
      final isEnabled = await PreferencesService.isBackgroundMonitoringEnabled();
      final interval = await PreferencesService.getBackgroundMonitoringInterval();
      
      if (isEnabled) {
        await registerPeriodicSpeedTest(interval);
        // Register the network performance monitor task
        await registerNetworkMonitor();
      }
      
      // Register port for background to UI communication
      _registerBackgroundPort();
    } catch (e) {
      debugPrint('Error registering periodic task: $e');
    }
  }
  
  // Register port for background to UI communication
  static void _registerBackgroundPort() {
    // Register a send port to receive messages from the background isolate
    final ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      backgroundPortName,
    );
    
    // Listen for messages from the background isolate
    port.listen((dynamic message) {
      if (message is Map<String, dynamic> && message['type'] == 'show_feedback') {
        _showFeedbackFromBackground(message['timestamp']);
      }
    });
  }
  
  // Show feedback screen from background task
  static void _showFeedbackFromBackground(String timestamp) async {
    try {
      final shouldShow = await PreferencesService.shouldShowBackgroundFeedback();
      if (!shouldShow) return;
      
      // Get the test result from storage
      final storageService = StorageService();
      final tests = await storageService.getTestResults();
      final DateTime testTime = DateTime.parse(timestamp);
      
      // Find the test that matches the timestamp
      SpeedTestResult? matchingTest;
      try {
        matchingTest = tests.firstWhere(
          (test) => test.timestamp.difference(testTime).inSeconds.abs() < 5,
        );
      } catch (e) {
        // No matching test found, use the first one if available
        if (tests.isNotEmpty) {
          matchingTest = tests.first;
        }
      }
      
      if (matchingTest != null) {
        // Use the global navigator key from main.dart
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                testResult: matchingTest,
                isFromBackgroundTest: true,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error showing feedback from background: $e');
    }
  }

  // Register periodic speed test task
  static Future<void> registerPeriodicSpeedTest(int intervalMinutes) async {
    // Cancel any existing tasks first
    await Workmanager().cancelByTag(periodicSpeedTestTask);
    
    // Enforce minimum interval of 15 minutes (Android WorkManager requirement)
    final int enforcedInterval = intervalMinutes < 15 ? 15 : intervalMinutes;
    
    // Register new periodic task
    await Workmanager().registerPeriodicTask(
      periodicSpeedTestTask, // Unique name
      periodicSpeedTestTask, // Task name
      tag: periodicSpeedTestTask,
      frequency: Duration(minutes: enforcedInterval),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    
    // Save the interval setting
    await PreferencesService.setBackgroundMonitoringInterval(enforcedInterval);
    await PreferencesService.setBackgroundMonitoringEnabled(true);
  }
  
  // Register network performance monitor task (runs every 30 minutes)
  static Future<void> registerNetworkMonitor() async {
    // Cancel any existing tasks first
    await Workmanager().cancelByTag(monitorNetworkPerformanceTask);
    
    // Get interval from preferences
    final interval = await PreferencesService.getBackgroundMonitoringInterval();
    
    // Enforce minimum interval of 15 minutes (Android WorkManager requirement)
    final int enforcedInterval = interval < 15 ? 15 : interval;
    
    // Register new periodic task
    await Workmanager().registerPeriodicTask(
      monitorNetworkPerformanceTask, // Unique name
      monitorNetworkPerformanceTask, // Task name
      tag: monitorNetworkPerformanceTask,
      frequency: Duration(minutes: enforcedInterval),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    
    debugPrint('Network performance monitor registered to run every $enforcedInterval minutes');
  }

  // Cancel periodic speed test task
  static Future<void> cancelPeriodicSpeedTest() async {
    await Workmanager().cancelByTag(periodicSpeedTestTask);
    await Workmanager().cancelByTag(monitorNetworkPerformanceTask);
    
    // Update settings
    await PreferencesService.setBackgroundMonitoringEnabled(false);
  }

  // Check if background monitoring is enabled
  static Future<bool> isBackgroundMonitoringEnabled() async {
    return PreferencesService.isBackgroundMonitoringEnabled();
  }
  
  // Get monitoring interval in minutes
  static Future<int> getMonitoringInterval() async {
    return PreferencesService.getBackgroundMonitoringInterval();
  }
  
  // Set whether to show feedback after background tests
  static Future<void> setShowBackgroundFeedback(bool show) async {
    await PreferencesService.setShowBackgroundFeedback(show);
  }
  
  // Get whether to show feedback after background tests
  static Future<bool> shouldShowBackgroundFeedback() async {
    return PreferencesService.shouldShowBackgroundFeedback();
  }

}

// Notify UI to show feedback after background test
void _notifyUIForFeedback(String timestamp) {
  try {
    // Try to get the send port
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(backgroundPortName);
    if (sendPort != null) {
      // Send message to UI
      sendPort.send({
        'type': 'show_feedback',
        'timestamp': timestamp,
      });
      debugPrint('Notification sent to UI for feedback');
    } else {
      debugPrint('No port found for UI notification');
    }
  } catch (e) {
    debugPrint('Error sending notification to UI: $e');
  }
}

// Network performance monitoring task that runs every 30 minutes
Future<void> _monitorNetworkPerformance() async {
  try {
    debugPrint('Starting network performance monitoring task');
    
    // Create services
    final connectivityService = ConnectivityService();
    final speedTestService = SpeedTestService(connectivityService);
    final storageService = StorageService();
    
    // Check connectivity
    final isOnline = await connectivityService.isConnected();
    final connectionType = await connectivityService.getCurrentConnectionType();
    if (!isOnline) {
      debugPrint('No connection available, exiting network monitoring task');
      return; // No connection, exit early
    }
    
    debugPrint('Connection type: $connectionType');
    
    // 1. Measure ping and calculate jitter
    final pingResults = await _measurePingWithJitter();
    final avgPing = pingResults['ping'] as int;
    final jitter = pingResults['jitter'] as double;
    final packetLoss = pingResults['packetLoss'] as double;
    
    debugPrint('Ping: $avgPing ms, Jitter: $jitter ms, Packet Loss: $packetLoss%');
    
    // 2. Get location if permission is granted
    Position? position;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
        debugPrint('Location obtained: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Continue without location
    }
    
    // 3. Perform speed test
    final downloadSpeed = await speedTestService.testDownloadSpeed();
    final uploadSpeed = await speedTestService.testUploadSpeed();
    
    debugPrint('Download speed: $downloadSpeed Mbps, Upload speed: $uploadSpeed Mbps');
    
    // 4. Create SpeedTestResult object
    final result = SpeedTestResult(
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      ping: avgPing,
      connectionType: connectionType,
      timestamp: DateTime.now(),
      signalStrength: null, // Would require platform-specific code to get actual signal strength
      latitude: position?.latitude,
      longitude: position?.longitude,
      jitter: jitter,
      packetLoss: packetLoss,
    );
    
    // 5. Save result and limit history to last 10 entries
    await storageService.saveTestResult(result);
    await _limitHistoryEntries(storageService, 10);
    
    // 6. Record the timestamp of this test
    await PreferencesService.setLastBackgroundTestTime(DateTime.now());
    
    // 7. Notify UI to show feedback if enabled
    _notifyUIForFeedback(result.timestamp.toIso8601String());
    
    debugPrint('Network performance monitoring completed and saved');
  } catch (e) {
    debugPrint('Error in network performance monitoring task: $e');
  }
}

// Measure ping with multiple samples to calculate jitter and packet loss
Future<Map<String, dynamic>> _measurePingWithJitter({int samples = 5}) async {
  final String pingUrl = 'https://1.1.1.1'; // Cloudflare DNS for reliable ping
  final List<int> pings = [];
  int failedPings = 0;
  
  for (int i = 0; i < samples; i++) {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(pingUrl))
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Ping request timed out');
      });
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        pings.add(stopwatch.elapsedMilliseconds);
        debugPrint('Ping sample ${i+1}: ${stopwatch.elapsedMilliseconds} ms');
      } else {
        failedPings++;
        debugPrint('Ping sample ${i+1} failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      failedPings++;
      debugPrint('Ping sample ${i+1} failed: $e');
    }
    
    // Small delay between pings
    if (i < samples - 1) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
  
  // Calculate average ping
  final int avgPing = pings.isEmpty ? -1 : pings.reduce((a, b) => a + b) ~/ pings.length;
  
  // Calculate jitter (standard deviation of ping times)
  double jitter = 0;
  if (pings.length > 1) {
    final double mean = avgPing.toDouble();
    final double sumSquaredDifferences = pings.fold(0.0, (sum, ping) {
      final double diff = ping - mean;
      return sum + (diff * diff);
    });
    final double variance = sumSquaredDifferences / pings.length;
    jitter = math.sqrt(variance);
  }
  
  // Calculate packet loss percentage
  final double packetLoss = samples > 0 ? (failedPings / samples) * 100 : 0;
  
  return {
    'ping': avgPing,
    'jitter': jitter,
    'packetLoss': packetLoss,
  };
}

// Limit history to the specified number of entries
Future<void> _limitHistoryEntries(StorageService storageService, int limit) async {
  final results = await storageService.getTestResults();
  
  if (results.length > limit) {
    // Sort by timestamp (newest first)
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Keep only the newest 'limit' entries
    final trimmedResults = results.sublist(0, limit);
    
    // Clear and save the trimmed list
    await storageService.clearTestResults();
    for (final result in trimmedResults) {
      await storageService.saveTestResult(result);
    }
    
    debugPrint('History trimmed to $limit entries');
  }
}

// Perform the background speed test
Future<void> _performBackgroundSpeedTest() async {
  try {
    // Create services
    final connectivityService = ConnectivityService();
    final speedTestService = SpeedTestService(connectivityService);
    final storageService = StorageService();
    
    // Check connectivity
    final isOnline = await connectivityService.isConnected();
    final connectionType = await connectivityService.getCurrentConnectionType();
    if (!isOnline) {
      return; // No connection, exit early
    }
    
    // Get location if permission is granted
    Position? position;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Continue without location
    }
    
    // Perform speed test
    final result = await speedTestService.runSpeedTest();
    
    // Add location data if available
    final Map<String, dynamic> resultJson = result.toJson();
    if (position != null) {
      resultJson['latitude'] = position.latitude;
      resultJson['longitude'] = position.longitude;
    }
    
    // Add additional metrics if available
    // Note: These would typically come from platform-specific code
    // For now, we'll just add placeholders
    resultJson['signalStrength'] = -70; // Example value in dBm
    resultJson['jitter'] = 5.0; // Example value in ms
    resultJson['packetLoss'] = 0.5; // Example value in percentage
    resultJson['connectionType'] = connectionType; // Use the connection type we retrieved
    
    // Create enhanced result
    final enhancedResult = SpeedTestResult.fromJson(resultJson);
    
    // Save result
    await storageService.saveTestResult(enhancedResult);
    debugPrint('Background speed test completed and saved');
    
  } catch (e) {
    debugPrint('Error in background speed test: $e');
  }
}
