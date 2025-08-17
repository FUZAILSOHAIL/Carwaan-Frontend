import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'performance_metrics.dart';
import 'performance_reporter.dart';

class PerformanceService extends GetxService {
  final Map<String, List<int>> _apiResponseTimes = {};
  final Map<String, List<int>> _screenLoadTimes = {};
  final Map<String, List<double>> _memoryUsage = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, int> _successCounts = {};
  final List<NetworkMetric> _networkMetrics = [];
  final List<UserInteractionMetric> _userInteractions = [];
  
  DateTime? _sessionStartTime;
  final PerformanceReporter _reporter = PerformanceReporter();
  
  @override
  void onInit() {
    super.onInit();
    _sessionStartTime = DateTime.now();
    _startPeriodicReporting();
  }
  
  // Track API response times
  void trackApiResponse(String endpoint, int responseTimeMs, {bool isSuccess = true}) {
    _apiResponseTimes.putIfAbsent(endpoint, () => []).add(responseTimeMs);
    
    if (isSuccess) {
      _successCounts[endpoint] = (_successCounts[endpoint] ?? 0) + 1;
    } else {
      _errorCounts[endpoint] = (_errorCounts[endpoint] ?? 0) + 1;
    }
    
    _networkMetrics.add(NetworkMetric(
      endpoint: endpoint,
      responseTime: responseTimeMs,
      timestamp: DateTime.now(),
      isSuccess: isSuccess,
    ));
    
    if (kDebugMode) {
      print('🚀 API Response: $endpoint - ${responseTimeMs}ms - ${isSuccess ? "✅" : "❌"}');
    }
  }
  
  // Track screen load times
  void trackScreenLoad(String screenName, int loadTimeMs) {
    _screenLoadTimes.putIfAbsent(screenName, () => []).add(loadTimeMs);
    
    if (kDebugMode) {
      print('📱 Screen Load: $screenName - ${loadTimeMs}ms');
    }
  }
  
  // Track memory usage
  void trackMemoryUsage(String context, double memoryMB) {
    _memoryUsage.putIfAbsent(context, () => []).add(memoryMB);
    
    if (kDebugMode) {
      print('💾 Memory Usage: $context - ${memoryMB.toStringAsFixed(2)}MB');
    }
  }
  
