import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api_service.dart';

class AdminService extends GetxService {
  static AdminService get instance => Get.find<AdminService>();
  final ApiService _apiService = Get.find<ApiService>();

  /// Get all users for admin dashboard
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      debugPrint('🔄 AdminService: Calling API /admin/users/');
      final response = await _apiService.get('/admin/users/');
      if (response.statusCode == 200 && response.data is List) {
        final users = List<Map<String, dynamic>>.from(response.data);
        debugPrint('✅ AdminService: Got ${users.length} users from API');
        return users;
      } else {
        debugPrint('❌ AdminService: Unexpected response: ${response.statusCode}, ${response.data}');
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ AdminService: Error fetching users from API: $e');
      rethrow;
    }
  }

  /// Get all rides for admin monitoring
  Future<List<Map<String, dynamic>>> getAllRides() async {
    try {
      debugPrint('🔄 AdminService: Calling API /admin/rides/');
      final response = await _apiService.get('/admin/rides/');
      if (response.statusCode == 200 && response.data is List) {
        final rides = List<Map<String, dynamic>>.from(response.data);
        debugPrint('✅ AdminService: Got ${rides.length} rides from API');
        return rides;
      } else {
        debugPrint('❌ AdminService: Unexpected response: ${response.statusCode}, ${response.data}');
        throw Exception('Failed to fetch rides: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ AdminService: Error fetching rides from API: $e');
      rethrow;
    }
  }

  /// Get admin analytics and statistics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      debugPrint('🔄 AdminService: Calling API /admin/analytics/');
      final response = await _apiService.get('/admin/analytics/');
      if (response.statusCode == 200 && response.data is Map) {
        final analytics = Map<String, dynamic>.from(response.data);
        debugPrint('✅ AdminService: Got analytics from API: ${analytics.keys.toList()}');
        return analytics;
      } else {
        debugPrint('❌ AdminService: Unexpected response: ${response.statusCode}, ${response.data}');
        throw Exception('Failed to fetch analytics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ AdminService: Error fetching analytics from API: $e');
      rethrow;
    }
  }

  /// Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      // For now, use the same analytics endpoint
      final response = await _apiService.get('/admin/analytics/');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to fetch system stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching system stats: $e');
      rethrow;
    }
  }

  /// Get detailed information about a specific user
  Future<Map<String, dynamic>?> getUserDetails(int userId) async {
    try {
      final response = await _apiService.get('/users/users/$userId/');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to fetch user details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user details: $e');
      rethrow;
    }
  }

  /// Suspend a user account
  Future<bool> suspendUser(int userId) async {
    try {
      final response = await _apiService.post('/admin/users/$userId/suspend/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error suspending user: $e');
      rethrow;
    }
  }

  /// Delete a user account
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await _apiService.delete('/admin/users/$userId/delete/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      rethrow;
    }
  }

  /// Cancel a ride (admin only)
  Future<bool> cancelRide(int rideId, String reason) async {
    try {
      final response = await _apiService.post('/admin/rides/$rideId/cancel/', 
        data: {'reason': reason});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error cancelling ride: $e');
      rethrow;
    }
  }

  /// Approve driver verification
  Future<bool> approveDriverVerification(int userId) async {
    try {
      final response = await _apiService.post('/admin/driver/verification/approve/$userId/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error approving driver verification: $e');
      rethrow;
    }
  }

  /// Get recent activity for admin dashboard
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      debugPrint('🔄 AdminService: Calling API /admin/recent-activity/');
      final response = await _apiService.get('/admin/recent-activity/');
      if (response.statusCode == 200 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data);
        final activities = List<Map<String, dynamic>>.from(data['recent_activity'] ?? []);
        debugPrint('✅ AdminService: Got ${activities.length} recent activities from API');
        return activities;
      } else {
        debugPrint('❌ AdminService: Unexpected response: ${response.statusCode}, ${response.data}');
        throw Exception('Failed to fetch recent activity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ AdminService: Error fetching recent activity from API: $e');
      rethrow;
    }
  }

  /// Reject driver verification
  Future<bool> rejectDriverVerification(int userId, String reason) async {
    try {
      final response = await _apiService.post('/admin/driver/verification/reject/$userId/', 
        data: {'reason': reason});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error rejecting driver verification: $e');
      rethrow;
    }
  }
}
