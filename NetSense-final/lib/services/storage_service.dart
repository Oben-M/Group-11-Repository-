import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/speed_test_result.dart';
import '../models/feedback_result.dart';

class StorageService {

  static StorageService? _instance;
  static SharedPreferences? _prefs;
  static bool _initializing = false;
  

  factory StorageService() {
    _instance ??= StorageService._internal();
    return _instance!;
  }
  
  StorageService._internal();
  
  static const String _resultsKey = 'speed_test_results';
  static const String _feedbackKey = 'feedback_results';
  static const int _maxResults = 10;
  

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) {
      return _prefs!;
    }
    

    if (_initializing) {

      int attempts = 0;
      while (_prefs == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      if (_prefs != null) {
        return _prefs!;
      }
    }
    

    _initializing = true;
    _prefs = await SharedPreferences.getInstance();
    _initializing = false;
    return _prefs!;
  }
  

  Future<void> saveTestResult(SpeedTestResult result) async {
    final prefs = await _getPrefs();
    

    List<SpeedTestResult> results = await getTestResults();
    

    results.insert(0, result);
    

    if (results.length > _maxResults) {
      results = results.sublist(0, _maxResults);
    }
    

    final jsonList = results.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_resultsKey, jsonList);
  }
  

  Future<List<SpeedTestResult>> getTestResults() async {
    try {
      final prefs = await _getPrefs();
      

      final jsonList = prefs.getStringList(_resultsKey) ?? [];
      

      
      if (jsonList.isEmpty) {
        return [];
      }
      

      List<SpeedTestResult> results = [];
      for (var jsonStr in jsonList) {
        try {
          final Map<String, dynamic> json = jsonDecode(jsonStr);
          results.add(SpeedTestResult.fromJson(json));
        } catch (e) {
          print('StorageService: Error parsing test result: $e');

        }
      }
      

      return results;
    } catch (e) {
      print('StorageService: Critical error getting test results: $e');

      return [];
    }
  }
  

  Future<void> clearTestResults() async {
    final prefs = await _getPrefs();
    await prefs.remove(_resultsKey);
  }
  

  Future<void> createSampleTestResults() async {

    final now = DateTime.now();
    
    final result1 = SpeedTestResult(
      downloadSpeed: 25.5,
      uploadSpeed: 10.2,
      ping: 45,
      connectionType: 'WiFi',
      timestamp: now,
      signalStrength: 3,
      latitude: 37.7749,
      longitude: -122.4194,
    );
    
    final result2 = SpeedTestResult(
      downloadSpeed: 18.7,
      uploadSpeed: 8.5,
      ping: 60,
      connectionType: 'WiFi',
      timestamp: now.subtract(const Duration(hours: 2)),
      signalStrength: 2,
      latitude: 37.7749,
      longitude: -122.4194,
    );
    
    final result3 = SpeedTestResult(
      downloadSpeed: 5.2,
      uploadSpeed: 2.1,
      ping: 120,
      connectionType: 'Mobile Data',
      timestamp: now.subtract(const Duration(days: 1)),
      signalStrength: 1,
      latitude: 37.7749,
      longitude: -122.4194,
    );
    

    await saveTestResult(result1);
    await saveTestResult(result2);
    await saveTestResult(result3);
    

  }
  

  Future<void> saveFeedbackResult(FeedbackResult feedback) async {
    final prefs = await _getPrefs();
    

    List<FeedbackResult> feedbackList = await getFeedbackResults();
    

    feedbackList.insert(0, feedback);
    

    if (feedbackList.length > _maxResults) {
      feedbackList = feedbackList.sublist(0, _maxResults);
    }
    

    final jsonList = feedbackList.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_feedbackKey, jsonList);
  }
  

  Future<List<FeedbackResult>> getFeedbackResults() async {
    final prefs = await _getPrefs();
    
    // Get the stored JSON strings
    final jsonList = prefs.getStringList(_feedbackKey) ?? [];
    

    return jsonList.map((jsonStr) {
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return FeedbackResult.fromJson(json);
    }).toList();
  }
  

  Future<FeedbackResult?> getFeedbackForTestSession(String testSessionId) async {
    final feedbackList = await getFeedbackResults();
    
    try {
      return feedbackList.firstWhere((feedback) => feedback.testSessionId == testSessionId);
    } catch (e) {
      return null;
    }
  }
  

  Future<void> clearFeedbackResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedbackKey);
  }
}
