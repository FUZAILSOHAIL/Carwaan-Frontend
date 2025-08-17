import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../controllers/auth_controller.dart';

class AdminController extends GetxController {
  final AdminService _adminService = Get.find<AdminService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable data
  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rides = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> analytics = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> systemStats = <String, dynamic>{}.obs;
  
  // Loading states
  final RxBool isLoadingUsers = false.obs;
  final RxBool isLoadingRides = false.obs;
  final RxBool isLoadingAnalytics = false.obs;
  final RxBool isLoadingStats = false.obs;
  
  // Error states
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Only initialize if user is admin
    if (_authController.currentUser.value?.isAdmin == true) {
      loadInitialData();
    }
  }

  /// Check if current user is admin
  bool get isCurrentUserAdmin => _authController.currentUser.value?.isAdmin ?? false;

  /// Load all initial data for admin dashboard
  Future<void> loadInitialData() async {
    if (!isCurrentUserAdmin) {
      errorMessage.value = 'Access denied: Admin privileges required';
      return;
    }

    await Future.wait([
      loadUsers(),
      loadRides(),
      loadAnalytics(),
      loadSystemStats(),
    ]);
  }

  /// Load all users
  Future<void> loadUsers() async {
    if (!isCurrentUserAdmin) return;
    
    try {
      isLoadingUsers.value = true;
      errorMessage.value = '';
      
      debugPrint('🔄 AdminController: Loading users from API...');
      final usersList = await _adminService.getAllUsers();
      users.value = usersList;
      
      debugPrint('✅ AdminController: Loaded ${usersList.length} users from backend API');
      debugPrint('📊 AdminController: Sample user data: ${usersList.isNotEmpty ? usersList.first.keys.toList() : "No users"}');
    } catch (e) {
      errorMessage.value = 'Failed to load users: $e';
      debugPrint('❌ AdminController: Error loading users from API: $e');
      
      // Clear users on error
      users.value = [];
      
      if (e.toString().contains('403') || e.toString().contains('Admin privileges')) {
        debugPrint('🔑 AdminController: Admin privileges required. User may not be admin.');
      }
    } finally {
      isLoadingUsers.value = false;
    }
  }

  /// Load all rides
  Future<void> loadRides() async {
    if (!isCurrentUserAdmin) return;
    
    try {
      isLoadingRides.value = true;
      errorMessage.value = '';
      
      debugPrint('🔄 AdminController: Loading rides from API...');
      final ridesList = await _adminService.getAllRides();
      rides.value = ridesList;
      
      debugPrint('✅ AdminController: Loaded ${ridesList.length} rides from backend API');
      debugPrint('📊 AdminController: Sample ride data: ${ridesList.isNotEmpty ? ridesList.first.keys.toList() : "No rides"}');
    } catch (e) {
      errorMessage.value = 'Failed to load rides: $e';
      debugPrint('❌ AdminController: Error loading rides from API: $e');
    } finally {
      isLoadingRides.value = false;
    }
  }

  /// Load analytics data
  Future<void> loadAnalytics() async {
    if (!isCurrentUserAdmin) return;
    
    try {
      isLoadingAnalytics.value = true;
      errorMessage.value = '';
      
      debugPrint('🔄 AdminController: Loading analytics from API...');
      final analyticsData = await _adminService.getAnalytics();
      analytics.assignAll(analyticsData);
      
      debugPrint('✅ AdminController: Loaded analytics data from backend API');
      debugPrint('📊 AdminController: Analytics keys: ${analyticsData.keys.toList()}');
      debugPrint('📊 AdminController: Analytics values: $analyticsData');
    } catch (e) {
      errorMessage.value = 'Failed to load analytics: $e';
      debugPrint('❌ Error loading analytics: $e');
    } finally {
      isLoadingAnalytics.value = false;
    }
  }

  /// Load system statistics
  Future<void> loadSystemStats() async {
    if (!isCurrentUserAdmin) return;
    
    try {
      isLoadingStats.value = true;
      errorMessage.value = '';
      
      final statsData = await _adminService.getSystemStats();
      systemStats.assignAll(statsData);
      
      debugPrint('✅ Loaded system stats');
    } catch (e) {
      errorMessage.value = 'Failed to load system stats: $e';
      debugPrint('❌ Error loading system stats: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Get user details
  Future<Map<String, dynamic>?> getUserDetails(int userId) async {
    if (!isCurrentUserAdmin) return null;
    
    try {
      return await _adminService.getUserDetails(userId);
    } catch (e) {
      errorMessage.value = 'Failed to load user details: $e';
      debugPrint('❌ Error loading user details: $e');
      return null;
    }
  }

  /// Suspend a user
  Future<bool> suspendUser(int userId) async {
    if (!isCurrentUserAdmin) return false;
    
    try {
      final success = await _adminService.suspendUser(userId);
      if (success) {
        // Update local user list
        final userIndex = users.indexWhere((user) => user['id'] == userId);
        if (userIndex != -1) {
          users[userIndex]['is_active'] = false;
          users.refresh();
        }
        Get.snackbar('Success', 'User suspended successfully');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to suspend user: $e';
      Get.snackbar('Error', 'Failed to suspend user: $e');
      return false;
    }
  }

  /// Delete a user
  Future<bool> deleteUser(int userId) async {
    if (!isCurrentUserAdmin) return false;
    
    try {
      final success = await _adminService.deleteUser(userId);
      if (success) {
        // Remove from local user list
        users.removeWhere((user) => user['id'] == userId);
        Get.snackbar('Success', 'User deleted successfully');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to delete user: $e';
      Get.snackbar('Error', 'Failed to delete user: $e');
      return false;
    }
  }

  /// Cancel a ride
  Future<bool> cancelRide(int rideId, String reason) async {
    if (!isCurrentUserAdmin) return false;
    
    try {
      final success = await _adminService.cancelRide(rideId, reason);
      if (success) {
        // Update local ride list
        final rideIndex = rides.indexWhere((ride) => ride['id'] == rideId);
        if (rideIndex != -1) {
          rides[rideIndex]['status'] = 'cancelled';
          rides.refresh();
        }
        Get.snackbar('Success', 'Ride cancelled successfully');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to cancel ride: $e';
      Get.snackbar('Error', 'Failed to cancel ride: $e');
      return false;
    }
  }

  /// Approve driver verification
  Future<bool> approveDriverVerification(int userId) async {
    if (!isCurrentUserAdmin) return false;
    
    try {
      final success = await _adminService.approveDriverVerification(userId);
      if (success) {
        // Update local user list
        final userIndex = users.indexWhere((user) => user['id'] == userId);
        if (userIndex != -1) {
          users[userIndex]['driver_verification_status'] = 'verified';
          users.refresh();
        }
        Get.snackbar('Success', 'Driver verification approved');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to approve driver verification: $e';
      Get.snackbar('Error', 'Failed to approve driver verification: $e');
      return false;
    }
  }

  /// Reject driver verification
  Future<bool> rejectDriverVerification(int userId, String reason) async {
    if (!isCurrentUserAdmin) return false;
    
    try {
      final success = await _adminService.rejectDriverVerification(userId, reason);
      if (success) {
        // Update local user list
        final userIndex = users.indexWhere((user) => user['id'] == userId);
        if (userIndex != -1) {
          users[userIndex]['driver_verification_status'] = 'rejected';
          users.refresh();
        }
        Get.snackbar('Success', 'Driver verification rejected');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to reject driver verification: $e';
      Get.snackbar('Error', 'Failed to reject driver verification: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    await loadInitialData();
  }

  /// Get filtered users (drivers, passengers, etc.)
  List<Map<String, dynamic>> getFilteredUsers({bool? isDriver, bool? isActive}) {
    return users.where((user) {
      if (isDriver != null && user['is_driver'] != isDriver) return false;
      if (isActive != null && user['is_active'] != isActive) return false;
      return true;
    }).toList();
  }

  /// Get filtered rides by status
  List<Map<String, dynamic>> getRidesByStatus(String status) {
    return rides.where((ride) => ride['status'] == status).toList();
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final data = analytics;
    return {
      'totalUsers': data['total_users'] ?? 0,
      'totalDrivers': data['total_drivers'] ?? 0,
      'totalRides': data['total_rides'] ?? 0,
      'activeRides': data['active_rides'] ?? 0,
      'completionRate': data['completion_rate'] ?? 0.0,
      'averageRating': data['avg_rating'] ?? 0.0,
    };
  }
}