  // Track user interactions
  void trackUserInteraction(String action, String screen, {Map<String, dynamic>? metadata}) {
    _userInteractions.add(UserInteractionMetric(
      action: action,
      screen: screen,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
    
    if (kDebugMode) {
      print('👆 User Interaction: $action on $screen');
    }
  }
  
  // Calculate precision for a specific endpoint
  double calculatePrecision(String endpoint) {
    final successes = _successCounts[endpoint] ?? 0;
    final errors = _errorCounts[endpoint] ?? 0;
    final total = successes + errors;
    
    return total > 0 ? successes / total : 0.0;
  }
  
  // Calculate accuracy (overall success rate)
  double calculateAccuracy() {
    final totalSuccesses = _successCounts.values.fold(0, (sum, count) => sum + count);
    final totalErrors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    final total = totalSuccesses + totalErrors;
    
    return total > 0 ? totalSuccesses / total : 0.0;
  }
  
  // Calculate recall (how many of available operations were successful)
  double calculateRecall(String endpoint) {
    // For ride-sharing app, this could be:
    // - For ride booking: successful bookings / total ride requests
    // - For driver matching: successful matches / total available drivers
    final responses = _apiResponseTimes[endpoint]?.length ?? 0;
    final successes = _successCounts[endpoint] ?? 0;
    
    return responses > 0 ? successes / responses : 0.0;
  }
  
  // Calculate TNR (True Negative Rate) - for error handling
  double calculateTNR() {
    // This represents how well the app handles invalid operations
    final totalOperations = _getTotalOperations();
    final totalErrors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    
    return totalOperations > 0 ? (totalOperations - totalErrors) / totalOperations : 0.0;
  }
  
  int _getTotalOperations() {
    final successes = _successCounts.values.fold(0, (sum, count) => sum + count);
    final errors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    return successes + errors;
  }
  
  // Get comprehensive performance summary
  PerformanceMetrics getPerformanceMetrics() {
    return PerformanceMetrics(
      avgApiResponseTime: _calculateAverage(_getAllApiResponseTimes()),
      avgScreenLoadTime: _calculateAverage(_getAllScreenLoadTimes()),
      avgMemoryUsage: _calculateAverage(_getAllMemoryUsages()),
      slowestApi: _getSlowestApi(),
      slowestScreen: _getSlowestScreen(),
      highestMemoryUsage: _getHighestMemoryUsage(),
      totalApiCalls: _getTotalApiCalls(),
      totalScreenLoads: _getTotalScreenLoads(),
      errorRate: _calculateErrorRate(),
      sessionDuration: _getSessionDuration(),
      precision: _calculateOverallPrecision(),
      accuracy: calculateAccuracy(),
      recall: _calculateOverallRecall(),
      tnr: calculateTNR(),
      networkMetrics: List.from(_networkMetrics),
      userInteractions: List.from(_userInteractions),
    );
  }
  
  double _calculateAverage(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  List<int> _getAllApiResponseTimes() {
    return _apiResponseTimes.values.expand((list) => list).toList();
  }
  
  List<int> _getAllScreenLoadTimes() {
    return _screenLoadTimes.values.expand((list) => list).toList();
  }
  
  List<double> _getAllMemoryUsages() {
    return _memoryUsage.values.expand((list) => list).toList();
  }
  
  String? _getSlowestApi() {
    if (_apiResponseTimes.isEmpty) return null;
    
    String? slowestEndpoint;
    int maxTime = 0;
    
    _apiResponseTimes.forEach((endpoint, times) {
      final maxTimeForEndpoint = times.reduce((a, b) => a > b ? a : b);
      if (maxTimeForEndpoint > maxTime) {
        maxTime = maxTimeForEndpoint;
        slowestEndpoint = endpoint;
      }
    });
    
    return slowestEndpoint;
  }
  
  String? _getSlowestScreen() {
    if (_screenLoadTimes.isEmpty) return null;
    
    String? slowestScreen;
    int maxTime = 0;
    
    _screenLoadTimes.forEach((screen, times) {
      final maxTimeForScreen = times.reduce((a, b) => a > b ? a : b);
      if (maxTimeForScreen > maxTime) {
        maxTime = maxTimeForScreen;
        slowestScreen = screen;
      }
    });
    
    return slowestScreen;
  }
  
  String? _getHighestMemoryUsage() {
    if (_memoryUsage.isEmpty) return null;
    
    String? highestContext;
    double maxMemory = 0.0;
    
    _memoryUsage.forEach((context, usages) {
      final maxUsageForContext = usages.reduce((a, b) => a > b ? a : b);
      if (maxUsageForContext > maxMemory) {
        maxMemory = maxUsageForContext;
        highestContext = context;
      }
    });
    
    return highestContext;
  }
  
  int _getTotalApiCalls() {
    return _apiResponseTimes.values.fold(0, (sum, list) => sum + list.length);
  }
  
  int _getTotalScreenLoads() {
    return _screenLoadTimes.values.fold(0, (sum, list) => sum + list.length);
  }
  
  double _calculateErrorRate() {
    final totalErrors = _errorCounts.values.fold(0, (sum, count) => sum + count);
    final totalOperations = _getTotalOperations();
    
    return totalOperations > 0 ? totalErrors / totalOperations : 0.0;
  }
  
  Duration _getSessionDuration() {
    return _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;
  }
  
  double _calculateOverallPrecision() {
    final allEndpoints = {..._successCounts.keys, ..._errorCounts.keys};
    if (allEndpoints.isEmpty) return 0.0;
    
    double totalPrecision = 0.0;
    for (final endpoint in allEndpoints) {
      totalPrecision += calculatePrecision(endpoint);
    }
    
    return totalPrecision / allEndpoints.length;
  }
  
  double _calculateOverallRecall() {
    final allEndpoints = _apiResponseTimes.keys;
    if (allEndpoints.isEmpty) return 0.0;
    
    double totalRecall = 0.0;
    for (final endpoint in allEndpoints) {
      totalRecall += calculateRecall(endpoint);
    }
    
    return totalRecall / allEndpoints.length;
  }
  
  // Generate HTML report
  Future<void> generateHtmlReport() async {
    final metrics = getPerformanceMetrics();
    await _reporter.generateHtmlReport(metrics);
  }
  
  // Start periodic reporting (every 5 minutes)
  void _startPeriodicReporting() {
    if (!kDebugMode) return;
    
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _logPerformanceSummary();
    });
  }
  
  void _logPerformanceSummary() {
    final metrics = getPerformanceMetrics();
    print('\n📊 === PERFORMANCE SUMMARY ===');
    print('⏱️  Avg API Response: ${metrics.avgApiResponseTime.toStringAsFixed(2)}ms');
    print('📱 Avg Screen Load: ${metrics.avgScreenLoadTime.toStringAsFixed(2)}ms');
    print('💾 Avg Memory Usage: ${metrics.avgMemoryUsage.toStringAsFixed(2)}MB');
    print('🎯 Precision: ${(metrics.precision * 100).toStringAsFixed(2)}%');
    print('🎯 Accuracy: ${(metrics.accuracy * 100).toStringAsFixed(2)}%');
    print('🎯 Recall: ${(metrics.recall * 100).toStringAsFixed(2)}%');
    print('❌ Error Rate: ${(metrics.errorRate * 100).toStringAsFixed(2)}%');
    print('⏰ Session Duration: ${metrics.sessionDuration.inMinutes}m ${metrics.sessionDuration.inSeconds % 60}s');
    print('================================\n');
  }
  
  // Clear all metrics (useful for testing)
  void clearMetrics() {
    _apiResponseTimes.clear();
    _screenLoadTimes.clear();
    _memoryUsage.clear();
    _errorCounts.clear();
    _successCounts.clear();
    _networkMetrics.clear();
    _userInteractions.clear();
    _sessionStartTime = DateTime.now();
  }
}
