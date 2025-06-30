import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/speed_test_result.dart';
import 'connectivity_service.dart';

class SpeedTestService {
  final ConnectivityService _connectivityService;
  

  final List<String> _downloadTestServers = [
    'https://speed.cloudflare.com/__down?bytes=10000000',
    'https://speedtest-blr1.digitalocean.com/10mb.test',
    'https://speedtest.atlanta.linode.com/100MB-atlanta.bin',
  ];
  

  final String _uploadTestServer = 'https://speed.cloudflare.com/__up';
  

  final String _pingUrl = 'https://1.1.1.1';
  

  final _downloadProgressController = StreamController<double>.broadcast();
  final _uploadProgressController = StreamController<double>.broadcast();
  final _pingProgressController = StreamController<int>.broadcast();
  

  Stream<double> get downloadProgress => _downloadProgressController.stream;
  Stream<double> get uploadProgress => _uploadProgressController.stream;
  Stream<int> get pingProgress => _pingProgressController.stream;
  

  bool _isCancelled = false;
  
  SpeedTestService(this._connectivityService);
  

  Future<int> testPing({int samples = 3}) async {
    try {
      int totalPing = 0;
      int successfulSamples = 0;
      
      for (int i = 0; i < samples; i++) {
        final stopwatch = Stopwatch()..start();
        
        try {

          await http.get(Uri.parse(_pingUrl));
          stopwatch.stop();
          
          int currentPing = stopwatch.elapsedMilliseconds;
          totalPing += currentPing;
          successfulSamples++;
          

          _pingProgressController.add(currentPing);
          

          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {

          continue;
        }
      }
      

      if (successfulSamples > 0) {
        return (totalPing / successfulSamples).round();
      } else {
        return -1;
      }
    } catch (e) {
      return -1;
    }
  }
  

  Future<double> testDownloadSpeed() async {
    if (!await _connectivityService.isConnected()) {
      return 0.0;
    }
    
    _isCancelled = false;
    final testUrl = _downloadTestServers[0]; // Use the first server by default
    final client = http.Client();
    
    try {
      final stopwatch = Stopwatch()..start();
      int totalBytes = 0;
      double lastReportTime = 0;
      double currentSpeed = 0;
      
      // Start the request
      final request = http.Request('GET', Uri.parse(testUrl));
      final streamedResponse = await client.send(request);
      

      await for (final chunk in streamedResponse.stream) {
        if (_isCancelled) break;
        

        totalBytes += chunk.length;
        

        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
        if (elapsedSeconds - lastReportTime >= 0.2) {
          lastReportTime = elapsedSeconds;
          


          currentSpeed = (totalBytes * 8) / (elapsedSeconds * 1000000);
          

          _downloadProgressController.add(currentSpeed);
          

          if (elapsedSeconds > 5) break;
        }
      }
      
      stopwatch.stop();
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
      

      final speedMbps = (totalBytes * 8) / (elapsedSeconds * 1000000);
      

      _downloadProgressController.add(speedMbps);
      
      return speedMbps;
    } catch (e) {
      debugPrint('Download test exception: ${e.toString()}');
      return 0.0;
    } finally {
      client.close();
    }
  }
  

  Future<double> testUploadSpeed() async {
    if (!await _connectivityService.isConnected()) {
      return 0.0;
    }
    
    _isCancelled = false;
    final client = http.Client();
    
    try {
      final stopwatch = Stopwatch()..start();
      int totalBytesSent = 0;
      double lastReportTime = 0;
      double currentSpeed = 0;
      

      final chunkSize = 512 * 1024;
      final random = Random();
      final dataChunk = Uint8List(chunkSize);
      for (int i = 0; i < chunkSize; i++) {
        dataChunk[i] = random.nextInt(256);
      }
      

      for (int i = 0; i < 10; i++) {
        if (_isCancelled) break;
        

        final response = await client.post(
          Uri.parse(_uploadTestServer),
          body: dataChunk,
        );
        
        if (response.statusCode != 200) {
          debugPrint('Upload error: ${response.statusCode}');
          break;
        }
        

        totalBytesSent += chunkSize;
        
        // Calculate current speed
        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
        if (elapsedSeconds - lastReportTime >= 0.2) {
          lastReportTime = elapsedSeconds;
          

          currentSpeed = (totalBytesSent * 8) / (elapsedSeconds * 1000000);
          

          _uploadProgressController.add(currentSpeed);
        }
        

        if (stopwatch.elapsedMilliseconds > 10000) break;
      }
      
      stopwatch.stop();
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
      

      final speedMbps = (totalBytesSent * 8) / (elapsedSeconds * 1000000);
      

      _uploadProgressController.add(speedMbps);
      
      return speedMbps;
    } catch (e) {
      debugPrint('Upload test exception: ${e.toString()}');
      return 0.0;
    } finally {
      client.close();
    }
  }
  

  Future<Map<String, double?>> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'latitude': null, 'longitude': null};
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return {'latitude': null, 'longitude': null};
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      debugPrint('Error getting location: ${e.toString()}');
      return {'latitude': null, 'longitude': null};
    }
  }
  

  Future<int?> _getSignalStrength() async {


    return null;
  }
  

  Future<SpeedTestResult> runSpeedTest() async {
    final connectionType = await _connectivityService.getCurrentConnectionType();
    

    if (connectionType == 'None') {
      return SpeedTestResult(
        downloadSpeed: 0.0,
        uploadSpeed: 0.0,
        ping: -1,
        connectionType: connectionType,
        timestamp: DateTime.now(),
      );
    }
    

    final locationFuture = _getCurrentLocation();
    final signalStrengthFuture = _getSignalStrength();
    

    final ping = await testPing();
    final downloadSpeed = await testDownloadSpeed();
    final uploadSpeed = await testUploadSpeed();
    

    final location = await locationFuture;
    final signalStrength = await signalStrengthFuture;
    

    return SpeedTestResult(
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      ping: ping,
      connectionType: connectionType,
      timestamp: DateTime.now(),
      signalStrength: signalStrength,
      latitude: location['latitude'],
      longitude: location['longitude'],
    );
  }
  

  void cancelTests() {
    _isCancelled = true;
  }
  

  void dispose() {
    cancelTests();
    _downloadProgressController.close();
    _uploadProgressController.close();
    _pingProgressController.close();
  }
}
