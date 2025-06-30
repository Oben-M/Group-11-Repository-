class SpeedTestResult {
  final double downloadSpeed;
  final double uploadSpeed;
  final int ping;
  final String connectionType;
  final DateTime timestamp;
  final int? signalStrength;
  final double? latitude;
  final double? longitude;
  final String? estimatedRating;
  final double? jitter;
  final double? packetLoss;

  SpeedTestResult({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    required this.connectionType,
    required this.timestamp,
    this.signalStrength,
    this.latitude,
    this.longitude,
    this.jitter,
    this.packetLoss,
    String? estimatedRating,
  }) : this.estimatedRating = estimatedRating ?? _calculateRating(downloadSpeed, uploadSpeed, ping);


  Map<String, dynamic> toJson() {
    return {
      'downloadSpeed': downloadSpeed,
      'uploadSpeed': uploadSpeed,
      'ping': ping,
      'connectionType': connectionType,
      'timestamp': timestamp.toIso8601String(),
      'signalStrength': signalStrength,
      'latitude': latitude,
      'longitude': longitude,
      'jitter': jitter,
      'packetLoss': packetLoss,
      'estimatedRating': estimatedRating,
    };
  }


  factory SpeedTestResult.fromJson(Map<String, dynamic> json) {
    return SpeedTestResult(
      downloadSpeed: json['downloadSpeed'],
      uploadSpeed: json['uploadSpeed'],
      ping: json['ping'],
      connectionType: json['connectionType'],
      timestamp: DateTime.parse(json['timestamp']),
      signalStrength: json['signalStrength'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      jitter: json['jitter'],
      packetLoss: json['packetLoss'],
      estimatedRating: json['estimatedRating'],
    );
  }


  String getQualityRating() {
    return estimatedRating ?? _calculateRating(downloadSpeed, uploadSpeed, ping);
  }
  

  static String _calculateRating(double downloadSpeed, double uploadSpeed, int ping) {

    if (downloadSpeed <= 0 || uploadSpeed <= 0 || ping < 0) {
      return 'No Internet';
    }
    

    const double goodDownloadThreshold = 15.0;
    const double moderateDownloadThreshold = 5.0;
    const double goodUploadThreshold = 5.0;
    const double moderateUploadThreshold = 2.0;
    const int goodPingThreshold = 50;
    const int moderatePingThreshold = 150;
    
    int goodCriteriaMet = 0;
    if (downloadSpeed >= goodDownloadThreshold) goodCriteriaMet++;
    if (uploadSpeed >= goodUploadThreshold) goodCriteriaMet++;
    if (ping <= goodPingThreshold) goodCriteriaMet++;
    
    if (goodCriteriaMet >= 2) {
      return 'Good';
    }
  
    
    if (downloadSpeed < moderateDownloadThreshold || 
        uploadSpeed < moderateUploadThreshold || 
        ping > moderatePingThreshold) {
      return 'Poor';
    }
    

    return 'Moderate';
  }
}
