import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import '../constants/app_config.dart';
import '../controllers/auth_controller.dart';
import 'token_storage_service.dart';

class ApiService {
  static const String baseUrl = '${AppConfig.baseUrl}/api';
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add request interceptor for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Priority order for getting token:
        // 1. Local _token (set via setToken)
        // 2. AuthController token
        // 3. TokenStorageService (for app restart scenarios)
        
        String? authToken;
        
        // First try local token
        if (_token != null && _token!.isNotEmpty) {
          authToken = _token;
        } else {
          // Try to get token from AuthController if available
          try {
            final authController = Get.find<AuthController>();
            if (authController.isLoggedIn.value && authController.token.value.isNotEmpty) {
              authToken = authController.token.value;
            }
          } catch (e) {
            // AuthController not available, try TokenStorageService
            try {
              authToken = await TokenStorageService.getAccessToken();
            } catch (storageError) {
              debugPrint('⚠️ Could not retrieve token from storage: $storageError');
            }
          }
        }
        
        // Set authorization header if we have a token
        if (authToken != null && authToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $authToken';
          debugPrint('🔑 Authorization header set for ${options.path}');
        } else {
          debugPrint('⚠️ No auth token available for ${options.path}');
        }
        
        debugPrint('🌐 API Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) async {
        // Only log critical errors, not authentication issues which are expected
        if (error.response?.statusCode != 401) {
          debugPrint('❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          if (error.response?.data != null) {
            debugPrint('Error details: ${error.response!.data}');
          }
        } else {
          debugPrint('🔒 Authentication required for ${error.requestOptions.path}');
          
          // Attempt token refresh on 401 errors
          if (await _attemptTokenRefresh()) {
            debugPrint('🔄 Retrying request after token refresh...');
            
            // Get the new token for retry
            String? newToken = _token;
            if (newToken == null || newToken.isEmpty) {
              newToken = await TokenStorageService.getAccessToken();
            }
            
            // Retry the original request with new token
            final retryHeaders = Map<String, dynamic>.from(error.requestOptions.headers);
            if (newToken != null && newToken.isNotEmpty) {
              retryHeaders['Authorization'] = 'Bearer $newToken';
            }
            
            final opts = Options(
              method: error.requestOptions.method,
              headers: retryHeaders,
            );
            
            try {
              final response = await _dio.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              debugPrint('✅ Request retry successful after token refresh');
              return handler.resolve(response);
            } catch (retryError) {
              debugPrint('❌ Request retry failed even after token refresh: $retryError');
              // If retry fails, continue with original error
            }
          } else {
            debugPrint('❌ Token refresh failed, request will fail');
          }
        }
        handler.next(error);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
    debugPrint('🔑 API Service token updated');
    
    // Also update AuthController if available
    try {
      final authController = Get.find<AuthController>();
      if (authController.token.value != token) {
        authController.token.value = token;
        debugPrint('🔑 AuthController token synchronized');
      }
    } catch (e) {
      // AuthController not available, continue
      debugPrint('⚠️ AuthController not available for token sync');
    }
  }

  void clearToken() {
    _token = null;
    debugPrint('🔑 API Service token cleared');
  }

