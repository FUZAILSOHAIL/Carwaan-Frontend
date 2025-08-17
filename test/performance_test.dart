import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:carwaan/src/core/performance/performance_service.dart';
import 'package:carwaan/src/core/performance/performance_metrics.dart';

void main() {
  group('Performance Service Tests', () {
    late PerformanceService performanceService;

    setUp(() {
      Get.reset();
      performanceService = PerformanceService();
      Get.put(performanceService, permanent: true);
    });

    tearDown(() {
      Get.reset();
    });

    test('should track API response times', () {
      // Arrange
      const endpoint = '/api/rides';
      const responseTime = 250;

      // Act
      performanceService.trackApiResponse(endpoint, responseTime, isSuccess: true);

      // Assert
      final metrics = performanceService.getPerformanceMetrics();
      expect(metrics.avgApiResponseTime, equals(250.0));
      expect(metrics.totalApiCalls, equals(1));
    });

    test('should track screen load times', () {
      // Arrange
      const screenName = 'DashboardScreen';
      const loadTime = 850;

      // Act
      performanceService.trackScreenLoad(screenName, loadTime);

      // Assert
      final metrics = performanceService.getPerformanceMetrics();
      expect(metrics.avgScreenLoadTime, equals(850.0));
      expect(metrics.totalScreenLoads, equals(1));
    });

    test('should calculate precision correctly', () {
      // Arrange
      const endpoint = '/api/booking';

      // Act - 3 successful, 1 failed
      performanceService.trackApiResponse(endpoint, 200, isSuccess: true);
      performanceService.trackApiResponse(endpoint, 300, isSuccess: true);
      performanceService.trackApiResponse(endpoint, 500, isSuccess: false);
      performanceService.trackApiResponse(endpoint, 250, isSuccess: true);

      // Assert
      final precision = performanceService.calculatePrecision(endpoint);
      expect(precision, equals(0.75)); // 3 successes out of 4 total
    });

    test('should calculate accuracy correctly', () {
      // Arrange & Act
      performanceService.trackApiResponse('/api/rides', 200, isSuccess: true);
      performanceService.trackApiResponse('/api/booking', 300, isSuccess: true);
      performanceService.trackApiResponse('/api/profile', 500, isSuccess: false);

      // Assert
      final accuracy = performanceService.calculateAccuracy();
      expect(accuracy, closeTo(0.667, 0.001)); // 2 successes out of 3 total
    });

    test('should track memory usage', () {
      // Arrange
      const context = 'RideBooking';
      const memoryUsage = 145.7;

      // Act
      performanceService.trackMemoryUsage(context, memoryUsage);

      // Assert
      final metrics = performanceService.getPerformanceMetrics();
      expect(metrics.avgMemoryUsage, equals(145.7));
    });

    test('should track user interactions', () {
      // Arrange
      const action = 'button_press';
      const screen = 'LoginScreen';
      final metadata = {'button': 'login_submit'};

      // Act
      performanceService.trackUserInteraction(action, screen, metadata: metadata);

      // Assert
      final metrics = performanceService.getPerformanceMetrics();
      expect(metrics.userInteractions.length, equals(1));
      expect(metrics.userInteractions.first.action, equals(action));
      expect(metrics.userInteractions.first.screen, equals(screen));
      expect(metrics.userInteractions.first.metadata, equals(metadata));
    });

    test('should identify slowest API endpoint', () {
      // Arrange & Act
      performanceService.trackApiResponse('/api/fast', 100, isSuccess: true);
      performanceService.trackApiResponse('/api/slow', 2000, isSuccess: true);
      performanceService.trackApiResponse('/api/medium', 500, isSuccess: true);
      performanceService.trackApiResponse('/api/slow', 1800, isSuccess: true);

      // Assert
      final metrics = performanceService.getPerformanceMetrics();
      expect(metrics.slowestApi, equals('/api/slow'));
    });

    test('should clear all metrics', () {
      // Arrange
      performanceService.trackApiResponse('/api/test', 200, isSuccess: true);
      performanceService.trackScreenLoad('TestScreen', 500);
      performanceService.trackMemoryUsage('TestContext', 100.0);

      // Act
      performanceService.clearMetrics();

      // Assert
      final metrics = performanceService.getPerformanceMetrics();
      expect(metrics.avgApiResponseTime, equals(0.0));
      expect(metrics.avgScreenLoadTime, equals(0.0));
      expect(metrics.avgMemoryUsage, equals(0.0));
      expect(metrics.totalApiCalls, equals(0));
      expect(metrics.totalScreenLoads, equals(0));
    });

    test('should calculate TNR (True Negative Rate)', () {
      // Arrange & Act - Mix of successes and failures
      performanceService.trackApiResponse('/api/endpoint1', 200, isSuccess: true);
      performanceService.trackApiResponse('/api/endpoint2', 300, isSuccess: true);
      performanceService.trackApiResponse('/api/endpoint3', 500, isSuccess: false);
      performanceService.trackApiResponse('/api/endpoint4', 250, isSuccess: true);
      performanceService.trackApiResponse('/api/endpoint5', 600, isSuccess: false);

      // Assert - TNR should be (total - errors) / total = (5 - 2) / 5 = 0.6
      final tnr = performanceService.calculateTNR();
      expect(tnr, equals(0.6));
    });

    test('should provide comprehensive performance metrics', () {
      // Arrange - Create a realistic performance scenario
      // API calls
      performanceService.trackApiResponse('/api/login', 150, isSuccess: true);
      performanceService.trackApiResponse('/api/rides', 200, isSuccess: true);
      performanceService.trackApiResponse('/api/booking', 300, isSuccess: true);
      performanceService.trackApiResponse('/api/payment', 800, isSuccess: false);

      // Screen loads
      performanceService.trackScreenLoad('SplashScreen', 500);
      performanceService.trackScreenLoad('LoginScreen', 800);
      performanceService.trackScreenLoad('DashboardScreen', 1200);

      // Memory usage
      performanceService.trackMemoryUsage('AppStart', 80.0);
      performanceService.trackMemoryUsage('Dashboard', 120.0);
      performanceService.trackMemoryUsage('Booking', 150.0);

      // User interactions
      performanceService.trackUserInteraction('login', 'LoginScreen');
      performanceService.trackUserInteraction('book_ride', 'BookingScreen');

      // Act
      final metrics = performanceService.getPerformanceMetrics();

      // Assert
      expect(metrics.totalApiCalls, equals(4));
      expect(metrics.totalScreenLoads, equals(3));
      expect(metrics.avgApiResponseTime, equals(362.5)); // (150+200+300+800)/4
      expect(metrics.avgScreenLoadTime, closeTo(833.33, 0.1));
      expect(metrics.avgMemoryUsage, closeTo(116.67, 0.1));
      expect(metrics.networkMetrics.length, equals(4));
      expect(metrics.userInteractions.length, equals(2));
      expect(metrics.accuracy, equals(0.75)); // 3 successes out of 4
      expect(metrics.errorRate, equals(0.25)); // 1 error out of 4
    });
  });

  group('Performance Metrics Model Tests', () {
    test('should serialize to JSON correctly', () {
      // Arrange
      final networkMetric = NetworkMetric(
        endpoint: '/api/test',
        responseTime: 250,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        isSuccess: true,
      );

      final userInteraction = UserInteractionMetric(
        action: 'button_press',
        screen: 'TestScreen',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        metadata: {'test': 'data'},
      );

      final metrics = PerformanceMetrics(
        avgApiResponseTime: 250.0,
        avgScreenLoadTime: 800.0,
        avgMemoryUsage: 120.0,
        slowestApi: '/api/slow',
        slowestScreen: 'SlowScreen',
        highestMemoryUsage: 'MemoryIntensive',
        totalApiCalls: 10,
        totalScreenLoads: 5,
        errorRate: 0.1,
        sessionDuration: const Duration(minutes: 30),
        precision: 0.85,
        accuracy: 0.90,
        recall: 0.80,
        tnr: 0.95,
        networkMetrics: [networkMetric],
        userInteractions: [userInteraction],
      );

      // Act
      final json = metrics.toJson();

      // Assert
      expect(json['avgApiResponseTime'], equals(250.0));
      expect(json['avgScreenLoadTime'], equals(800.0));
      expect(json['avgMemoryUsage'], equals(120.0));
      expect(json['slowestApi'], equals('/api/slow'));
      expect(json['totalApiCalls'], equals(10));
      expect(json['precision'], equals(0.85));
      expect(json['accuracy'], equals(0.90));
      expect(json['networkMetrics'], isA<List>());
      expect(json['userInteractions'], isA<List>());
    });

    test('should get quality rating correctly', () {
      expect(PerformanceDataset.getQualityRating(0.95), equals('Excellent'));
      expect(PerformanceDataset.getQualityRating(0.85), equals('Good'));
      expect(PerformanceDataset.getQualityRating(0.75), equals('Average'));
      expect(PerformanceDataset.getQualityRating(0.65), equals('Below Average'));
      expect(PerformanceDataset.getQualityRating(0.55), equals('Poor'));
    });
  });
}
