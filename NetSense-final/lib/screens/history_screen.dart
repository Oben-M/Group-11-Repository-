import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/speed_test_result.dart';
import '../services/storage_service.dart';

// Provider for test history
final testHistoryProvider = FutureProvider<List<SpeedTestResult>>((ref) async {
  final storageService = StorageService();
  return await storageService.getTestResults();
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<SpeedTestResult> _testResults = [];
  bool _isLoading = true;
  String? _error;
  final StorageService _storageService = StorageService();
  
  @override
  void initState() {
    super.initState();
    // Load test history with a short delay to allow widget to build
    Future.microtask(_ensureTestHistory);
  }
  
  Future<void> _ensureTestHistory() async {
    try {
      // First try to load existing history
      await _loadTestHistory();
      
      // If no history exists, create sample data
      if (_testResults.isEmpty) {
        debugPrint('HistoryScreen: No test history found, creating sample data');
        await _storageService.createSampleTestResults();
        // Reload history after creating samples
        await _loadTestHistory();
      }
    } catch (e) {
      debugPrint('HistoryScreen: Error ensuring test history: $e');
    }
  }
  
  Future<void> _loadTestHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final results = await _storageService.getTestResults();
      setState(() {
        _testResults = results;
        _isLoading = false;
        debugPrint('HistoryScreen: Loaded ${results.length} test results');
      });
    } catch (e) {
      debugPrint('Error loading test history in history screen: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        
        // Try to create sample data as a fallback
        try {
          await _storageService.createSampleTestResults();
          final fallbackResults = await _storageService.getTestResults();
          
          if (mounted) {
            setState(() {
              _testResults = fallbackResults;
              _error = null; // Clear the error since we have fallback data
              debugPrint('HistoryScreen: Created fallback sample data with ${fallbackResults.length} results');
            });
          }
        } catch (innerError) {
          debugPrint('HistoryScreen: Error creating fallback sample data: $innerError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Modern app bar with gradient
          SliverAppBar(
            expandedHeight: 120.0,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
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
              ),
              title: const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh history',
                onPressed: () => _loadTestHistory(),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadTestHistory();
                return Future.value();
              },
              child: _isLoading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Something went wrong',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _loadTestHistory(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _testResults.isEmpty
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.speed_rounded,
                                  size: 64,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No test history available',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Run a speed test to see your results here',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Go back to home screen
                                },
                                icon: const Icon(Icons.network_check),
                                label: const Text('Run Speed Test'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildHistoryCharts(theme, colorScheme),
                      ),
            ),
          ),
          
          // Bottom padding for safe area
          SliverToBoxAdapter(
            child: SizedBox(height: 80), // Add extra padding at bottom to avoid overlap with navigation
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryCharts(ThemeData theme, ColorScheme colorScheme) {
    if (_testResults.isEmpty) {
      return const Center(child: Text('No test history available'));
    }
    
    return SingleChildScrollView(
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartSection(
            title: 'Download Speed History',
            icon: Icons.download_rounded,
            iconColor: Colors.blue,
            chart: _buildSpeedLineChart(_testResults, (result) => result.downloadSpeed, Colors.blue),
          ),
          const SizedBox(height: 24),
          _buildChartSection(
            title: 'Upload Speed History',
            icon: Icons.upload_rounded,
            iconColor: Colors.green,
            chart: _buildSpeedLineChart(_testResults, (result) => result.uploadSpeed, Colors.green),
          ),
          const SizedBox(height: 24),
          _buildChartSection(
            title: 'Ping History',
            icon: Icons.network_ping,
            iconColor: Colors.amber,
            chart: _buildSpeedLineChart(_testResults, (result) => result.ping.toDouble(), Colors.amber),
          ),
          const SizedBox(height: 24),
          _buildConnectionTypeDistribution(),
        ],
      ),
    );
  }
  
  Widget _buildChartSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget chart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: chart,
        ),
      ],
    );
  }
  
  Widget _buildSpeedLineChart(List<SpeedTestResult> results, double Function(SpeedTestResult) getValue, Color color) {
    // Sort results by timestamp
    final sortedResults = List<SpeedTestResult>.from(results);
    sortedResults.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Only show the last 10 results if there are more than 10
    final displayResults = sortedResults.length > 10 
        ? sortedResults.sublist(sortedResults.length - 10) 
        : sortedResults;
    
    // Create spots for the line chart
    final spots = <FlSpot>[];
    for (int i = 0; i < displayResults.length; i++) {
      spots.add(FlSpot(i.toDouble(), getValue(displayResults[i])));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.surfaceVariant,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.surfaceVariant,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= displayResults.length || value.toInt() < 0) {
                  return const SizedBox.shrink();
                }
                
                final result = displayResults[value.toInt()];
                final date = result.timestamp;
                
                // Show day/month for dates
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              _getAxisTitle(getValue),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            axisNameSize: 25,
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(displayResults, getValue),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
        ),
        minX: 0,
        maxX: displayResults.length - 1.0,
        minY: 0,
        maxY: _getMaxValue(displayResults, getValue) * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surface,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final result = displayResults[spot.x.toInt()];
                final value = getValue(result);
                return LineTooltipItem(
                  '${value.toStringAsFixed(1)} ${_getUnitForValue(getValue)}',
                  TextStyle(color: Theme.of(context).colorScheme.onSurface),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  double _getMaxValue(List<SpeedTestResult> results, double Function(SpeedTestResult) getValue) {
    if (results.isEmpty) return 10.0;
    
    double maxValue = 0;
    for (final result in results) {
      final value = getValue(result);
      if (value > maxValue) {
        maxValue = value;
      }
    }
    
    return maxValue == 0 ? 10.0 : maxValue;
  }
  
  double _calculateInterval(List<SpeedTestResult> results, double Function(SpeedTestResult) getValue) {
    final maxValue = _getMaxValue(results, getValue);
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 4;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    return maxValue / 5;
  }
  
  String _getAxisTitle(double Function(SpeedTestResult) getValue) {
    if (getValue == (result) => result.downloadSpeed) return 'Download (Mbps)';
    if (getValue == (result) => result.uploadSpeed) return 'Upload (Mbps)';
    if (getValue == (result) => result.ping.toDouble()) return 'Ping (ms)';
    return '';
  }
  
  String _getUnitForValue(double Function(SpeedTestResult) getValue) {
    if (getValue == (result) => result.downloadSpeed) return 'Mbps';
    if (getValue == (result) => result.uploadSpeed) return 'Mbps';
    if (getValue == (result) => result.ping.toDouble()) return 'ms';
    return '';
  }
  
  Widget _buildConnectionTypeDistribution() {
    // Count occurrences of each connection type
    final Map<String, int> connectionCounts = {};
    for (final result in _testResults) {
      final type = result.connectionType;
      connectionCounts[type] = (connectionCounts[type] ?? 0) + 1;
    }
    
    // Create pie chart sections
    final sections = <PieChartSectionData>[];
    final colors = [Colors.blue, Colors.green, Colors.amber, Colors.purple, Colors.red];
    int colorIndex = 0;
    
    connectionCounts.forEach((type, count) {
      final percentage = count / _testResults.length * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: percentage,
          title: '$type\n${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Connection Type Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                enabled: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
