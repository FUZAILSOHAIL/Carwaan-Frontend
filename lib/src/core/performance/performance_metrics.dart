import 'dart:convert';

class PerformanceMetrics {
  final double avgApiResponseTime;
  final double avgScreenLoadTime;
  final double avgMemoryUsage;
  final String? slowestApi;
  final String? slowestScreen;
  final String? highestMemoryUsage;
  final int totalApiCalls;
  final int totalScreenLoads;
  final double errorRate;
  final Duration sessionDuration;
  final double precision;
  final double accuracy;
  final double recall;
  final double tnr;
  final List<NetworkMetric> networkMetrics;
  final List<UserInteractionMetric> userInteractions;

  PerformanceMetrics({
    required this.avgApiResponseTime,
    required this.avgScreenLoadTime,
    required this.avgMemoryUsage,
    this.slowestApi,
    this.slowestScreen,
    this.highestMemoryUsage,
    required this.totalApiCalls,
    required this.totalScreenLoads,
    required this.errorRate,
    required this.sessionDuration,
    required this.precision,
    required this.accuracy,
    required this.recall,
    required this.tnr,
    required this.networkMetrics,
    required this.userInteractions,
  });

  Map<String, dynamic> toJson() {
    return {
      'avgApiResponseTime': avgApiResponseTime,
      'avgScreenLoadTime': avgScreenLoadTime,
      'avgMemoryUsage': avgMemoryUsage,
      'slowestApi': slowestApi,
      'slowestScreen': slowestScreen,
      'highestMemoryUsage': highestMemoryUsage,
      'totalApiCalls': totalApiCalls,
      'totalScreenLoads': totalScreenLoads,
      'errorRate': errorRate,
      'sessionDurationMs': sessionDuration.inMilliseconds,
      'precision': precision,
      'accuracy': accuracy,
      'recall': recall,
      'tnr': tnr,
      'networkMetrics': networkMetrics.map((m) => m.toJson()).toList(),
      'userInteractions': userInteractions.map((m) => m.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class NetworkMetric {
  final String endpoint;
  final int responseTime;
  final DateTime timestamp;
  final bool isSuccess;

  NetworkMetric({
    required this.endpoint,
    required this.responseTime,
    required this.timestamp,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'responseTime': responseTime,
      'timestamp': timestamp.toIso8601String(),
      'isSuccess': isSuccess,
    };
  }
}

class UserInteractionMetric {
  final String action;
  final String screen;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  UserInteractionMetric({
    required this.action,
    required this.screen,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'screen': screen,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class PerformanceDataset {
  final String name;
  final double precision;
  final double accuracy;
  final double recall;
  final double tnr;
  final String qualityRating;

  PerformanceDataset({
    required this.name,
    required this.precision,
    required this.accuracy,
    required this.recall,
    required this.tnr,
    required this.qualityRating,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'precision': precision,
      'accuracy': accuracy,
      'recall': recall,
      'tnr': tnr,
      'qualityRating': qualityRating,
    };
  }

  // Convert metrics to quality ratings based on performance thresholds
  static String getQualityRating(double value) {
    if (value >= 0.9) return 'Excellent';
    if (value >= 0.8) return 'Good';
    if (value >= 0.7) return 'Average';
    if (value >= 0.6) return 'Below Average';
    return 'Poor';
  }
}
