import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api_service.dart';
import 'token_storage_service.dart';
import '../controllers/auth_controller.dart';

class DebugRidesTest {
  
  /// Test all ride-related endpoints to identify issues
  static Future<void> testRideEndpoints() async {
    if (!kDebugMode) return;
    
    debugPrint('🧪 Starting comprehensive rides endpoint test...');
    
    final apiService = Get.find<ApiService>();
    final authController = Get.find<AuthController>();
    
    // Check authentication status
    debugPrint('🔐 Auth status: logged in = ${authController.isLoggedIn.value}');
    debugPrint('🔑 Token exists: ${authController.token.value.isNotEmpty}');
    
    // Test token storage
    try {
      final storedToken = await TokenStorageService.getAccessToken();
      debugPrint('💾 Stored token: ${storedToken?.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Token storage error: $e');
    }
    
    // Test available rides endpoint
    await _testAvailableRides(apiService);
    
    // Test my rides endpoint
    await _testMyRides(apiService);
    
    // Test search rides endpoint
    await _testSearchRides(apiService);
    
    debugPrint('🏁 Rides endpoint test completed');
  }
  
  static Future<void> _testAvailableRides(ApiService apiService) async {
    debugPrint('\n🔍 Testing available rides endpoint...');
    try {
      final rides = await apiService.getAvailableRides();
      debugPrint('✅ Available rides: ${rides.length} found');
      if (rides.isNotEmpty) {
        debugPrint('📄 Sample ride: ${rides.first}');
      }
    } catch (e) {
      debugPrint('❌ Available rides failed: $e');
      _analyzeError('available_rides', e);
    }
  }
  
  static Future<void> _testMyRides(ApiService apiService) async {
    debugPrint('\n🔍 Testing my rides endpoint...');
    try {
      final rides = await apiService.getMyRides();
      debugPrint('✅ My rides loaded successfully');
      debugPrint('📄 Response keys: ${rides.keys.toList()}');
    } catch (e) {
      debugPrint('❌ My rides failed: $e');
      _analyzeError('my_rides', e);
    }
  }
  
  static Future<void> _testSearchRides(ApiService apiService) async {
    debugPrint('\n🔍 Testing search rides endpoint...');
    try {
      final rides = await apiService.searchRides(
        pickup: 'Test Location',
        dropoff: 'Test Destination',
      );
      debugPrint('✅ Search rides: ${rides.length} found');
    } catch (e) {
      debugPrint('❌ Search rides failed: $e');
      _analyzeError('search_rides', e);
    }
  }
  
  static void _analyzeError(String endpoint, dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('404')) {
      debugPrint('💡 $endpoint: Endpoint not found - check backend routes');
      debugPrint('   Expected: /api/rides/rides/$endpoint/ or /api/rides/$endpoint/');
    } else if (errorStr.contains('401')) {
      debugPrint('💡 $endpoint: Authentication required - check token');
    } else if (errorStr.contains('403')) {
      debugPrint('💡 $endpoint: Permission denied - check user permissions');
    } else if (errorStr.contains('500')) {
      debugPrint('💡 $endpoint: Server error - check backend logs');
    } else if (errorStr.contains('timeout') || errorStr.contains('connection')) {
      debugPrint('💡 $endpoint: Connection issue - check if backend is running');
    } else {
      debugPrint('💡 $endpoint: Unknown error - check backend and network');
    }
  }
  
  /// Quick test for just the available rides endpoint
  static Future<void> testAvailableRidesOnly() async {
    if (!kDebugMode) return;
    
    debugPrint('🚀 Quick test: Available rides endpoint');
    final apiService = Get.find<ApiService>();
    await _testAvailableRides(apiService);
  }
}
