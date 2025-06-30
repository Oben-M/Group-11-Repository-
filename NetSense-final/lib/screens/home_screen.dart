import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/speed_test_result.dart';
import '../services/connectivity_service.dart';
import '../services/speed_test_service.dart';
import '../services/storage_service.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/speed_test_result_widget.dart';
import '../widgets/test_history_widget.dart';
import 'feedback_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  late final SpeedTestService _speedTestService;
  final StorageService _storageService = StorageService();
  
  bool _isTestRunning = false;
  bool _isLoading = true; // Add loading state
  String _connectionType = 'Unknown';
  SpeedTestResult? _currentResult;
  List<SpeedTestResult> _testHistory = [];
  
  @override
  void initState() {
    super.initState();
    _speedTestService = SpeedTestService(_connectivityService);
    _loadInitialData();
    
    // Listen for connectivity changes
    _connectivityService.connectionStatus.listen((status) {
      setState(() {
        _connectionType = status;
      });
    });
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true; // Set loading state to true before fetching data
    });
    
    try {
      // Get connection type
      final connectionType = await _connectivityService.getCurrentConnectionType();
      
      // Get test history
      final testHistory = await _storageService.getTestResults();
      
      if (mounted) {
        setState(() {
          _connectionType = connectionType;
          _testHistory = testHistory;
          if (testHistory.isNotEmpty) {
            _currentResult = testHistory.first;
          }
          _isLoading = false; // Set loading state to false after data is fetched
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading state to false even if there's an error
        });
      }
    }
  }
  
  Future<void> _runSpeedTest() async {
    if (_isTestRunning) return;
    
    setState(() {
      _isTestRunning = true;
      // Don't set _currentResult to null here to prevent flashing
    });
    
    try {
      // Run the speed test
      final result = await _speedTestService.runSpeedTest();
      
      // Save the result
      await _storageService.saveTestResult(result);
      
      // Update the UI
      final testHistory = await _storageService.getTestResults();
      
      setState(() {
        _currentResult = result;
        _testHistory = testHistory;
      });
      
      // Show feedback prompt after a short delay
      // Using mounted check to avoid using build context after async gap
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showFeedbackPrompt(result);
          }
        });
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error running speed test: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('NETSENSE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh connection',
            onPressed: () async {
              final connectionType = await _connectivityService.getCurrentConnectionType();
              setState(() {
                _connectionType = connectionType;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connection refreshed: $_connectionType')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Connection status indicator with modern design
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ConnectionStatusWidget(connectionType: _connectionType),
                        ),
                        
                        // Current test result or placeholder with improved UI
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildMainContent(theme),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Start test button with modern design
                        _buildSpeedTestButton(theme),
                        
                        const SizedBox(height: 24),
                        
                        // Test history with improved UI
                        if (_testHistory.isNotEmpty)
                          TestHistoryWidget(testHistory: _testHistory),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildMainContent(ThemeData theme) {
    // Show loading indicator while data is being fetched
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we load your data',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (_isTestRunning) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Running Speed Test...',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we analyze your connection',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (_currentResult != null) {
      return SpeedTestResultWidget(result: _currentResult!);
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.speed,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'No Test Results Yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to start your first network speed test',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildSpeedTestButton(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isTestRunning ? [] : [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isTestRunning ? null : _runSpeedTest,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.6),
          disabledForegroundColor: Colors.white70,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTestRunning ? Icons.hourglass_top : Icons.speed,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _isTestRunning ? 'Testing...' : 'Start Speed Test',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show feedback prompt
  void _showFeedbackPrompt(SpeedTestResult result) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeedbackScreen(testResult: result),
      ),
    );
  }
  
  @override
  void dispose() {
    _connectivityService.dispose();
    _speedTestService.dispose();
    super.dispose();
  }
}
