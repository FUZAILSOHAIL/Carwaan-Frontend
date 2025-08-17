import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/token_storage_service.dart';
import '../../domain/models/user_model.dart';
import '../services/debug_auth_test.dart';
import '../services/debug_rides_test.dart';
import 'rides_controller.dart';
import 'vehicle_controller.dart';

class AuthController extends GetxController {
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString token = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxList<Map<String, dynamic>> paymentMethods = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> defaultPaymentMethod = Rx<Map<String, dynamic>?>(null);

  late final ApiService _apiService;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    
    // Check authentication status on app start
    _initializeAuthentication();
  }

  /// Initialize authentication on app startup
  Future<void> _initializeAuthentication() async {
    try {
      debugPrint('🔄 AuthController: Initializing authentication...');
      
      // Ensure API service has current token if available
      await _syncTokenWithApiService();
      
      // Load user data and check authentication
      await _loadUserData();
      
      debugPrint('✅ AuthController: Authentication initialization completed');
    } catch (e) {
      debugPrint('❌ AuthController: Error during authentication initialization: $e');
    }
  }

  /// Ensure API service has the current token
  Future<void> _syncTokenWithApiService() async {
    try {
      // Try to get token from storage first
      final storedToken = await TokenStorageService.getAccessToken();
      if (storedToken != null && storedToken.isNotEmpty) {
        token.value = storedToken;
        _apiService.setToken(storedToken);
        debugPrint('🔄 Token synchronized with API service on init');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync token on init: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      debugPrint('🔄 AuthController: Loading user data...');
      
      // Check if we have valid stored credentials
      final hasValidCreds = await TokenStorageService.hasValidCredentials();
      
      if (hasValidCreds) {
        final savedToken = await TokenStorageService.getAccessToken();
        
        if (savedToken != null && savedToken.isNotEmpty) {
          debugPrint('🔑 Found saved token, checking validity...');
          
          // Check if token is expired
          final isExpired = await TokenStorageService.isTokenExpired();
          
          if (isExpired) {
            debugPrint('⏰ Token expired, attempting refresh...');
            final refreshed = await _attemptTokenRefresh();
            if (!refreshed) {
              debugPrint('❌ Token refresh failed, clearing stored data...');
              await _clearAuthenticationData();
              return;
            }
          } else {
            token.value = savedToken;
            _apiService.setToken(savedToken);
          }
          
          // Try to load user profile from API
          final success = await _loadUserProfileFromAPI();
          if (success) {
            debugPrint('✅ User authenticated and profile loaded successfully');
            isLoggedIn.value = true;
            
            // Load additional user data
            await _loadAdditionalUserData();
            
            // Initialize other controllers with data after authentication
            await _initializeControllersAfterAuth();
          } else {
            // API failed, try to load from stored data
            debugPrint('⚠️ API failed, trying to load from stored data...');
            await _loadUserFromStoredData();
          }
        }
      } else {
        // No valid credentials, try to load from stored data as fallback
        debugPrint('ℹ️ No valid stored credentials, checking for stored user data...');
        final hasStoredData = await TokenStorageService.hasStoredCredentials();
        if (hasStoredData) {
          await _loadUserFromStoredData();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      await _clearAuthenticationData();
    }
  }

  /// Load user profile from API
  Future<bool> _loadUserProfileFromAPI() async {
    try {
      final response = await _apiService.getUserProfile();
      debugPrint('🔍 AuthController: getUserProfile response: $response');
      
      // Handle different response structures
      Map<String, dynamic> userData;
      if (response.containsKey('user') && response['user'] is Map<String, dynamic>) {
        userData = response['user'] as Map<String, dynamic>;
      } else {
        userData = response;
      }
      
      debugPrint('🔍 AuthController: Raw user data: $userData');
      debugPrint('🔍 AuthController: Gender field: ${userData['gender']}');
      currentUser.value = User.fromJson(userData);
      debugPrint('🔍 AuthController: Parsed user gender: ${currentUser.value?.gender}');
      
      // Store updated user data
      await TokenStorageService.storeUserData(userData);
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to load user profile from API: $e');
      
      // If it's an auth error, try token refresh
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔄 Auth error, attempting token refresh...');
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          // Retry loading user data after successful token refresh
          try {
            final response = await _apiService.getUserProfile();
            Map<String, dynamic> userData;
            if (response.containsKey('user') && response['user'] is Map<String, dynamic>) {
              userData = response['user'] as Map<String, dynamic>;
            } else {
              userData = response;
            }
            
            currentUser.value = User.fromJson(userData);
            await TokenStorageService.storeUserData(userData);
            debugPrint('✅ User profile loaded successfully after token refresh');
            return true;
          } catch (retryError) {
            debugPrint('❌ Failed to load user profile after token refresh: $retryError');
            return false;
          }
        }
      }
      return false;
    }
  }

  /// Load user from stored data (offline mode)
  Future<void> _loadUserFromStoredData() async {
    try {
      final userData = await TokenStorageService.getUserData();
      if (userData != null && userData.isNotEmpty) {
        debugPrint('📱 Loading user from stored data (offline mode)');
        currentUser.value = User.fromJson(userData);
        isLoggedIn.value = true;
        
        // Try to load stored token
        final storedToken = await TokenStorageService.getAccessToken();
        if (storedToken != null) {
          token.value = storedToken;
          _apiService.setToken(storedToken);
        }
        
        debugPrint('✅ User loaded from stored data: ${currentUser.value?.firstName}');
      }
    } catch (e) {
      debugPrint('❌ Error loading user from stored data: $e');
    }
  }

  /// Clear all authentication data
  Future<void> _clearAuthenticationData() async {
    try {
      await TokenStorageService.clearAll();
      token.value = '';
      currentUser.value = null;
      isLoggedIn.value = false;
      _apiService.clearToken();
      debugPrint('🗑️ Authentication data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing authentication data: $e');
    }
  }

  /// Attempt to refresh the access token
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await TokenStorageService.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ No refresh token available');
        return false;
      }
      
      debugPrint('🔄 Attempting token refresh...');
      final response = await _apiService.refreshToken(refreshToken);
      
      if (response['access'] != null) {
        final newAccessToken = response['access'];
        final newRefreshToken = response['refresh']; // Some APIs provide new refresh token
        
        // Calculate expiry time (usually tokens are valid for 24 hours)
        final expiryTime = DateTime.now().add(const Duration(hours: 24));
        
        // Store new tokens
        await TokenStorageService.storeTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
          expiryTime: expiryTime,
        );
        
        // Update API service
        token.value = newAccessToken;
        _apiService.setToken(newAccessToken);
        
        debugPrint('✅ Token refreshed successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password, {String? userType}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _apiService.login(username, password);
      
      // Handle the backend response format
      if (response.containsKey('access_token') || response.containsKey('access')) {
        final accessToken = response['access_token'] ?? response['access'];
        final refreshToken = response['refresh_token'] ?? response['refresh'];
        
        if (accessToken != null) {
          token.value = accessToken;
          _apiService.setToken(accessToken);
          
          // Calculate token expiry (usually 24 hours)
          final expiryTime = DateTime.now().add(const Duration(hours: 24));
          
          // Store tokens securely
          await TokenStorageService.storeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiryTime: expiryTime,
          );
          
          // Load user profile
          try {
            final userResponse = await _apiService.getUserProfile();
            if (userResponse['user'] != null) {
              currentUser.value = User.fromJson(userResponse['user']);
              
              // Store user data
              await TokenStorageService.storeUserData(userResponse['user']);
              
              // Load payment methods after successful login
              await getPaymentMethods();
              await refreshDefaultPaymentMethod();
            }
          } catch (e) {
            debugPrint('Failed to load user profile after login: $e');
            // Continue with login even if profile load fails
          }
          
          isLoggedIn.value = true;
          
          // Initialize other controllers with data after authentication
          await _initializeControllersAfterAuth();
          
          // Navigate based on user type selection and user role
          _navigateAfterLogin(userType);
          
          return true;
        }
      }
      
      // Don't show error message here, let the UI handle it
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      
      // Parse detailed error information from backend
      String errorText = e.toString();
      
      try {
        if (errorText.contains("Email doesn't exist, please create account")) {
          errorMessage.value = "Email doesn't exist, please create account";
        } else if (errorText.contains('Invalid credentials')) {
          errorMessage.value = 'Invalid password. Please check your password and try again.';
        } else if (errorText.contains('network') || errorText.contains('connection')) {
          errorMessage.value = 'Network error. Please check your connection and try again.';
        } else if (errorText.contains('timeout')) {
          errorMessage.value = 'Request timeout. Please try again.';
        } else {
          errorMessage.value = 'Login failed. Please check your credentials and try again.';
        }
      } catch (parseError) {
        debugPrint('Error parsing login error: $parseError');
        errorMessage.value = 'Login failed. Please try again.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to appropriate dashboard based on user type selection and user role
  void _navigateAfterLogin(String? userType) {
    final user = currentUser.value;
    
    // Debug logging
    debugPrint('🔍 Navigation Debug:');
    debugPrint('   userType: $userType');
    debugPrint('   userType?.toLowerCase(): ${userType?.toLowerCase()}');
    debugPrint('   user: ${user?.toJson()}');
    debugPrint('   user.role: "${user?.role}"');
    debugPrint('   user.userType: "${user?.userType}"');
    debugPrint('   user.isDriver: ${user?.isDriver}');
    debugPrint('   user.isAdmin: ${user?.isAdmin}');
    debugPrint('   isLoggedIn.value: ${isLoggedIn.value}');
    
    // If no userType specified, route based on user role
    if (userType == null) {
      debugPrint('   → No userType provided, routing based on user role');
      if (user?.userType == 'admin') {
        debugPrint('   → User is admin, going to /admin-dashboard');
        Get.offAllNamed('/admin-dashboard');
      } else if (user?.userType == 'driver') {
        if (user?.isDriverVerified == true) {
          debugPrint('   → User is verified driver, going to /driver-dashboard');
          Get.offAllNamed('/driver-dashboard');
        } else {
          debugPrint('   → User is unverified driver, going to /driver-verification');
          Get.offAllNamed('/driver-verification');
        }
      } else {
        debugPrint('   → User is passenger, going to /passenger-dashboard');
        Get.offAllNamed('/passenger-dashboard');
      }
      return;
    }
    
    switch (userType.toLowerCase()) {
      case 'admin':
        debugPrint('   → Admin case selected');
        debugPrint('   → userType check: "${user?.userType}" == "admin" = ${user?.userType == 'admin'}');
        // Verify user has admin role
        if (user?.userType == 'admin') {
          debugPrint('   → ✅ Admin verified, going to /admin-dashboard');
          Get.offAllNamed('/admin-dashboard');
        } else {
          debugPrint('   → ❌ Admin access denied, going to /user-selection');
          debugPrint('   → Current user type: ${user?.userType}, Required: admin');
          // User selected admin but doesn't have admin role
          String userCurrentType = user?.userType ?? 'passenger';
          String message = 'Access denied. This account is registered as ${userCurrentType.toUpperCase()}. Please select ${userCurrentType.toUpperCase()} option to login.';
          errorMessage.value = message;
          _showRoleError(userCurrentType.toUpperCase());
        }
        break;
        
      case 'driver':
        debugPrint('   → Driver case selected');
        debugPrint('   → userType check: "${user?.userType}" == "driver" = ${user?.userType == 'driver'}');
        // Check if user is a driver
        if (user?.userType == 'driver') {
          if (user?.isDriverVerified == true) {
            debugPrint('   → ✅ Verified driver, going to /driver-dashboard');
            Get.offAllNamed('/driver-dashboard');
          } else {
            debugPrint('   → ✅ Unverified driver, going to /driver-verification');
            Get.offAllNamed('/driver-verification');
          }
        } else {
          debugPrint('   → ❌ Driver access denied');
          String userCurrentType = user?.userType ?? 'passenger';
          String message = 'Access denied. This account is registered as ${userCurrentType.toUpperCase()}. Please select ${userCurrentType.toUpperCase()} option to login.';
          errorMessage.value = message;
          _showRoleError(userCurrentType.toUpperCase());
        }
        break;
        
      case 'passenger':
        debugPrint('   → Passenger case selected');
        debugPrint('   → userType check: "${user?.userType}" == "passenger" = ${user?.userType == 'passenger'}');
        // Check if user is a passenger
        if (user?.userType == 'passenger') {
          debugPrint('   → ✅ Passenger verified, going to /passenger-dashboard');
          Get.offAllNamed('/passenger-dashboard');
        } else {
          debugPrint('   → ❌ Passenger access denied');
          String userCurrentType = user?.userType ?? 'passenger';
          String message = 'Access denied. This account is registered as ${userCurrentType.toUpperCase()}. Please select ${userCurrentType.toUpperCase()} option to login.';
          errorMessage.value = message;
          _showRoleError(userCurrentType.toUpperCase());
        }
        break;
        
      default:
        // Fallback to unified dashboard
        Get.offAllNamed('/dashboard');
        break;
    }
  }

  /// Show role-based error and redirect to user selection
  void _showRoleError(String currentUserRole) {
    // Clear current session but keep user data for role verification
    isLoggedIn.value = false;
    
    // Navigate back to user selection with error
    Get.offAllNamed('/user-selection', arguments: {
      'error': 'Access denied. This account is registered as $currentUserRole. Please select $currentUserRole option to login.',
      'requiredRole': currentUserRole,
    });
  }

  /// Quick method to check if user is currently authenticated
  bool get isAuthenticated {
    return isLoggedIn.value && currentUser.value != null && token.value.isNotEmpty;
  }

  /// Check authentication status with detailed logging
  Future<bool> checkAuthenticationStatus() async {
    try {
      debugPrint('🔍 Checking authentication status...');
      
      // First check in-memory state
      if (isAuthenticated) {
        debugPrint('✅ User is already authenticated in memory');
        return true;
      }
      
      // Check stored credentials
      final hasValidCreds = await TokenStorageService.hasValidCredentials();
      if (hasValidCreds) {
        debugPrint('✅ Valid stored credentials found');
        return true;
      }
      
      // Check for any stored data (even if expired)
      final hasStoredData = await TokenStorageService.hasStoredCredentials();
      if (hasStoredData) {
        debugPrint('⚠️ Found stored data but credentials may be expired');
        // We still consider this as potentially authenticated for offline mode
        return true;
      }
      
      debugPrint('❌ No authentication found');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking authentication status: $e');
      return false;
    }
  }

  /// Check if user is authenticated and has a specific role
  bool isAuthenticatedWithRole(String role) {
    if (!isAuthenticated) return false;
    
    final user = currentUser.value;
    switch (role.toLowerCase()) {
      case 'admin':
        return user?.userType == 'admin';
      case 'driver':
        return user?.userType == 'driver';
      case 'passenger':
        return user?.userType == 'passenger';
      default:
        return true;
    }
  }

  /// Validate if user can access a specific role dashboard
  bool canAccessDashboard(String dashboardType) {
    final user = currentUser.value;
    final loggedIn = isLoggedIn.value;
    
    debugPrint('🛡️ Role Guard: Checking access to $dashboardType dashboard');
    debugPrint('   User role: ${user?.role}');
    debugPrint('   Is logged in: $loggedIn');
    
    if (!loggedIn) {
      debugPrint('   ❌ Not logged in');
      return false;
    }
    
    switch (dashboardType.toLowerCase()) {
      case 'admin':
        final hasAccess = user?.role == 'admin';
        debugPrint('   ${hasAccess ? '✅' : '❌'} Admin access: $hasAccess');
        return hasAccess;
        
      case 'driver':
        final hasAccess = user?.role == 'driver' || user?.isDriver == true;
        debugPrint('   ${hasAccess ? '✅' : '❌'} Driver access: $hasAccess');
        return hasAccess;
        
      case 'passenger':
        final hasAccess = user?.role == 'passenger' || user?.role == 'user' || user?.role == null;
        debugPrint('   ${hasAccess ? '✅' : '❌'} Passenger access: $hasAccess');
        return hasAccess;
        
      default:
        debugPrint('   ✅ General access allowed');
        return true;
    }
  }

  /// Redirect to user selection with role error
  void redirectWithRoleError(String requiredRole) {
    errorMessage.value = 'Access denied. Please login as $requiredRole to access ${requiredRole.toLowerCase()} dashboard.';
    Get.offAllNamed('/user-selection', arguments: {
      'error': errorMessage.value,
      'requiredRole': requiredRole,
    });
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? gender,
    String? userType,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      debugPrint('🔄 Starting registration with userType: $userType');
      
      final userData = {
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': password, // Add password confirmation field
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (userType != null) 'user_type': userType, // Pass user type to backend
      };
      
      debugPrint('📤 Registration data: ${userData.keys}');
      
      final response = await _apiService.register(userData);
      
      // Registration successful, OTP should be sent
      if (response.containsKey('otp_sent') && response['otp_sent'] == true) {
        debugPrint('✅ Registration successful, navigating to OTP verification with userType: $userType');
        // Navigate to OTP verification with userType
        Get.toNamed('/otp-verification', arguments: {
          'email': email,
          'isLogin': false,
          'userType': userType, // Pass userType for post-verification navigation
        });
      }
      
      return true;
      
    } catch (e) {
      debugPrint('Registration error: $e');
      
      // The _handleError method in ApiService already extracts the proper error message
      // from the backend response, so we can use it directly
      String errorText = e.toString();
      
      try {
        // First check if the error message is already user-friendly from the backend
        if (errorText.contains('Phone number is already registered')) {
          errorMessage.value = 'Phone number is already registered. Please use a different phone number.';
        } else if (errorText.contains('Email address is already registered')) {
          errorMessage.value = 'Email address is already registered. Please use a different email or try logging in.';
        } else if (errorText.contains('Username is already taken')) {
          errorMessage.value = 'Username is already taken. Please choose a different username.';
        } else if (errorText.contains('Password must be at least')) {
          errorMessage.value = 'Password must be at least 8 characters long.';
        } else if (errorText.contains('Passwords do not match')) {
          errorMessage.value = 'Passwords do not match. Please ensure both password fields are identical.';
        } else if (errorText.contains('Please enter a valid email')) {
          errorMessage.value = 'Please enter a valid email address.';
        } else if (errorText.contains('First Name is required') || errorText.contains('first_name')) {
          errorMessage.value = 'First name is required.';
        } else if (errorText.contains('Last Name is required') || errorText.contains('last_name')) {
          errorMessage.value = 'Last name is required.';
        } else if (errorText.contains('Please select your gender') || errorText.contains('gender')) {
          errorMessage.value = 'Please select your gender.';
        } else if (errorText.contains('network') || errorText.contains('connection')) {
          errorMessage.value = 'Network error. Please check your connection and try again.';
        } else if (errorText.contains('timeout')) {
          errorMessage.value = 'Request timeout. Please try again.';
        } else {
          // Use the error message as-is if it's already user-friendly
          // ApiService _handleError method extracts the backend message
          errorMessage.value = errorText.isNotEmpty ? errorText : 'Registration failed. Please try again.';
        }
      } catch (parseError) {
        debugPrint('Error parsing registration error: $parseError');
        errorMessage.value = 'Registration failed. Please try again.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendOTP(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _apiService.sendOTP(email);
      return true;
    } catch (e) {
      debugPrint('Send OTP error: $e');
      
      // Parse detailed error information
      String errorText = e.toString();
      
      try {
        if (errorText.contains("Email doesn't exist, please create account")) {
          errorMessage.value = "Email doesn't exist, please create account";
        } else if (errorText.contains('Email is already verified')) {
          errorMessage.value = 'Email is already verified. You can login directly.';
        } else if (errorText.contains('network') || errorText.contains('connection')) {
          errorMessage.value = 'Network error. Please check your connection and try again.';
        } else if (errorText.contains('timeout')) {
          errorMessage.value = 'Request timeout. Please try again.';
        } else {
          errorMessage.value = 'Failed to send OTP. Please try again.';
        }
      } catch (parseError) {
        debugPrint('Error parsing OTP error: $parseError');
        errorMessage.value = 'Failed to send OTP. Please try again.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyRegistrationOTP(String email, String otpCode, {String? userType}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.verifyOTP(email, otpCode);
      
      // Check if the response contains access token (auto-login after verification)
      if (response.containsKey('access_token') || response.containsKey('access')) {
        final accessToken = response['access_token'] ?? response['access'];
        final refreshToken = response['refresh_token'] ?? response['refresh'];
        
        if (accessToken != null) {
          token.value = accessToken;
          _apiService.setToken(accessToken);
          
          // Calculate token expiry
          final expiryTime = DateTime.now().add(const Duration(hours: 24));
          
          // Store tokens securely
          await TokenStorageService.storeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiryTime: expiryTime,
          );
          
          // Load user data
          try {
            final userResponse = await _apiService.getUserProfile();
            if (userResponse['user'] != null) {
              currentUser.value = User.fromJson(userResponse['user']);
              isLoggedIn.value = true;
              
              // Store user data
              await TokenStorageService.storeUserData(userResponse['user']);
              
              // Load payment methods and vehicles
              await getPaymentMethods();
              await refreshDefaultPaymentMethod();
              await getUserVehicles();
              
              // Initialize other controllers with data after authentication
              await _initializeControllersAfterAuth();
              
              // Navigate based on user type
              _navigateAfterLogin(userType);
              return true;
            }
          } catch (e) {
            debugPrint('Failed to load user profile after registration: $e');
          }
        }
      }
      
      // If no access token, navigate back to login with userType
      if (userType != null) {
        Get.offAllNamed('/login', arguments: {'userType': userType});
      } else {
        Get.offAllNamed('/login');
      }
      return true;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      
      // Parse detailed error information
      String errorText = e.toString();
      
      try {
        if (errorText.contains("Email doesn't exist, please create account")) {
          errorMessage.value = "Email doesn't exist, please create account";
        } else if (errorText.contains('Invalid OTP') || errorText.contains('expired')) {
          errorMessage.value = 'Invalid or expired OTP. Please request a new one.';
        } else if (errorText.contains('OTP has expired')) {
          errorMessage.value = 'OTP has expired. Please request a new one.';
        } else if (errorText.contains('network') || errorText.contains('connection')) {
          errorMessage.value = 'Network error. Please check your connection and try again.';
        } else if (errorText.contains('timeout')) {
          errorMessage.value = 'Request timeout. Please try again.';
        } else {
          errorMessage.value = 'OTP verification failed. Please try again.';
        }
      } catch (parseError) {
        debugPrint('Error parsing OTP verification error: $parseError');
        errorMessage.value = 'OTP verification failed. Please try again.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithOTP(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _apiService.loginWithOTP(email);
      return true;
    } catch (e) {
      debugPrint('Login with OTP error: $e');
      
      // Parse detailed error information
      String errorText = e.toString();
      
      try {
        if (errorText.contains("Email doesn't exist, please create account")) {
          errorMessage.value = "Email doesn't exist, please create account";
        } else if (errorText.contains('network') || errorText.contains('connection')) {
          errorMessage.value = 'Network error. Please check your connection and try again.';
        } else if (errorText.contains('timeout')) {
          errorMessage.value = 'Request timeout. Please try again.';
        } else {
          errorMessage.value = 'Failed to send login OTP. Please try again.';
        }
      } catch (parseError) {
        debugPrint('Error parsing login OTP error: $parseError');
        errorMessage.value = 'Failed to send login OTP. Please try again.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyLoginOTP(String email, String otpCode, {String? userType}) async {
    try {
      isLoading.value = true;
      debugPrint('🔍 OTP Verification Debug:');
      debugPrint('   Email: $email');
      debugPrint('   OTP Code: $otpCode');
      debugPrint('   User Type: $userType');
      
      final response = await _apiService.verifyLoginOTP(email, otpCode);
      debugPrint('   API Response keys: ${response.keys.toList()}');
      
      if (response.containsKey('access_token') || response.containsKey('access')) {
        final accessToken = response['access_token'] ?? response['access'];
        final refreshToken = response['refresh_token'] ?? response['refresh'];
        debugPrint('   ✅ Tokens found in response');
        debugPrint('   Access token length: ${accessToken?.toString().length}');
        
        if (accessToken != null) {
          token.value = accessToken;
          _apiService.setToken(accessToken);
          
          // Calculate token expiry
          final expiryTime = DateTime.now().add(const Duration(hours: 24));
          
          // Store tokens securely
          await TokenStorageService.storeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiryTime: expiryTime,
          );
          debugPrint('   ✅ Tokens stored successfully');
          
          // Load user profile
          try {
            final userResponse = await _apiService.getUserProfile();
            debugPrint('   ✅ User profile response received');
            if (userResponse['user'] != null) {
              currentUser.value = User.fromJson(userResponse['user']);
              debugPrint('   ✅ User object created: ${currentUser.value?.fullName}');
              debugPrint('   User role: ${currentUser.value?.role}');
              debugPrint('   User isAdmin: ${currentUser.value?.isAdmin}');
              
              // Store user data
              await TokenStorageService.storeUserData(userResponse['user']);
              
              // Load payment methods after successful OTP login
              await getPaymentMethods();
              await refreshDefaultPaymentMethod();
            }
          } catch (e) {
            debugPrint('Failed to load user profile after OTP login: $e');
          }
          
          isLoggedIn.value = true;
          debugPrint('   ✅ Login state updated to true');
          
          // Initialize other controllers with data after authentication
          await _initializeControllersAfterAuth();
          
          // Navigate based on user type
          debugPrint('   🧭 About to navigate with userType: $userType');
          _navigateAfterLogin(userType);
          
          return true;
        }
      } else {
        debugPrint('   ❌ No access tokens found in response');
      }
      
      return false;
    } catch (e) {
      debugPrint('OTP login verification error: $e');
      
      // Parse detailed error information
      String errorText = e.toString();
      
      try {
        if (errorText.contains("Email doesn't exist, please create account")) {
          errorMessage.value = "Email doesn't exist, please create account";
        } else if (errorText.contains('Invalid OTP') || errorText.contains('expired')) {
          errorMessage.value = 'Invalid or expired OTP. Please request a new one.';
        } else if (errorText.contains('OTP has expired')) {
          errorMessage.value = 'OTP has expired. Please request a new one.';
        } else if (errorText.contains('network') || errorText.contains('connection')) {
          errorMessage.value = 'Network error. Please check your connection and try again.';
        } else if (errorText.contains('timeout')) {
          errorMessage.value = 'Request timeout. Please try again.';
        } else {
          errorMessage.value = 'OTP verification failed. Please try again.';
        }
      } catch (parseError) {
        debugPrint('Error parsing OTP login verification error: $parseError');
        errorMessage.value = 'OTP verification failed. Please try again.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout({bool navigateToLogin = true}) async {
    try {
      debugPrint('🚪 Logging out user...');
      
      // Clear local data
      token.value = '';
      currentUser.value = null;
      isLoggedIn.value = false;
      paymentMethods.clear();
      defaultPaymentMethod.value = null;
      
      // Clear API service token
      _apiService.clearToken();
      
      // Clear all stored authentication data
      await TokenStorageService.clearAll();
      
      debugPrint('✅ User logged out successfully');
      
      if (navigateToLogin) {
        Get.offAllNamed('/user-selection'); // Navigate to user selection screen
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Starting profile update...');
      
      final response = await _apiService.updateUserProfile(updateData);
      
      // Handle both response formats: direct user data or nested under 'user' key
      Map<String, dynamic>? userData;
      if (response['user'] != null) {
        userData = response['user'];
      } else if (response['id'] != null) {
        // Direct user data format (what backend actually returns)
        userData = response;
      }
      
      if (userData != null) {
        debugPrint('✅ Profile update successful');
        currentUser.value = User.fromJson(userData);
        
        // Save updated user data using new token storage service
        await TokenStorageService.storeUserData(userData);
      } else {
        debugPrint('⚠️ No user data in profile update response');
        debugPrint('📄 Response format: ${response.keys}');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
      
      // If it's an auth error, try to refresh the token or logout
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during profile update, logging out...');
        await logout();
        return false;
      }
      
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasCarAccess {
    return currentUser.value?.hasCar ?? false;
  }

  String get userDisplayName {
    final user = currentUser.value;
    if (user == null) return 'Guest';
    
    if (user.fullName?.isNotEmpty == true) {
      return user.fullName!;
    }
    
    return '${user.firstName} ${user.lastName}';
  }

  /// Load additional user data (payment methods, vehicles, etc.)
  Future<void> _loadAdditionalUserData() async {
    try {
      debugPrint('🔄 Loading additional user data...');
      
      // Load payment methods (don't fail if this fails)
      try {
        await getPaymentMethods();
        await refreshDefaultPaymentMethod();
      } catch (e) {
        debugPrint('⚠️ Failed to load payment methods: $e');
      }
      
      // Load user vehicles (don't fail if this fails)
      try {
        await _loadUserVehiclesSafely();
      } catch (e) {
        debugPrint('⚠️ Failed to load user vehicles: $e');
      }
      
      debugPrint('✅ Additional user data loading completed');
    } catch (e) {
      debugPrint('⚠️ Some additional user data failed to load: $e');
      // Don't fail the entire login process if additional data fails to load
    }
  }

  /// Initialize other controllers after successful authentication
  Future<void> _initializeControllersAfterAuth() async {
    try {
      debugPrint('🔄 Initializing controllers after authentication...');
      
      // Initialize RidesController data
      try {
        final ridesController = Get.find<RidesController>();
        await ridesController.initializeAfterAuth();
        debugPrint('✅ RidesController initialized');
      } catch (e) {
        debugPrint('⚠️ Failed to initialize RidesController: $e');
      }
      
      // Initialize VehicleController data
      try {
        final vehicleController = Get.find<VehicleController>();
        await vehicleController.initializeAfterAuth();
        debugPrint('✅ VehicleController initialized');
      } catch (e) {
        debugPrint('⚠️ Failed to initialize VehicleController: $e');
      }
      
      debugPrint('✅ Controllers initialization completed');
    } catch (e) {
      debugPrint('⚠️ Some controllers failed to initialize: $e');
      // Don't fail the entire login process if controller initialization fails
    }
  }

  /// Safely load user vehicles without triggering logout on auth errors during initial load
  Future<List<Map<String, dynamic>>> _loadUserVehiclesSafely() async {
    try {
      debugPrint('🚗 Fetching user vehicles...');
      final vehicles = await _apiService.getUserVehicles();
      userVehicles.value = List<Map<String, dynamic>>.from(vehicles);
      
      // Find primary vehicle
      final primary = userVehicles.firstWhereOrNull((v) => v['is_primary'] == true);
      primaryVehicle.value = primary;
      
      debugPrint('✅ Loaded ${vehicles.length} vehicles');
      return userVehicles;
    } catch (e) {
      debugPrint('❌ Error fetching user vehicles: $e');
      // Don't logout during initial load, just return empty list
      return [];
    }
  }

  // Payment Method Management
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      debugPrint('🔄 Fetching payment methods...');
      final response = await _apiService.getPaymentMethods();
      
      debugPrint('✅ Payment methods fetched successfully');
      // The response is directly a list from the ApiService
      final methods = List<Map<String, dynamic>>.from(response);
      paymentMethods.value = methods;
      return methods;
    } catch (e) {
      debugPrint('❌ Error fetching payment methods: $e');
      
      // If it's an auth error, try to refresh the token or logout
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during payment methods fetch, logging out...');
        await logout();
      }
      
      return [];
    }
  }

  Future<bool> addPaymentMethod({
    required String type,
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    String? cvv,
    bool isDefault = false,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Adding payment method...');
      
      final paymentData = {
        'type': type,
        'card_number': cardNumber,
        'card_holder_name': cardHolderName,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'is_default': isDefault,
        if (cvv != null) 'cvv': cvv,
      };
      
      final response = await _apiService.addPaymentMethod(paymentData);
      
      // Backend returns the created payment method object
      if (response['id'] != null || response['payment_method'] != null) {
        debugPrint('✅ Payment method added successfully');
        // Refresh payment methods list
        await getPaymentMethods();
        return true;
      }
      
      debugPrint('⚠️ Failed to add payment method');
      return false;
    } catch (e) {
      debugPrint('❌ Error adding payment method: $e');
      
      // If it's an auth error, try to refresh the token or logout
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during payment method add, logging out...');
        await logout();
      }
      
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletePaymentMethod(int paymentMethodId) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Deleting payment method: $paymentMethodId');
      
      final response = await _apiService.deletePaymentMethod(paymentMethodId);
      
      if (response['message'] != null) {
        debugPrint('✅ Payment method deleted successfully');
        // Refresh payment methods list
        await getPaymentMethods();
        return true;
      }
      
      debugPrint('⚠️ Failed to delete payment method');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting payment method: $e');
      
      // If it's an auth error, try to refresh the token or logout
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during payment method delete, logging out...');
        await logout();
      }
      
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> setDefaultPaymentMethod(int paymentMethodId) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Setting default payment method: $paymentMethodId');
      
      final response = await _apiService.setDefaultPaymentMethod(paymentMethodId);
      
      if (response['success'] == true || response['message'] != null) {
        debugPrint('✅ Default payment method set successfully');
        // Refresh payment methods and default payment method
        await getPaymentMethods();
        await refreshDefaultPaymentMethod();
        return true;
      }
      
      debugPrint('⚠️ Failed to set default payment method');
      return false;
    } catch (e) {
      debugPrint('❌ Error setting default payment method: $e');
      
      // If it's an auth error, try to refresh the token or logout
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during default payment method set, logging out...');
        await logout();
      }
      
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getDefaultPaymentMethod() async {
    try {
      debugPrint('🔄 Fetching default payment method...');
      final response = await _apiService.getDefaultPaymentMethod();
      
      // The backend might return the payment method directly or in a nested structure
      if (response.isNotEmpty) {
        debugPrint('✅ Default payment method fetched successfully');
        final paymentMethod = response['payment_method'] ?? response;
        defaultPaymentMethod.value = paymentMethod;
        return paymentMethod;
      }
      
      debugPrint('⚠️ No default payment method found');
      defaultPaymentMethod.value = null;
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching default payment method: $e');
      
      // If it's an auth error, try to refresh the token or logout
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during default payment method fetch, logging out...');
        await logout();
      }
      
      defaultPaymentMethod.value = null;
      return null;
    }
  }

  Future<void> refreshDefaultPaymentMethod() async {
    await getDefaultPaymentMethod();
  }

  String getPaymentMethodDisplayName(Map<String, dynamic> paymentMethod) {
    final type = paymentMethod['type'] ?? 'Card';
    final lastFour = paymentMethod['last_four'] ?? 
                     (paymentMethod['card_number'] != null ? 
                      paymentMethod['card_number'].toString().substring(
                        paymentMethod['card_number'].toString().length - 4
                      ) : '****');
    return '$type ending in $lastFour';
  }

  String getPaymentMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return '💳';
      case 'mastercard':
        return '💳';
      case 'jazzcash':
        return '📱';
      case 'easypaisa':
        return '📱';
      case 'bank':
        return '🏦';
      default:
        return '💳';
    }
  }

  // Profile Picture Management
  Future<bool> uploadProfilePicture(String filePath) async {
    try {
      isLoading.value = true;
      errorMessage.value = ''; // Clear any previous error messages
      debugPrint('🔄 Uploading profile picture...');
      
      // Check file extension
      final extension = filePath.toLowerCase().split('.').last;
      if (extension != 'png' && extension != 'jpg' && extension != 'jpeg') {
        debugPrint('❌ Invalid file format: $extension');
        errorMessage.value = 'Only PNG and JPG files are allowed';
        return false;
      }
      
      final response = await _apiService.uploadProfilePicture(filePath);
      
      // Handle both response formats: direct user data or nested under 'user' key
      Map<String, dynamic>? userData;
      if (response['user'] != null) {
        userData = response['user'];
      } else if (response['id'] != null) {
        // Direct user data format (what backend actually returns)
        userData = response;
      }
      
      if (userData != null) {
        debugPrint('✅ Profile picture uploaded successfully');
        currentUser.value = User.fromJson(userData);
        
        // Save updated user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
        return true;
      }
      
      debugPrint('⚠️ Failed to upload profile picture - no user data in response');
      debugPrint('📄 Response format: ${response.keys}');
      errorMessage.value = 'Failed to upload profile picture. Please try again.';
      return false;
    } catch (e) {
      debugPrint('❌ Error uploading profile picture: $e');
      
      if (e.toString().contains('413')) {
        errorMessage.value = 'File size too large. Please choose a smaller image.';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during profile picture upload, logging out...');
        errorMessage.value = 'Session expired. Please login again.';
        await logout();
      } else {
        errorMessage.value = 'Failed to upload profile picture. Please try again.';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteProfilePicture() async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Deleting profile picture...');
      
      final response = await _apiService.deleteProfilePicture();
      
      // Handle both response formats: direct user data or nested under 'user' key
      Map<String, dynamic>? userData;
      if (response['user'] != null) {
        userData = response['user'];
      } else if (response['id'] != null) {
        // Direct user data format (what backend actually returns)
        userData = response;
      }
      
      // Success case: Profile picture existed and was deleted (HTTP 200 with user data)
      if (userData != null) {
        debugPrint('✅ Profile picture deleted successfully');
        currentUser.value = User.fromJson(userData);
        
        // Save updated user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
        return true;
      }
      
      // Also success case: No profile picture to delete (HTTP 404 with message)
      if (response['message'] != null) {
        debugPrint('✅ Profile picture deletion successful: ${response['message']}');
        // Refresh user data since profile picture is already null
        if (currentUser.value != null) {
          // Create updated user with null profile picture
          final userMap = currentUser.value!.toJson();
          userMap['profile_picture'] = null;
          userMap['profile_picture_url'] = null;
          currentUser.value = User.fromJson(userMap);
          
          // Save updated user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(userMap));
        }
        return true;
      }
      
      debugPrint('⚠️ Failed to delete profile picture - unexpected response format');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting profile picture: $e');
      
      // Handle HTTP 404 as success (no profile picture to delete)
      if (e.toString().contains('404') || e.toString().contains('No profile picture to delete')) {
        debugPrint('✅ Profile picture deletion successful: No profile picture existed to delete');
        // Update current user to ensure profile picture is null
        if (currentUser.value != null) {
          final userMap = currentUser.value!.toJson();
          userMap['profile_picture'] = null;
          userMap['profile_picture_url'] = null;
          currentUser.value = User.fromJson(userMap);
          
          // Save updated user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(userMap));
        }
        return true;
      }
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during profile picture delete, logging out...');
        await logout();
      } else {
        errorMessage.value = 'Failed to delete profile picture: $e';
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String? get profilePictureUrl {
    return currentUser.value?.profilePicture;
  }

  // Ride Preference Management
  Future<Map<String, dynamic>?> getRidePreferences() async {
    try {
      debugPrint('🔄 Fetching ride preferences...');
      final response = await _apiService.getRidePreferences();
      
      debugPrint('✅ Ride preferences fetched successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching ride preferences: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during ride preferences fetch, logging out...');
        await logout();
      }
      
      return null;
    }
  }

  Future<bool> updateRidePreferences(Map<String, dynamic> preferences) async {
    try {
      isLoading.value = true;
      debugPrint('🔄 Updating ride preferences...');
      
      final response = await _apiService.updateRidePreferences(preferences);
      
      if (response['message'] != null) {
        debugPrint('✅ Ride preferences updated successfully');
        // Refresh user profile to get updated preferences
        try {
          final userResponse = await _apiService.getUserProfile();
          if (userResponse['user'] != null) {
            currentUser.value = User.fromJson(userResponse['user']);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to refresh user profile after preference update: $e');
        }
        return true;
      }
      
      debugPrint('⚠️ Failed to update ride preferences');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating ride preferences: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during ride preferences update, logging out...');
        await logout();
      } else {
        errorMessage.value = e.toString();
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Vehicle Management Methods
  final RxList<Map<String, dynamic>> userVehicles = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> primaryVehicle = Rx<Map<String, dynamic>?>(null);

  Future<List<Map<String, dynamic>>> getUserVehicles() async {
    try {
      debugPrint('🚗 Fetching user vehicles...');
      final vehicles = await _apiService.getUserVehicles();
      userVehicles.value = List<Map<String, dynamic>>.from(vehicles);
      
      // Find primary vehicle
      final primary = userVehicles.firstWhereOrNull((v) => v['is_primary'] == true);
      primaryVehicle.value = primary;
      
      debugPrint('✅ Loaded ${vehicles.length} vehicles');
      return userVehicles;
    } catch (e) {
      debugPrint('❌ Error fetching user vehicles: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during vehicle fetch');
        // Try to refresh token first
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          // Retry the request
          try {
            final vehicles = await _apiService.getUserVehicles();
            userVehicles.value = List<Map<String, dynamic>>.from(vehicles);
            
            final primary = userVehicles.firstWhereOrNull((v) => v['is_primary'] == true);
            primaryVehicle.value = primary;
            
            debugPrint('✅ Loaded ${vehicles.length} vehicles after token refresh');
            return userVehicles;
          } catch (retryError) {
            debugPrint('❌ Failed to fetch vehicles after token refresh, logging out...');
            await logout();
          }
        } else {
          debugPrint('❌ Token refresh failed, logging out...');
          await logout();
        }
      } else {
        errorMessage.value = e.toString();
      }
      
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveVehicles() async {
    try {
      debugPrint('🚗 Fetching active user vehicles...');
      final vehicles = await _apiService.getActiveVehicles();
      
      debugPrint('✅ Loaded ${vehicles.length} active vehicles');
      return List<Map<String, dynamic>>.from(vehicles);
    } catch (e) {
      debugPrint('❌ Error fetching active vehicles: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during active vehicles fetch, logging out...');
        await logout();
      } else {
        errorMessage.value = e.toString();
      }
      
      return [];
    }
  }

  Future<bool> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      isLoading.value = true;
      debugPrint('🚗 Creating new vehicle...');
      
      final response = await _apiService.createVehicle(vehicleData);
      
      if (response['id'] != null) {
        debugPrint('✅ Vehicle created successfully');
        
        // Update user's has_car status if this is their first vehicle
        if (currentUser.value != null) {
          currentUser.value = currentUser.value!.copyWith(hasCar: true);
        }
        
        // Refresh vehicle list
        await getUserVehicles();
        return true;
      }
      
      debugPrint('⚠️ Failed to create vehicle');
      return false;
    } catch (e) {
      debugPrint('❌ Error creating vehicle: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during vehicle creation, logging out...');
        await logout();
      } else {
        errorMessage.value = e.toString();
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateVehicle(int vehicleId, Map<String, dynamic> vehicleData) async {
    try {
      isLoading.value = true;
      debugPrint('🚗 Updating vehicle $vehicleId...');
      
      final response = await _apiService.updateVehicle(vehicleId, vehicleData);
      
      if (response['id'] != null) {
        debugPrint('✅ Vehicle updated successfully');
        
        // Refresh vehicle list
        await getUserVehicles();
        return true;
      }
      
      debugPrint('⚠️ Failed to update vehicle');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating vehicle: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during vehicle update, logging out...');
        await logout();
      } else {
        errorMessage.value = e.toString();
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    try {
      isLoading.value = true;
      debugPrint('🚗 Deleting vehicle $vehicleId...');
      
      await _apiService.deleteVehicle(vehicleId);
      
      debugPrint('✅ Vehicle deleted successfully');
      
      // Refresh vehicle list
      await getUserVehicles();
      
      // Update user's has_car status if no vehicles left
      if (userVehicles.isEmpty && currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(hasCar: false);
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting vehicle: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during vehicle deletion, logging out...');
        await logout();
      } else {
        errorMessage.value = e.toString();
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> setPrimaryVehicle(int vehicleId) async {
    try {
      debugPrint('🚗 Setting vehicle $vehicleId as primary...');
      
      final response = await _apiService.setPrimaryVehicle(vehicleId);
      
      if (response['message'] != null) {
        debugPrint('✅ Primary vehicle set successfully');
        
        // Refresh vehicle list
        await getUserVehicles();
        return true;
      }
      
      debugPrint('⚠️ Failed to set primary vehicle');
      return false;
    } catch (e) {
      debugPrint('❌ Error setting primary vehicle: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during primary vehicle setting, logging out...');
        await logout();
      } else {
        errorMessage.value = e.toString();
      }
      
      return false;
    }
  }

  Future<bool> toggleVehicleActive(int vehicleId) async {
    try {
      debugPrint('🚗 Toggling vehicle $vehicleId active status...');
      
      final response = await _apiService.toggleVehicleActive(vehicleId);
      
      if (response['message'] != null) {
        debugPrint('✅ Vehicle status toggled successfully');
        
        // Refresh vehicle list
        await getUserVehicles();
        return true;
      }
      
      debugPrint('⚠️ Failed to toggle vehicle status');
      return false;
    } catch (e) {
      debugPrint('❌ Error toggling vehicle status: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error during vehicle toggle, logging out...');
        await logout();
      } else {
        errorMessage.value = e.toString();
      }
      
      return false;
    }
  }

  /// Debug method to test authentication flow
  Future<void> debugAuthTest() async {
    if (kDebugMode) {
      await DebugAuthTest.testAuthenticationFlow();
    }
  }

  /// Debug method to test token refresh
  Future<void> debugTokenRefresh() async {
    if (kDebugMode) {
      await DebugAuthTest.testTokenRefresh();
    }
  }

  /// Debug method to test rides endpoints
  Future<void> debugTestRidesEndpoints() async {
    if (kDebugMode) {
      await DebugRidesTest.testRideEndpoints();
    }
  }

  /// Quick test for available rides endpoint
  Future<void> debugTestAvailableRides() async {
    if (kDebugMode) {
      await DebugRidesTest.testAvailableRidesOnly();
    }
  }

  /// Refresh current user data from the server
  Future<void> refreshUserData() async {
    try {
      debugPrint('🔄 AuthController: Refreshing user data...');
      
      if (token.value.isEmpty) {
        debugPrint('❌ AuthController: No token available for refresh');
        return;
      }

      // Get fresh user data from the server using existing method
      final response = await _apiService.getUserProfile();
      debugPrint('📄 AuthController: Raw user data from API: $response');
      
      // Handle different response structures
      Map<String, dynamic> userData;
      if (response.containsKey('user') && response['user'] is Map<String, dynamic>) {
        userData = response['user'] as Map<String, dynamic>;
      } else {
        userData = response;
      }
      
      debugPrint('📄 AuthController: Processed user data: $userData');
      debugPrint('📄 AuthController: Gender field: ${userData['gender']}');
      
      // Create user with additional error handling
      try {
        final user = User.fromJson(userData);
        
        // Update current user
        currentUser.value = user;
        
        // Save updated user data to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
        
        debugPrint('✅ AuthController: User data refreshed successfully');
        debugPrint('📄 AuthController: Updated user verification status: ${user.isDriverVerified}');
        debugPrint('📄 AuthController: Updated user gender: ${user.gender}');
      } catch (userParseError) {
        debugPrint('❌ AuthController: Error parsing user data: $userParseError');
        debugPrint('📄 AuthController: Problem data: $userData');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ AuthController: Error refreshing user data: $e');
    }
  }
}

// Global instance
final authController = Get.put(AuthController());
