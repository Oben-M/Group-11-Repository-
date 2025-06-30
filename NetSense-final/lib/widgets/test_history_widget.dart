import 'package:flutter/material.dart';
import '../models/speed_test_result.dart';
import 'dart:math' as math;

class TestHistoryWidget extends StatelessWidget {
  final List<SpeedTestResult> testHistory;

  const TestHistoryWidget({
    super.key,
    required this.testHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Test History',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: testHistory.length,
          itemBuilder: (context, index) {
            final result = testHistory[index];
            final qualityRating = result.getQualityRating();
            final qualityColor = _getQualityColor(qualityRating);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: colorScheme.surface,
                  child: InkWell(
                    onTap: () {}, // Could expand to show more details
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with connection type and quality
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            border: Border(
                              left: BorderSide(color: qualityColor, width: 4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Connection type with icon
                              Row(
                                children: [
                                  _buildConnectionIcon(result.connectionType),
                                  const SizedBox(width: 8),
                                  Text(
                                    result.connectionType,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              // Quality badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: qualityColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getQualityIcon(qualityRating),
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      qualityRating,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Speed metrics
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Speed metrics with visual indicators
                              Row(
                                children: [
                                  // Download speed
                                  Expanded(
                                    child: _buildSpeedIndicator(
                                      context: context,
                                      icon: Icons.download_rounded,
                                      iconColor: Colors.blue,
                                      label: 'Download',
                                      value: '${result.downloadSpeed.toStringAsFixed(2)}',
                                      unit: 'Mbps',
                                      percentage: _calculatePercentage(result.downloadSpeed, 50),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // Upload speed
                                  Expanded(
                                    child: _buildSpeedIndicator(
                                      context: context,
                                      icon: Icons.upload_rounded,
                                      iconColor: Colors.green,
                                      label: 'Upload',
                                      value: '${result.uploadSpeed.toStringAsFixed(2)}',
                                      unit: 'Mbps',
                                      percentage: _calculatePercentage(result.uploadSpeed, 20),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Ping and timestamp
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Ping
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.network_ping,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ping: ',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        '${result.ping} ms',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Timestamp
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDateTime(result.timestamp),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConnectionIcon(String connectionType) {
    IconData icon;
    Color color;

    switch (connectionType) {
      case 'WiFi':
        icon = Icons.wifi;
        color = Colors.green;
        break;
      case 'Mobile':
        icon = Icons.signal_cellular_alt;
        color = Colors.blue;
        break;
      case 'Ethernet':
        icon = Icons.lan;
        color = Colors.indigo;
        break;
      case 'None':
        icon = Icons.signal_wifi_off;
        color = Colors.red;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
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
  
  Widget _buildSpeedIndicator({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required double percentage,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Value
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
  
  double _calculatePercentage(double value, double maxValue) {
    // Ensure the percentage is between 0.05 and 1.0
    return math.min(1.0, math.max(0.05, value / maxValue));
  }
}
