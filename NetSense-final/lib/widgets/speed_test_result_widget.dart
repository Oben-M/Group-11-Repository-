import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/speed_test_result.dart';

class SpeedTestResultWidget extends StatelessWidget {
  final SpeedTestResult result;

  const SpeedTestResultWidget({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final qualityRating = result.getQualityRating();
    final Color qualityColor = _getQualityColor(qualityRating);
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header with quality rating
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [qualityColor, qualityColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Test Results',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _getQualityIcon(qualityRating),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      qualityRating,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Connection type chip with icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getConnectionIcon(result.connectionType),
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    result.connectionType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(result.timestamp),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Speed metrics in cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Download',
                    '${result.downloadSpeed.toStringAsFixed(2)}',
                    'Mbps',
                    Icons.download,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Upload',
                    '${result.uploadSpeed.toStringAsFixed(2)}',
                    'Mbps',
                    Icons.upload,
                    theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Ping',
                    _formatLargeNumber(result.ping),
                    'ms',
                    Icons.network_ping,
                    theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Chart
            SizedBox(
              height: 180,
              child: _buildSpeedChart(),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpeedChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(enabled: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: result.downloadSpeed,
                color: Colors.blue,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: result.uploadSpeed,
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Download';
                    break;
                  case 1:
                    text = 'Upload';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _getMaxY() / 5,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
  
  double _getMaxY() {
    final max = result.downloadSpeed > result.uploadSpeed
        ? result.downloadSpeed
        : result.uploadSpeed;
    
    // Round up to the nearest 5 for a cleaner chart
    return ((max / 5).ceil() * 5).toDouble() + 5;
  }
  
  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'Good':
        return Colors.green.shade600;
      case 'Moderate':
        return Colors.amber.shade700;
      case 'Poor':
        return Colors.orange.shade700;
      case 'No Internet':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
  
  IconData _getQualityIcon(String quality) {
    switch (quality) {
      case 'Good':
        return Icons.sentiment_very_satisfied;
      case 'Moderate':
        return Icons.sentiment_satisfied;
      case 'Poor':
        return Icons.sentiment_dissatisfied;
      case 'No Internet':
        return Icons.signal_wifi_off;
      default:
        return Icons.help_outline;
    }
  }
  
  IconData _getConnectionIcon(String connectionType) {
    switch (connectionType) {
      case 'WiFi':
        return Icons.wifi;
      case 'Mobile':
        return Icons.signal_cellular_alt;
      case 'Ethernet':
        return Icons.lan;
      case 'None':
        return Icons.signal_wifi_off;
      default:
        return Icons.device_unknown;
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  String _formatLargeNumber(int number) {
    // Format large numbers to be more readable and avoid overflow
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toString();
    }
  }
}
