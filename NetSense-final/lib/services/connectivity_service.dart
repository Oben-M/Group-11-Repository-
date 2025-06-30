import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  // Stream controller to broadcast connectivity changes
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();
  
  // Stream to listen to
  Stream<String> get connectionStatus => _connectionStatusController.stream;

  ConnectivityService() {
    // Initialize the connectivity service and listen for changes
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Initialize connectivity
  Future<void> _initConnectivity() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _connectionStatusController.add('None');
    }
  }

  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _connectionStatusController.add('WiFi');
        break;
      case ConnectivityResult.mobile:
        _connectionStatusController.add('Mobile');
        break;
      case ConnectivityResult.none:
        _connectionStatusController.add('None');
        break;
      default:
        _connectionStatusController.add('None');
        break;
    }
  }

  // Get current connection type
  Future<String> getCurrentConnectionType() async {
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.none:
        return 'None';
      default:
        return 'None';
    }
  }

  // Check if device is connected to the internet
  Future<bool> isConnected() async {
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Dispose resources
  void dispose() {
    _connectionStatusController.close();
  }
}
