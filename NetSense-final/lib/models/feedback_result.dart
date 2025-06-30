class FeedbackResult {
  final int overallSatisfaction;
  final int responsiveness;
  final int usability;
  final String? comment;
  final DateTime timestamp;
  final String testSessionId;

  FeedbackResult({
    required this.overallSatisfaction,
    required this.responsiveness,
    required this.usability,
    this.comment,
    required this.timestamp,
    required this.testSessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'overallSatisfaction': overallSatisfaction,
      'responsiveness': responsiveness,
      'usability': usability,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
      'testSessionId': testSessionId,
    };
  }


  factory FeedbackResult.fromJson(Map<String, dynamic> json) {
    return FeedbackResult(
      overallSatisfaction: json['overallSatisfaction'],
      responsiveness: json['responsiveness'],
      usability: json['usability'],
      comment: json['comment'],
      timestamp: DateTime.parse(json['timestamp']),
      testSessionId: json['testSessionId'],
    );
  }
}
