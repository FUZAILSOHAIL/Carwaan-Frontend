import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'api_service.dart';
import 'token_storage_service.dart';

/// Debug utility to test authentication flow and API endpoints
class DebugAuthTest {
  static Future<void> testAuthenticationFlow() async {
    debugPrint('🧪 Starting Authentication Debug Test');
    
    try {
      final authController = Get.find<AuthController>();
      final apiService = Get.find<ApiService>();
      
      // Test 1: Check if user is logged in
      debugPrint('🔍 Test 1: Checking login status');
      debugPrint('   isLoggedIn: ${authController.isLoggedIn.value}');
      debugPrint('   hasToken: ${authController.token.value.isNotEmpty}');
      debugPrint('   currentUser: ${authController.currentUser.value?.firstName ?? 'null'}');
      
      // Test 2: Check stored credentials
      debugPrint('🔍 Test 2: Checking stored credentials');
      final hasValidCreds = await TokenStorageService.hasValidCredentials();
      final accessToken = await TokenStorageService.getAccessToken();
      final refreshToken = await TokenStorageService.getRefreshToken();
      final isExpired = await TokenStorageService.isTokenExpired();
      
      debugPrint('   hasValidCredentials: $hasValidCreds');
      debugPrint('   accessToken length: ${accessToken?.length ?? 0}');
      debugPrint('   refreshToken length: ${refreshToken?.length ?? 0}');
      debugPrint('   isTokenExpired: $isExpired');
      
      // Test 3: Test API connection
      debugPrint('🔍 Test 3: Testing API connection');
      try {
        final connectionOk = await apiService.testConnection();
        debugPrint('   API connection: ${connectionOk ? 'OK' : 'FAILED'}');
      } catch (e) {
        debugPrint('   API connection error: $e');
      }
      
      // Test 4: Test protected endpoint (user profile)
      if (authController.isLoggedIn.value) {
        debugPrint('🔍 Test 4: Testing protected endpoint (user profile)');
        try {
          final profile = await apiService.getUserProfile();
          debugPrint('   User profile: ${profile['user']?['first_name'] ?? 'No name'}');
        } catch (e) {
          debugPrint('   User profile error: $e');
        }
        
        // Test 5: Test vehicles endpoint
        debugPrint('🔍 Test 5: Testing vehicles endpoint');
        try {
          final vehicles = await apiService.getUserVehicles();
          debugPrint('   Vehicles count: ${vehicles.length}');
        } catch (e) {
          debugPrint('   Vehicles error: $e');
        }
        
        // Test 6: Test rides endpoint
        debugPrint('🔍 Test 6: Testing rides endpoint');
        try {
          final rides = await apiService.getMyRides();
          debugPrint('   Rides data: ${rides.keys.toList()}');
        } catch (e) {
          debugPrint('   Rides error: $e');
        }
      } else {
        debugPrint('🔍 Skipping protected endpoint tests - user not logged in');
      }
      
      debugPrint('✅ Authentication Debug Test completed');
      
    } catch (e) {
      debugPrint('❌ Authentication Debug Test failed: $e');
    }
  }
  
  static Future<void> testTokenRefresh() async {
    debugPrint('🧪 Testing Token Refresh');
    
    try {
      final authController = Get.find<AuthController>();
      
      if (!authController.isLoggedIn.value) {
        debugPrint('❌ Cannot test token refresh - user not logged in');
        return;
      }
      
      // Force token expiry simulation
      debugPrint('🔄 Attempting manual token refresh...');
      
      // Get refresh token
      final refreshToken = await TokenStorageService.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('❌ No refresh token available');
        return;
      }
      
      // Try refresh
      final apiService = Get.find<ApiService>();
      try {
        final result = await apiService.refreshToken(refreshToken);
        debugPrint('✅ Token refresh successful: ${result.containsKey('access')}');
      } catch (e) {
        debugPrint('❌ Token refresh failed: $e');
      }
      
    } catch (e) {
      debugPrint('❌ Token refresh test failed: $e');
    }
  }
}
