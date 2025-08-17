import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/fare_service.dart';
import '../models/ride_models.dart';

class RidesController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  
  final RxList<Ride> availableRides = <Ride>[].obs;
  final RxList<Ride> myOfferedRides = <Ride>[].obs;
  final RxList<Ride> myJoinedRides = <Ride>[].obs;
  final RxList<RideRequest> pendingRequests = <RideRequest>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isCreatingRide = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Don't automatically load data - wait for authentication
    debugPrint('🚗 RidesController initialized - data loading deferred until authentication');
  }

  /// Initialize rides data after user authentication
  Future<void> initializeAfterAuth() async {
    debugPrint('🔐 Initializing rides data after authentication...');
    await loadAllRideData();
  }

  Future<void> loadAllRideData() async {
    await Future.wait([
      loadAvailableRides(),
      loadMyOfferedRides(),
      loadMyJoinedRides(),
      loadPendingRequests(),
    ]);
  }

  Future<void> loadAvailableRides() async {
    try {
      isLoading.value = true;
      final ridesData = await apiService.getAvailableRides();
      availableRides.value = ridesData.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      error.value = 'Error loading available rides: $e';
      debugPrint('Error loading available rides: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyOfferedRides() async {
    try {
      final ridesData = await apiService.getMyOfferedRides();
      myOfferedRides.value = ridesData.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading my offered rides: $e');
    }
  }

  Future<void> loadMyJoinedRides() async {
    try {
      final ridesData = await apiService.getMyJoinedRides();
      myJoinedRides.value = ridesData.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading my joined rides: $e');
    }
  }

  Future<void> loadPendingRequests() async {
    try {
      final requestsData = await apiService.getPendingRequestsForMyRides();
      pendingRequests.value = requestsData.map((json) => RideRequest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }
  }

  Future<List<Ride>> searchRides({
    String? pickup,
    String? dropoff,
    String? date,
    String? departureTime,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    int? timeFlexibility,
  }) async {
    try {
      isLoading.value = true;
      
      final ridesData = await apiService.searchRides(
        pickup: pickup,
        dropoff: dropoff,
        date: date,
        departureTime: departureTime,
        lat: pickupLocation?.latitude,
        lng: pickupLocation?.longitude,
        destLat: dropoffLocation?.latitude,
        destLng: dropoffLocation?.longitude,
        timeFlexibility: timeFlexibility,
      );
      
      return ridesData.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      error.value = 'Error searching rides: $e';
      debugPrint('Error searching rides: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createRide({
    required String pickupLocation,
    required LatLng pickupCoordinates,
    required String dropoffLocation,
    required LatLng dropoffCoordinates,
    required DateTime departureTime,
    required int totalSeats,
    required String genderPreference,
    String? notes,
    String? routeDescription,
    double? pricePerSeat,
  }) async {
    try {
      isCreatingRide.value = true;
      
      final rideData = {
        'pickup_location': pickupLocation,
        'pickup_latitude': pickupCoordinates.latitude,
        'pickup_longitude': pickupCoordinates.longitude,
        'dropoff_location': dropoffLocation,
        'dropoff_latitude': dropoffCoordinates.latitude,
        'dropoff_longitude': dropoffCoordinates.longitude,
        'departure_time': departureTime.toIso8601String(),
        'total_seats': totalSeats,
        'gender_preference': genderPreference,
        if (notes != null) 'notes': notes,
        if (routeDescription != null) 'route_description': routeDescription,
        if (pricePerSeat != null) 'price_per_seat': pricePerSeat,
      };
      
      final result = await apiService.createRide(rideData);
      
      // Add to my offered rides
      final newRide = Ride.fromJson(result);
      myOfferedRides.insert(0, newRide);
      
      Get.snackbar(
        'Success',
        'Ride created successfully!',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      error.value = 'Error creating ride: $e';
      Get.snackbar(
        'Error',
        'Error creating ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isCreatingRide.value = false;
    }
  }

  Future<bool> joinRide(int rideId, {String? pickupNote}) async {
    try {
      await apiService.joinRide(rideId, pickupNote: pickupNote);
      
      // Refresh available rides
      await loadAvailableRides();
      
      Get.snackbar(
        'Success',
        'Ride join request sent!',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error joining ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  Future<bool> leaveRide(int rideId) async {
    try {
      await apiService.leaveRide(rideId);
      
      // Refresh joined rides
      await loadMyJoinedRides();
      
      Get.snackbar(
        'Success',
        'You left the ride',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error leaving ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  Future<bool> managePassengerRequest(int rideId, int passengerId, bool approve) async {
    try {
      final action = approve ? 'confirm' : 'reject';
      await apiService.managePassenger(rideId, passengerId, action);
      
      // Refresh pending requests and offered rides
      await Future.wait([
        loadPendingRequests(),
        loadMyOfferedRides(),
      ]);
      
      final message = approve 
          ? 'Passenger request approved'
          : 'Passenger request rejected';
      
      Get.snackbar(
        'Success',
        message,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error approving/rejecting request: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  Future<FareBreakdown?> calculateFare({
    required LatLng pickup,
    required LatLng dropoff,
    required int seats,
    DateTime? departureTime,
  }) async {
    try {
      return await FareCalculationService.instance.calculateFareAPI(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        seats: seats,
        departureTime: departureTime,
      );
    } catch (e) {
      debugPrint('Error calculating fare: $e');
      return null;
    }
  }

  Future<bool> rateRide(int rideId, int rating, {String? comment}) async {
    try {
      await apiService.rateRide(rideId, rating, comment: comment);
      
      Get.snackbar(
        'کامیابی', // Success
        'آپ کی ریٹنگ محفوظ ہو گئی', // Your rating has been saved
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'خرابی', // Error
        'ریٹنگ میں خرابی: $e', // Error in rating
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchAreas(String query) async {
    try {
      final results = await apiService.searchAreas(query);
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('Error searching areas: $e');
      return [];
    }
  }

  Future<bool> startRide(int rideId) async {
    try {
      await apiService.startRide(rideId);
      await loadMyOfferedRides();
      
      Get.snackbar(
        'Success',
        'Ride started!',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error starting ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  Future<bool> completeRide(int rideId) async {
    try {
      await apiService.completeRide(rideId);
      await loadMyOfferedRides();
      
      Get.snackbar(
        'Success',
        'Ride completed!',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error completing ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  Future<bool> cancelRide(int rideId) async {
    try {
      await apiService.cancelRide(rideId);
      await loadMyOfferedRides();
      
      Get.snackbar(
        'Success',
        'Ride cancelled',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error cancelling ride: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  void clearError() {
    error.value = '';
  }
}

// Global instance
final ridesController = Get.put(RidesController());
