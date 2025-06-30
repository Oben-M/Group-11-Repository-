import 'package:flutter/material.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final String connectionType;

  const ConnectionStatusWidget({
    super.key,
    required this.connectionType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Define connection properties based on type
    final ConnectionInfo info = _getConnectionInfo(connectionType);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              info.color.withOpacity(0.1),
              theme.cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              // Animated connection icon
              _buildConnectionIcon(info),
              const SizedBox(width: 16),
              
              // Connection details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          info.statusText,
                          style: TextStyle(
                            color: info.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (info.speedIndicator != null) ...[  
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: info.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              info.speedIndicator!,
                              style: TextStyle(
                                fontSize: 12,
                                color: info.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildConnectionIcon(ConnectionInfo info) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          info.icon,
          color: info.color,
          size: 24,
        ),
      ),
    );
  }
  
  ConnectionInfo _getConnectionInfo(String type) {
    switch (type) {
      case 'WiFi':
        return ConnectionInfo(
          color: const Color(0xFF43A047),
          icon: Icons.wifi,
          statusText: 'Connected to WiFi',
          speedIndicator: 'Fast',
        );
      case 'Mobile':
        return ConnectionInfo(
          color: const Color(0xFFFB8C00),
          icon: Icons.signal_cellular_alt,
          statusText: 'Mobile Data',
          speedIndicator: 'Variable',
        );
      case 'None':
        return ConnectionInfo(
          color: const Color(0xFFE53935),
          icon: Icons.signal_wifi_off,
          statusText: 'No Internet Connection',
          speedIndicator: null,
        );
      default:
        return ConnectionInfo(
          color: const Color(0xFF757575),
          icon: Icons.help_outline,
          statusText: 'Checking Connection...',
          speedIndicator: null,
        );
    }
  }
}

class ConnectionInfo {
  final Color color;
  final IconData icon;
  final String statusText;
  final String? speedIndicator;
  
  ConnectionInfo({
    required this.color,
    required this.icon,
    required this.statusText,
    this.speedIndicator,
  });
}