  // Connection test endpoint
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing connection to: $baseUrl');
      final response = await _dio.get('/test/', options: Options(
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Backend server is reachable');
        debugPrint('📡 Response: ${response.data}');
        return true;
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      // Handle rate limiting as a special case
      if (e.response?.statusCode == 429) {
        debugPrint('⚠️ Rate limited on connection test - but server is running');
        throw Exception('429 Too Many Requests');
      }
      
      debugPrint('❌ Backend server connection failed: ${e.message}');
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          debugPrint('💡 Connection timeout - Backend server may not be running');
          break;
        case DioExceptionType.connectionError:
          debugPrint('💡 Connection error - Check if backend server is running on $baseUrl');
          debugPrint('💡 Make sure Django server is started with: python manage.py runserver 192.168.100.32:8000');
          break;
        case DioExceptionType.receiveTimeout:
          debugPrint('💡 Receive timeout - Backend server is slow to respond');
          break;
        default:
          debugPrint('💡 Other error: ${e.message}');
          debugPrint('💡 Status code: ${e.response?.statusCode}');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error during connection test: $e');
      return false;
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/token/', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/auth/register/', data: userData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // OTP endpoints
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await _dio.post('/auth/send_otp/', data: {
        'email': email,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otpCode) async {
    try {
      final response = await _dio.post('/auth/verify_otp/', data: {
        'email': email,
        'otp_code': otpCode,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> loginWithOTP(String usernameOrEmail) async {
    try {
      final response = await _dio.post('/auth/login_with_otp/', data: {
        'username': usernameOrEmail,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyLoginOTP(String usernameOrEmail, String otpCode) async {
    try {
      final response = await _dio.post('/auth/verify_login_otp/', data: {
        'username': usernameOrEmail,
        'otp_code': otpCode,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // User Profile endpoints
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/users/me/');
      debugPrint('🔍 ApiService: Raw /users/me/ response: ${response.data}');
      // Check if response.data is already the user object or wrapped in 'user' key
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('user')) {
          // Response already has user key
          debugPrint('🔍 ApiService: Response already has user key');
          return data;
        } else {
          // Response is the user object directly
          debugPrint('🔍 ApiService: Response is user object directly');
          return {'user': data}; // Wrap in user key for compatibility
        }
      }
      return {'user': response.data}; // Fallback wrap
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      // Use the standard update endpoint for the current user
      final response = await _dio.patch('/users/me/', data: profileData);
      return {'user': response.data}; // Wrap in user key for compatibility
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Payment Method endpoints
  Future<List<dynamic>> getPaymentMethods() async {
    try {
      debugPrint('🔄 ApiService: Getting payment methods...');
      final response = await _dio.get('/payment-methods/');
      debugPrint('✅ ApiService: Payment methods retrieved successfully');
      
      // Ensure we return a List even if the backend returns a different structure
      if (response.data is List) {
        return response.data;
      } else if (response.data is Map && response.data['results'] != null) {
        return response.data['results'];
      } else if (response.data is Map && response.data['payment_methods'] != null) {
        return response.data['payment_methods'];
      } else {
        debugPrint('⚠️ Unexpected payment methods response format: ${response.data}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ ApiService: Error getting payment methods: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addPaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      debugPrint('🔄 ApiService: Adding payment method...');
      final response = await _dio.post('/payment-methods/', data: paymentData);
      debugPrint('✅ ApiService: Payment method added successfully');
      return response.data;
    } catch (e) {
      debugPrint('❌ ApiService: Error adding payment method: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deletePaymentMethod(int paymentMethodId) async {
    try {
      debugPrint('🔄 ApiService: Deleting payment method: $paymentMethodId');
      final response = await _dio.delete('/payment-methods/$paymentMethodId/');
      debugPrint('✅ ApiService: Payment method deleted successfully');
      return response.data ?? {'message': 'Payment method deleted successfully'};
    } catch (e) {
      debugPrint('❌ ApiService: Error deleting payment method: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setDefaultPaymentMethod(int paymentMethodId) async {
    try {
      debugPrint('🔄 ApiService: Setting default payment method: $paymentMethodId');
      final response = await _dio.patch('/payment-methods/$paymentMethodId/set-default/');
      debugPrint('✅ ApiService: Default payment method set successfully');
      return response.data ?? {'success': true, 'message': 'Default payment method set successfully'};
    } catch (e) {
      debugPrint('❌ ApiService: Error setting default payment method: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDefaultPaymentMethod() async {
    try {
      debugPrint('🔄 ApiService: Getting default payment method...');
      final response = await _dio.get('/payment-methods/default/');
      debugPrint('✅ ApiService: Default payment method retrieved successfully');
      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ ApiService: Error getting default payment method: $e');
      rethrow;
    }
  }

  // Profile Picture endpoints
  Future<Map<String, dynamic>> uploadProfilePicture(String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "profile_picture": await MultipartFile.fromFile(filePath, filename: fileName),
      });
      
      final response = await _dio.post('/users/upload_picture/', data: formData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteProfilePicture() async {
    try {
      final response = await _dio.delete('/users/delete_picture/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Ride endpoints
  Future<List<dynamic>> getAvailableRides() async {
    try {
      final response = await _dio.get('/rides/available_rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> searchRides({
    String? pickup,
    String? dropoff,
    String? date,
    String? departureTime,
    double? lat,
    double? lng,
    double? destLat,
    double? destLng,
    int? timeFlexibility,
  }) async {
    try {
      Map<String, dynamic> params = {};
      if (pickup != null) params['pickup'] = pickup;
      if (dropoff != null) params['dropoff'] = dropoff;
      if (date != null) params['date'] = date;
      if (departureTime != null) params['departure_time'] = departureTime;
      if (lat != null) params['lat'] = lat.toString();
      if (lng != null) params['lng'] = lng.toString();
      if (destLat != null) params['dest_lat'] = destLat.toString();
      if (destLng != null) params['dest_lng'] = destLng.toString();
      if (timeFlexibility != null) params['time_flexibility'] = timeFlexibility.toString();

      final response = await _dio.get('/rides/passenger-search/search_rides/', queryParameters: params);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createRide(Map<String, dynamic> rideData) async {
    try {
      // Ensure vehicle_id is included in ride data
      if (!rideData.containsKey('vehicle_id')) {
        throw Exception('Vehicle ID is required to create a ride');
      }
      
      final response = await _dio.post('/rides/rides/', data: rideData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateRide(int rideId, Map<String, dynamic> rideData) async {
    try {
      final response = await _dio.patch('/rides/rides/$rideId/', data: rideData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> joinRide(int rideId, {String? pickupNote}) async {
    try {
      final response = await _dio.post('/rides/rides/$rideId/join/', data: {
        if (pickupNote != null) 'pickup_note': pickupNote,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> leaveRide(int rideId) async {
    try {
      await _dio.post('/rides/rides/$rideId/leave_ride/');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRidePassengerDetails(int rideId) async {
    try {
      final response = await _dio.get('/rides/rides/$rideId/passenger_details/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> managePassenger(int rideId, int passengerId, String action) async {
    try {
      final response = await _dio.post('/rides/rides/$rideId/manage_passengers/', data: {
        'passenger_id': passengerId,
        'action': action, // 'confirm' or 'reject'
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyOfferedRides() async {
    try {
      final response = await _dio.get('/rides/my_offered_rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyJoinedRides() async {
    try {
      final response = await _dio.get('/rides/my_joined_rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPendingRequestsForMyRides() async {
    try {
      final response = await _dio.get('/ride-passengers/pending_requests_for_my_rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // New endpoints for frontend features
  Future<Map<String, dynamic>> calculateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required int seats,
    String? departureTime,
  }) async {
    try {
      final response = await _dio.post('/ride-passengers/calculate_fare/', data: {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'seats': seats,
        if (departureTime != null) 'departure_time': departureTime,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> rateRide(int rideId, int rating, {String? comment}) async {
    try {
      final response = await _dio.post('/rides/rides/$rideId/rate_ride/', data: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Enhanced review methods for comprehensive review system
  Future<Map<String, dynamic>> createDetailedReview({
    required int rideId,
    required int revieweeId,
    required int rating,
    String? comment,
    int? punctualityRating,
    int? cleanlinessRating,
    int? communicationRating,
    int? safetyRating,
  }) async {
    try {
      final response = await _dio.post('/rides/user-reviews/', data: {
        'ride': rideId,
        'reviewee': revieweeId,
        'reviewer_type': 'passenger', // Required field for API
        'overall_rating': rating,
        if (comment != null) 'comment': comment,
        'punctuality_rating': punctualityRating ?? rating,
        'cleanliness_rating': cleanlinessRating ?? rating,
        'communication_rating': communicationRating ?? rating,
        'safety_rating': safetyRating ?? rating,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyReceivedReviews() async {
    try {
      final response = await _dio.get('/rides/user-reviews/my_received/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyGivenReviews() async {
    try {
      final response = await _dio.get('/rides/user-reviews/my_given/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserReceivedReviews(int userId) async {
    try {
      final response = await _dio.get('/rides/user-reviews/user/$userId/summary/');
      return response.data['recent_reviews'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserGivenReviews(int userId) async {
    try {
      final response = await _dio.get('/rides/user-reviews/my_given/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Alias methods for passenger review screen
  Future<Map<String, dynamic>> getReceivedReviews() async {
    try {
      final response = await _dio.get('/rides/user-reviews/my_received/');
      return {'results': response.data};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getGivenReviews() async {
    try {
      final response = await _dio.get('/rides/user-reviews/my_given/');
      return {'results': response.data};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserReviewSummary([int? userId]) async {
    try {
      final endpoint = userId != null 
          ? '/rides/user-reviews/user/$userId/summary/'
          : '/rides/user-reviews/my_summary/';
      final response = await _dio.get(endpoint);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> searchAreas(String query) async {
    try {
      final response = await _dio.get('/ride-passengers/search_areas/', queryParameters: {
        'q': query,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserRideHistory() async {
    try {
      final response = await _dio.get('/ride-passengers/user_ride_history/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getRecommendedRides({
    double? lat,
    double? lng,
    double? destLat,
    double? destLng,
  }) async {
    try {
      Map<String, dynamic> params = {};
      if (lat != null) params['lat'] = lat.toString();
      if (lng != null) params['lng'] = lng.toString();
      if (destLat != null) params['dest_lat'] = destLat.toString();
      if (destLng != null) params['dest_lng'] = destLng.toString();

      final response = await _dio.get('/rides/recommended_rides/', queryParameters: params);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getColleaguesRides() async {
    try {
      final response = await _dio.get('/rides/colleagues_rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> startRide(int rideId) async {
    try {
      final response = await _dio.post('/rides/rides/$rideId/start_ride/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> completeRide(int rideId) async {
    try {
      final response = await _dio.post('/rides/rides/$rideId/complete_ride/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelRide(int rideId) async {
    try {
      final response = await _dio.post('/rides/rides/$rideId/cancel_ride/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Location endpoints
  Future<List<dynamic>> getWorkplaces() async {
    try {
      final response = await _dio.get('/rides/locations/workplaces/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getLocations() async {
    try {
      final response = await _dio.get('/rides/locations/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Ride Preferences endpoints
  Future<Map<String, dynamic>> getRidePreferences() async {
    try {
      debugPrint('🔄 ApiService: Getting ride preferences...');
      final response = await _dio.get('/users/ride-preferences/');
      debugPrint('✅ ApiService: Ride preferences retrieved successfully');
      return response.data;
    } catch (e) {
      debugPrint('❌ ApiService: Error getting ride preferences: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateRidePreferences(Map<String, dynamic> preferences) async {
    try {
      debugPrint('🔄 ApiService: Updating ride preferences...');
      final response = await _dio.patch('/users/ride-preferences/', data: preferences);
      debugPrint('✅ ApiService: Ride preferences updated successfully');
      return response.data;
    } catch (e) {
      debugPrint('❌ ApiService: Error updating ride preferences: $e');
      rethrow;
    }
  }

  // Vehicle endpoints
  Future<List<dynamic>> getUserVehicles() async {
    try {
      final response = await _dio.get('/vehicles/');
      // Handle both paginated and non-paginated responses
      if (response.data is Map && response.data.containsKey('results')) {
        return response.data['results'];
      } else if (response.data is List) {
        return response.data;
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getActiveVehicles() async {
    try {
      final response = await _dio.get('/vehicles/active_vehicles/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPrimaryVehicle() async {
    try {
      final response = await _dio.get('/vehicles/primary_vehicle/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await _dio.post('/vehicles/', data: vehicleData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateVehicle(int vehicleId, Map<String, dynamic> vehicleData) async {
    try {
      final response = await _dio.patch('/vehicles/$vehicleId/', data: vehicleData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    try {
      await _dio.delete('/vehicles/$vehicleId/');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> setPrimaryVehicle(int vehicleId) async {
    try {
      final response = await _dio.post('/vehicles/$vehicleId/set_primary/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> toggleVehicleActive(int vehicleId) async {
    try {
      final response = await _dio.post('/vehicles/$vehicleId/toggle_active/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // ENHANCED RIDE & FARE CALCULATION METHODS
  // ============================================================================

  /// Calculate individual passenger fare
  Future<Map<String, dynamic>> calculateIndividualFare({
    required double passengerDistanceKm,
    required String departureTime,
  }) async {
    try {
      final response = await _dio.post('/rides/fare/individual/', data: {
        'passenger_distance_km': passengerDistanceKm,
        'departure_time': departureTime,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Search for available rides for passengers (enhanced)
  Future<Map<String, dynamic>> searchRidesEnhanced({
    required String pickupLocation,
    required String dropoffLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String departureTime,
    bool femaleOnly = false,
  }) async {
    try {
      final response = await _dio.get('/rides/rides/search-rides-enhanced/', queryParameters: {
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'pickup_latitude': pickupLatitude.toString(),
        'pickup_longitude': pickupLongitude.toString(),
        'dropoff_latitude': dropoffLatitude.toString(),
        'dropoff_longitude': dropoffLongitude.toString(),
        'departure_time': departureTime,
        'female_only': femaleOnly.toString(),
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a ride request
  Future<Map<String, dynamic>> createRideRequest({
    required int rideId,
    required String pickupLocation,
    required String dropoffLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    String? message,
    int seatsRequested = 1,
  }) async {
    try {
      final response = await _dio.post('/rides/ride-requests/', data: {
        'ride': rideId,
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'message': message ?? '',
        'seats_requested': seatsRequested,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get driver dashboard data
  Future<Map<String, dynamic>> getDriverDashboard() async {
    try {
      final response = await _dio.get('/rides/driver-dashboard/dashboard/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get upcoming rides for driver
  Future<List<dynamic>> getUpcomingRides() async {
    try {
      final response = await _dio.get('/rides/driver-dashboard/upcoming_rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get pending ride requests for driver
  Future<List<dynamic>> getPendingRideRequests() async {
    try {
      final response = await _dio.get('/rides/driver-dashboard/pending_requests/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Accept a ride request
  Future<Map<String, dynamic>> acceptRideRequest(int requestId, {String? message}) async {
    try {
      final response = await _dio.post('/rides/ride-requests/$requestId/accept/', data: {
        'message': message ?? '',
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Reject a ride request
  Future<Map<String, dynamic>> rejectRideRequest(int requestId, {String? message}) async {
    try {
      final response = await _dio.post('/rides/ride-requests/$requestId/reject/', data: {
        'message': message ?? '',
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Start a ride (enhanced)
  Future<Map<String, dynamic>> startRideEnhanced(int rideId) async {
    try {
      final response = await _dio.post('/rides/driver-dashboard/$rideId/start_ride/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create enhanced ride with vehicle verification
  Future<Map<String, dynamic>> createEnhancedRide({
    required int vehicleId,
    required String departureTime,
    required String pickupLocation,
    required String dropoffLocation,
    required int totalSeats,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    bool isRecurring = false,
    List<String>? recurringDays,
    String? notes,
    String genderPreference = 'any',
    bool isFemaleOnly = false,
  }) async {
    try {
      final response = await _dio.post('/rides/', data: {
        'vehicle_id': vehicleId,
        'departure_time': departureTime,
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'total_seats': totalSeats,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'is_recurring': isRecurring,
        'recurring_days': recurringDays,
        'notes': notes,
        'gender_preference': genderPreference,
        'is_female_only': isFemaleOnly,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's vehicles with verification status (enhanced)
  Future<List<dynamic>> getUserVehiclesEnhanced() async {
    try {
      final response = await _dio.get('/rides/vehicle-verification/my_vehicles/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit vehicle for verification
  Future<Map<String, dynamic>> submitVehicleVerification(
    int vehicleId, {
    String? registrationBookPath,
    String? carImagePath,
  }) async {
    try {
      FormData formData = FormData();
      
      if (registrationBookPath != null) {
        formData.files.add(MapEntry(
          'registration_book',
          await MultipartFile.fromFile(registrationBookPath),
        ));
      }
      
      if (carImagePath != null) {
        formData.files.add(MapEntry(
          'car_image',
          await MultipartFile.fromFile(carImagePath),
        ));
      }

      final response = await _dio.post(
        '/rides/vehicle-verification/$vehicleId/submit_verification/',
        data: formData,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get passenger's ride requests from RideRequestViewSet
  Future<List<dynamic>> getMyRideRequests() async {
    try {
      final response = await _dio.get('/rides/ride-requests/');
      return response.data['results'] ?? response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Toggle female-only status for a ride
  Future<Map<String, dynamic>> toggleFemaleOnlyRide(int rideId) async {
    try {
      final response = await _dio.post('/rides/rides/$rideId/toggle_female_only/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's rides (as driver and passenger) from EnhancedRideViewSet
  Future<Map<String, dynamic>> getMyRides() async {
    try {
      final response = await _dio.get('/rides/rides/my_rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== TOKEN MANAGEMENT =====
  
  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh/', data: {
        'refresh': refreshToken,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Set tokens in the API service
  void setTokens(String accessToken, [String? refreshToken]) {
    _token = accessToken;
    // Store refresh token if needed for future use
  }

  /// Attempt to refresh the access token automatically
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshTokenValue = await TokenStorageService.getRefreshToken();
      
      if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
        return false;
      }
      
      final response = await refreshToken(refreshTokenValue);
      
      if (response['access'] != null) {
        final newAccessToken = response['access'];
        final newRefreshToken = response['refresh'];
        
        // Calculate expiry time
        final expiryTime = DateTime.now().add(const Duration(hours: 24));
        
        // Store new tokens
        await TokenStorageService.storeTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshTokenValue,
          expiryTime: expiryTime,
        );
        
        // Update current token
        _token = newAccessToken;
        
        debugPrint('✅ Token automatically refreshed');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Automatic token refresh failed: $e');
      return false;
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map<String, dynamic>) {
          // Handle different error response formats
          if (data.containsKey('error')) {
            return data['error'].toString();
          }
          if (data.containsKey('detail')) {
            return data['detail'].toString();
          }
          if (data.containsKey('message')) {
            return data['message'].toString();
          }
          // Handle field validation errors
          if (data.containsKey('non_field_errors')) {
            return (data['non_field_errors'] as List).join(', ');
          }
          // Handle field-specific errors
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.add('$key: ${value.join(', ')}');
            } else {
              errors.add('$key: $value');
            }
          });
          if (errors.isNotEmpty) {
            return errors.join('\n');
          }
        }
        return data.toString();
      }
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.receiveTimeout:
          return 'Server response timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server. Please check your internet connection.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return error.toString();
  }

  // Driver Verification API Methods
  Future<Map<String, dynamic>?> getDriverVerificationStatus() async {
    try {
      final response = await _dio.get('/driver/verification/status/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitDriverVerification({
    required String cnicNumber,
    required String driverLicenseNumber,
    File? cnicFrontImage,
    File? cnicBackImage,
    File? licenseFrontImage,
    File? licenseBackImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'cnic_number': cnicNumber,
        'driver_license_number': driverLicenseNumber,
      });

      // Only add images that are provided (for resubmission scenarios)
      if (cnicFrontImage != null) {
        formData.files.add(MapEntry(
          'cnic_front_image',
          await MultipartFile.fromFile(cnicFrontImage.path),
        ));
      }
      if (cnicBackImage != null) {
        formData.files.add(MapEntry(
          'cnic_back_image',
          await MultipartFile.fromFile(cnicBackImage.path),
        ));
      }
      if (licenseFrontImage != null) {
        formData.files.add(MapEntry(
          'driver_license_front_image',
          await MultipartFile.fromFile(licenseFrontImage.path),
        ));
      }
      if (licenseBackImage != null) {
        formData.files.add(MapEntry(
          'driver_license_back_image',
          await MultipartFile.fromFile(licenseBackImage.path),
        ));
      }

      final response = await _dio.post('/driver/verification/submit/', data: formData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== ADMIN API METHODS =====
  
  /// Get user details for admin
  Future<Map<String, dynamic>> getUserDetails(int userId) async {
    try {
      final response = await _dio.get('/users/$userId/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all users for admin dashboard
  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get('/users/admin/users/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all rides for admin dashboard
  Future<List<dynamic>> getAllRides() async {
    try {
      final response = await _dio.get('/users/admin/rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get admin analytics
  Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      final response = await _dio.get('/users/admin/analytics/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Suspend user (admin only)
  Future<Map<String, dynamic>> suspendUser(int userId) async {
    try {
      final response = await _dio.post('/users/admin/users/$userId/suspend/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete user (admin only)
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await _dio.delete('/users/admin/users/$userId/delete/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel ride (admin only)
  Future<Map<String, dynamic>> adminCancelRide(int rideId, {String? reason}) async {
    try {
      final response = await _dio.post('/users/admin/rides/$rideId/cancel/', data: {
        'reason': reason ?? 'Cancelled by admin',
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _dio.get('/users/admin/analytics/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all users (admin only)
  Future<List<dynamic>> getAdminUsers() async {
    try {
      final response = await _dio.get('/users/admin/users/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all rides (admin only)
  Future<List<dynamic>> getAdminRides() async {
    try {
      final response = await _dio.get('/users/admin/rides/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user details (admin only)
  Future<Map<String, dynamic>> getAdminUserDetails(int userId) async {
    try {
      final response = await _dio.get('/users/admin/users/$userId/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic HTTP methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }
}

// Singleton instance
final apiService = ApiService();
