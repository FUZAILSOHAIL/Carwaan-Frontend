import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api_service.dart';

class RidesDataService {
  static final RidesDataService _instance = RidesDataService._internal();
  factory RidesDataService() => _instance;
  RidesDataService._internal();

  // Get API service instance
  ApiService get _apiService => Get.find<ApiService>();

  // Mock ride data with comprehensive information
  static final List<Map<String, dynamic>> _mockRides = [
    {
      'id': '1',
      'driver_id': '101',
      'driver_name': 'Ahmed Ali',
      'driver_phone': '+92-300-1234567',
      'driver_rating': 4.8,
      'driver_total_rides': 156,
      'created_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
      'vehicle_info': {
        'make': 'Toyota',
        'model': 'Corolla',
        'year': 2020,
        'color': 'White',
        'license_plate': 'KHI-1234',
      },
      'pickup_location': 'DHA Phase 5, Karachi',
      'pickup_latitude': 24.8243,
      'pickup_longitude': 67.0633,
      'dropoff_location': 'Clifton Block 2, Karachi',
      'dropoff_latitude': 24.8138,
      'dropoff_longitude': 67.0299,
      'departure_time': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
      'estimated_duration': 35, // minutes
      'distance_km': 12.5,
      'total_seats': 4,
      'occupied_seats': 2,
      'available_seats': 2,
      'fare_per_seat': 200,
      'route_preference': 'fastest',
      'gender_preference': 'mixed',
      'status': 'available',
      'is_recurring': false,
      'amenities': ['AC', 'Music', 'Phone Charging'],
      'notes': 'Comfortable ride with AC. Pickup from main gate.',
      'passengers': [
        {
          'id': '201',
          'name': 'Sara Khan',
          'rating': 4.6,
          'seats_booked': 1,
        },
        {
          'id': '202',
          'name': 'Hassan Ahmed',
          'rating': 4.9,
          'seats_booked': 1,
        },
      ],
      'direction': 'south', // north, south, east, west, northeast, northwest, southeast, southwest
    },
    {
      'id': '2',
      'driver_id': '102',
      'driver_name': 'Maria Khan',
      'driver_phone': '+92-321-7654321',
      'driver_rating': 4.9,
      'driver_total_rides': 89,
      'vehicle_info': {
        'make': 'Honda',
        'model': 'Civic',
        'year': 2019,
        'color': 'Silver',
        'license_plate': 'KHI-5678',
      },
      'pickup_location': 'Gulshan-e-Iqbal Block 13A, Karachi',
      'pickup_latitude': 24.9183,
      'pickup_longitude': 67.1078,
      'dropoff_location': 'Saddar Town, Karachi',
      'dropoff_latitude': 24.8607,
      'dropoff_longitude': 67.0011,
      'departure_time': DateTime.now().add(Duration(hours: 1, minutes: 30)).toIso8601String(),
      'estimated_duration': 45,
      'distance_km': 18.2,
      'total_seats': 3,
      'occupied_seats': 1,
      'available_seats': 2,
      'fare_per_seat': 250,
      'route_preference': 'shortest',
      'gender_preference': 'female_only',
      'female_only_ride': true,
      'status': 'available',
      'is_recurring': true,
      'recurring_days': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      'amenities': ['AC', 'Ladies Only', 'Non-Smoking'],
      'notes': 'Ladies only ride. Daily commute to office area.',
      'passengers': [
        {
          'id': '203',
          'name': 'Ayesha Malik',
          'rating': 4.7,
          'seats_booked': 1,
        },
      ],
      'direction': 'southwest',
    },
    {
      'id': '3',
      'driver_id': '103',
      'driver_name': 'Usman Tariq',
      'driver_phone': '+92-333-9876543',
      'driver_rating': 4.6,
      'driver_total_rides': 234,
      'vehicle_info': {
        'make': 'Suzuki',
        'model': 'Alto',
        'year': 2018,
        'color': 'Red',
        'license_plate': 'KHI-9876',
      },
      'pickup_location': 'Nazimabad Block 4, Karachi',
      'pickup_latitude': 24.9341,
      'pickup_longitude': 67.0369,
      'dropoff_location': 'Korangi Industrial Area, Karachi',
      'dropoff_latitude': 24.8546,
      'dropoff_longitude': 67.1578,
      'departure_time': DateTime.now().add(Duration(minutes: 45)).toIso8601String(),
      'estimated_duration': 55,
      'distance_km': 22.1,
      'total_seats': 3,
      'occupied_seats': 3,
      'available_seats': 0,
      'fare_per_seat': 180,
      'route_preference': 'balanced',
      'gender_preference': 'mixed',
      'status': 'full',
      'is_recurring': true,
      'recurring_days': ['monday', 'wednesday', 'friday'],
      'amenities': ['Affordable', 'Reliable'],
      'notes': 'Budget-friendly ride. Please be on time.',
      'passengers': [
        {
          'id': '204',
          'name': 'Ali Raza',
          'rating': 4.4,
          'seats_booked': 1,
        },
        {
          'id': '205',
          'name': 'Fatima Sheikh',
          'rating': 4.8,
          'seats_booked': 1,
        },
        {
          'id': '206',
          'name': 'Zain Malik',
          'rating': 4.5,
          'seats_booked': 1,
        },
      ],
      'direction': 'east',
    },
    {
      'id': '4',
      'driver_id': '104',
      'driver_name': 'Farah Siddiqui',
      'driver_phone': '+92-345-1112223',
      'driver_rating': 4.7,
      'driver_total_rides': 67,
      'vehicle_info': {
        'make': 'Toyota',
        'model': 'Vitz',
        'year': 2021,
        'color': 'Blue',
        'license_plate': 'KHI-4321',
      },
      'pickup_location': 'Malir Cantonment, Karachi',
      'pickup_latitude': 24.9454,
      'pickup_longitude': 67.2095,
      'dropoff_location': 'University of Karachi, Karachi',
      'dropoff_latitude': 24.9454,
      'dropoff_longitude': 67.1300,
      'departure_time': DateTime.now().add(Duration(hours: 3)).toIso8601String(),
      'estimated_duration': 30,
      'distance_km': 8.7,
      'total_seats': 4,
      'occupied_seats': 1,
      'available_seats': 3,
      'fare_per_seat': 150,
      'route_preference': 'fastest',
      'gender_preference': 'mixed',
      'status': 'available',
      'is_recurring': false,
      'amenities': ['AC', 'Student Friendly', 'Music'],
      'notes': 'Student friendly rates. Going to university area.',
      'passengers': [
        {
          'id': '207',
          'name': 'Bilal Khan',
          'rating': 4.3,
          'seats_booked': 1,
        },
      ],
      'direction': 'west',
    },
    {
      'id': '5',
      'driver_id': '105',
      'driver_name': 'Kashif Mahmood',
      'driver_phone': '+92-300-5556667',
      'driver_rating': 4.5,
      'driver_total_rides': 145,
      'vehicle_info': {
        'make': 'Honda',
        'model': 'City',
        'year': 2017,
        'color': 'Black',
        'license_plate': 'KHI-7890',
      },
      'pickup_location': 'Bahadurabad, Karachi',
      'pickup_latitude': 24.8754,
      'pickup_longitude': 67.0775,
      'dropoff_location': 'Port Qasim, Karachi',
      'dropoff_latitude': 24.7596,
      'dropoff_longitude': 67.3635,
      'departure_time': DateTime.now().add(Duration(hours: 4, minutes: 15)).toIso8601String(),
      'estimated_duration': 70,
      'distance_km': 35.4,
      'total_seats': 4,
      'occupied_seats': 0,
      'available_seats': 4,
      'fare_per_seat': 350,
      'route_preference': 'balanced',
      'gender_preference': 'mixed',
      'status': 'available',
      'is_recurring': true,
      'recurring_days': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      'amenities': ['AC', 'Long Distance', 'Comfortable'],
      'notes': 'Daily office commute to Port Qasim area.',
      'passengers': [],
      'direction': 'southeast',
    },
  ];

  // Get all available rides
  List<Map<String, dynamic>> getAvailableRides() {
    return _mockRides.where((ride) => 
      ride['status'] == 'available' && 
      ride['available_seats'] > 0
    ).toList();
  }

  // Get rides based on direction matching
  List<Map<String, dynamic>> getRidesByDirection(String userDirection, [String? userPickupArea]) {
    final availableRides = getAvailableRides();
    
    return availableRides.where((ride) {
      // Basic direction matching
      final rideDirection = ride['direction'] as String;
      
      // Exact match
      if (rideDirection == userDirection) return true;
      
      // Similar direction matching (e.g., north matches northeast/northwest)
      if (userDirection == 'north' && 
          (rideDirection == 'northeast' || rideDirection == 'northwest')) {
        return true;
      }
      if (userDirection == 'south' && 
          (rideDirection == 'southeast' || rideDirection == 'southwest')) {
        return true;
      }
      if (userDirection == 'east' && 
          (rideDirection == 'northeast' || rideDirection == 'southeast')) {
        return true;
      }
      if (userDirection == 'west' && 
          (rideDirection == 'northwest' || rideDirection == 'southwest')) {
        return true;
      }
      
      return false;
    }).toList();
  }

  // Get ride details by ID
  Map<String, dynamic>? getRideById(String rideId) {
    try {
      return _mockRides.firstWhere((ride) => ride['id'] == rideId);
    } catch (e) {
      return null;
    }
  }

  // Book a seat in a ride
  bool bookSeat(String rideId, Map<String, dynamic> passengerInfo, int seatsToBook) {
    final rideIndex = _mockRides.indexWhere((ride) => ride['id'] == rideId);
    if (rideIndex == -1) return false;

    final ride = _mockRides[rideIndex];
    if (ride['available_seats'] < seatsToBook) return false;

    // Add passenger to the ride
    final passengers = List<Map<String, dynamic>>.from(ride['passengers'] ?? []);
    passengers.add({
      'id': passengerInfo['id'],
      'name': passengerInfo['name'],
      'rating': passengerInfo['rating'] ?? 4.0,
      'seats_booked': seatsToBook,
    });

    // Update ride information
    _mockRides[rideIndex] = {
      ...ride,
      'passengers': passengers,
      'occupied_seats': ride['occupied_seats'] + seatsToBook,
      'available_seats': ride['available_seats'] - seatsToBook,
      'status': ride['available_seats'] - seatsToBook <= 0 ? 'full' : 'available',
    };

    return true;
  }

  // Add a new ride
  String addRide(Map<String, dynamic> rideData) {
    final newId = (int.parse(_mockRides.last['id']) + 1).toString();
    final now = DateTime.now();
    final newRide = {
      'id': newId,
      'driver_id': '101', // Current user as driver  
      'driver_name': 'You',
      'driver_phone': '+92-300-0000000',
      'driver_rating': 4.5,
      'driver_total_rides': 0,
      'created_at': now.toIso8601String(), // Add creation timestamp
      'vehicle_info': rideData['vehicle_info'] ?? {
        'make': 'Unknown',
        'model': 'Vehicle', 
        'year': 2020,
        'color': 'Unknown',
        'license_plate': 'XXX-0000',
      },
      'pickup_location': rideData['pickup_location'] ?? 'Unknown Pickup',
      'pickup_latitude': rideData['pickup_latitude'] ?? 0.0,
      'pickup_longitude': rideData['pickup_longitude'] ?? 0.0,
      'dropoff_location': rideData['dropoff_location'] ?? 'Unknown Destination', 
      'dropoff_latitude': rideData['dropoff_latitude'] ?? 0.0,
      'dropoff_longitude': rideData['dropoff_longitude'] ?? 0.0,
      'departure_time': rideData['departure_time'],
      'estimated_duration': rideData['estimated_duration'] ?? 30,
      'distance_km': rideData['estimated_distance_km'] ?? 0.0,
      'total_seats': rideData['available_seats'] ?? 4,
      'occupied_seats': 0,
      'available_seats': rideData['available_seats'] ?? 4,
      'fare_per_seat': rideData['fare_per_seat'] ?? 0,
      'route_preference': rideData['route_preference'] ?? 'fastest',
      'gender_preference': rideData['female_only_ride'] == true ? 'female_only' : 'mixed',
      'status': 'available',
      'is_recurring': false,
      'amenities': ['AC'],
      'notes': rideData['description'] ?? '',
      'passengers': [],
    };
    _mockRides.insert(0, newRide); // Insert at beginning for most recent first
    
    // Debug print to verify ride is added
    debugPrint('✅ Added new ride with ID: $newId');
    debugPrint('📍 Pickup: ${newRide['pickup_location']} (${newRide['pickup_latitude']}, ${newRide['pickup_longitude']})');
    debugPrint('🎯 Dropoff: ${newRide['dropoff_location']} (${newRide['dropoff_latitude']}, ${newRide['dropoff_longitude']})');
    debugPrint('🚗 Total rides in service: ${_mockRides.length}');
    debugPrint('🎯 Offered rides count: ${getOfferedRides().length}');
    
    return newId;
  }

  // Calculate direction between two points
  static String calculateDirection(double fromLat, double fromLng, double toLat, double toLng) {
    final latDiff = toLat - fromLat;
    final lngDiff = toLng - fromLng;
    
    // Calculate angle in degrees
    final angle = (atan2(lngDiff, latDiff) * 180 / pi + 360) % 360;
    
    // Map angle to direction
    if (angle >= 337.5 || angle < 22.5) return 'north';
    if (angle >= 22.5 && angle < 67.5) return 'northeast';
    if (angle >= 67.5 && angle < 112.5) return 'east';
    if (angle >= 112.5 && angle < 157.5) return 'southeast';
    if (angle >= 157.5 && angle < 202.5) return 'south';
    if (angle >= 202.5 && angle < 247.5) return 'southwest';
    if (angle >= 247.5 && angle < 292.5) return 'west';
    if (angle >= 292.5 && angle < 337.5) return 'northwest';
    
    return 'unknown';
  }
  
  // Get direction icon
  static String getDirectionIcon(String direction) {
    switch (direction.toLowerCase()) {
      case 'north': return '⬆️';
      case 'northeast': return '↗️';
      case 'east': return '➡️';
      case 'southeast': return '↘️';
      case 'south': return '⬇️';
      case 'southwest': return '↙️';
      case 'west': return '⬅️';
      case 'northwest': return '↖️';
      default: return '🧭';
    }
  }

  // Get random ride for testing
  Map<String, dynamic> getRandomRide() {
    final availableRides = getAvailableRides();
    if (availableRides.isEmpty) return {};
    return availableRides[Random().nextInt(availableRides.length)];
  }

  // Get current rides (upcoming and ongoing rides for the current user)
  List<Map<String, dynamic>> getCurrentRides() {
    final currentUserId = '202'; // Mock current user ID
    final now = DateTime.now();
    
    return _mockRides.where((ride) {
      // Check if user is a passenger in this ride
      final passengers = List.from(ride['passengers'] ?? []);
      final isPassenger = passengers.any((p) => p['id'] == currentUserId);
      
      // Check if ride is upcoming (departure time in future)
      final departureTime = DateTime.tryParse(ride['departure_time'] ?? '');
      final isUpcoming = departureTime != null && departureTime.isAfter(now);
      
      return isPassenger && isUpcoming && ride['status'] != 'completed';
    }).toList();
  }

  // Get past rides (completed rides for the current user)
  List<Map<String, dynamic>> getPastRides() {
    final currentUserId = '202'; // Mock current user ID
    final now = DateTime.now();
    
    return _mockRides.where((ride) {
      // Check if user was a passenger in this ride
      final passengers = List.from(ride['passengers'] ?? []);
      final isPassenger = passengers.any((p) => p['id'] == currentUserId);
      
      // Check if ride is completed or in the past
      final departureTime = DateTime.tryParse(ride['departure_time'] ?? '');
      final isCompleted = ride['status'] == 'completed' || 
                         (departureTime != null && departureTime.isBefore(now));
      
      return isPassenger && isCompleted;
    }).toList();
  }

  // Get offered rides (rides created/offered by the current user)
  List<Map<String, dynamic>> getOfferedRides() {
    final currentUserId = '101'; // Mock current user ID (as driver)
    
    final offeredRides = _mockRides.where((ride) {
      return ride['driver_id'] == currentUserId;
    }).toList();
    
    // Sort by creation date (newest first)
    offeredRides.sort((a, b) {
      final aCreated = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final bCreated = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return bCreated.compareTo(aCreated); // Descending order (newest first)
    });
    
    // Debug print
    debugPrint('🎯 Getting offered rides for user: $currentUserId');
    debugPrint('📊 Total rides in service: ${_mockRides.length}');
    debugPrint('🚗 Offered rides found: ${offeredRides.length}');
    if (offeredRides.isNotEmpty) {
      debugPrint('📋 Offered ride IDs: ${offeredRides.map((r) => r['id']).join(', ')}');
    }
    
    return offeredRides;
  }

  // Delete a ride (only allowed if user is the driver and ride hasn't started)
  bool deleteRide(String rideId) {
    final rideIndex = _mockRides.indexWhere((ride) => ride['id'] == rideId);
    if (rideIndex == -1) return false;

    final ride = _mockRides[rideIndex];
    
    // Check if current user is the driver
    if (ride['driver_id'] != '101') {
      debugPrint('❌ Cannot delete ride: User is not the driver');
      return false;
    }
    
    // Check if ride hasn't started yet
    final departureTime = DateTime.tryParse(ride['departure_time'] ?? '');
    final now = DateTime.now();
    
    if (departureTime != null && departureTime.isBefore(now)) {
      debugPrint('❌ Cannot delete ride: Ride has already started or passed');
      return false;
    }
    
    // Remove the ride
    _mockRides.removeAt(rideIndex);
    debugPrint('✅ Deleted ride with ID: $rideId');
    
    return true;
  }

  // Refresh offered rides after creating a new ride
  void refreshOfferedRides() {
    // This method can be used to trigger UI refresh
    // The actual refresh happens when getOfferedRides() is called
  }

  // ==================== API-BASED METHODS ====================
  
  /// Get user's rides from backend API (current, past, offered)
  Future<Map<String, List<Map<String, dynamic>>>> getMyRidesFromAPI() async {
    try {
      debugPrint('🌐 Fetching user rides from API...');
      final response = await _apiService.get('/rides/my_rides/');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        final currentRides = List<Map<String, dynamic>>.from(data['current_rides'] ?? []);
        final pastRides = List<Map<String, dynamic>>.from(data['past_rides'] ?? []);
        final offeredRides = List<Map<String, dynamic>>.from(data['offered_rides'] ?? []);
        
        debugPrint('✅ API rides fetched - Current: ${currentRides.length}, Past: ${pastRides.length}, Offered: ${offeredRides.length}');
        
        return {
          'current_rides': currentRides,
          'past_rides': pastRides,
          'offered_rides': offeredRides,
        };
      } else {
        debugPrint('❌ API error: ${response.statusCode}');
        return _getFallbackRides();
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch rides from API: $e');
      return _getFallbackRides();
    }
  }

  /// Join a ride via API
  Future<bool> joinRideAPI(String rideId, int seatsToBook) async {
    try {
      debugPrint('🌐 Joining ride $rideId with $seatsToBook seats via API...');
      
      final response = await _apiService.post('/rides/$rideId/join/', data: {
        'seats_requested': seatsToBook,
        'message': 'Joining ride via app',
      });
      
      if (response.statusCode == 201) {
        debugPrint('✅ Successfully joined ride $rideId');
        return true;
      } else {
        debugPrint('❌ Failed to join ride: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error joining ride: $e');
      return false;
    }
  }

  /// Delete an offered ride via API
  Future<bool> deleteOfferedRideAPI(String rideId) async {
    try {
      debugPrint('🌐 Deleting offered ride $rideId via API...');
      
      final response = await _apiService.delete('/rides/$rideId/delete_offered_ride/');
      
      if (response.statusCode == 200) {
        debugPrint('✅ Successfully deleted ride $rideId');
        return true;
      } else {
        debugPrint('❌ Failed to delete ride: ${response.statusCode} - ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting ride: $e');
      return false;
    }
  }

  /// Create a new ride via API
  Future<String?> createRideAPI(Map<String, dynamic> rideData) async {
    try {
      debugPrint('🌐 Creating ride via API...');
      
      final response = await _apiService.post('/rides/', data: rideData);
      
      if (response.statusCode == 201) {
        final createdRide = response.data as Map<String, dynamic>;
        final rideId = createdRide['id'].toString();
        debugPrint('✅ Successfully created ride with ID: $rideId');
        return rideId;
      } else {
        debugPrint('❌ Failed to create ride: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating ride: $e');
      return null;
    }
  }

  /// Search for rides using passenger search endpoint
  Future<Map<String, dynamic>> searchRidesForPassenger({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required DateTime departureTime,
    bool femaleOnly = false,
  }) async {
    try {
      debugPrint('🌐 Searching rides for passenger via API...');
      
      final requestData = {
        'pickup_latitude': pickupLat,
        'pickup_longitude': pickupLng,
        'dropoff_latitude': dropoffLat,
        'dropoff_longitude': dropoffLng,
        'departure_time': departureTime.toIso8601String(),
        'female_only': femaleOnly,
      };
      
      final response = await _apiService.post('/rides/passenger-search/search_rides/', data: requestData);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final rides = List<Map<String, dynamic>>.from(data['rides'] ?? []);
        final isFallback = data['is_fallback'] ?? false;
        final message = data['message'] ?? '';
        
        debugPrint('✅ Found ${rides.length} rides via passenger search API');
        if (isFallback) {
          debugPrint('🔄 Showing fallback results: $message');
        }
        
        return {
          'success': true,
          'rides': rides,
          'is_fallback': isFallback,
          'message': message,
          'total_found': data['total_found'] ?? rides.length,
        };
      } else {
        debugPrint('❌ Failed to search rides: ${response.statusCode}');
        return await _getFallbackPassengerSearch(femaleOnly: femaleOnly);
      }
    } catch (e) {
      debugPrint('❌ Error searching rides: $e');
      return await _getFallbackPassengerSearch(femaleOnly: femaleOnly);
    }
  }

  /// Fallback method for passenger search when API fails
  Future<Map<String, dynamic>> _getFallbackPassengerSearch({bool femaleOnly = false}) async {
    debugPrint('🔄 Using fallback data for passenger search');
    
    // Get available rides from mock data
    var availableRides = getAvailableRides();
    
    // Apply female-only filter if requested
    if (femaleOnly) {
      availableRides = availableRides.where((ride) {
        return ride['gender_preference'] == 'female_only' ||
               ride['female_only_ride'] == true;
      }).toList();
    }
    
    return {
      'success': true,
      'rides': availableRides,
      'is_fallback': true,
      'message': 'No matching rides found. Showing all available rides.',
      'total_found': availableRides.length,
    };
  }

  /// Get available rides from API with female-only filter support
  Future<List<Map<String, dynamic>>> getAvailableRidesFromAPI({bool? femaleOnly}) async {
    try {
      debugPrint('🌐 Fetching available rides from API...');
      
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (femaleOnly == true) {
        queryParams['female_only'] = 'true';
      }
      
      final response = await _apiService.get('/rides/available_rides/', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final rides = List<Map<String, dynamic>>.from(response.data);
        debugPrint('✅ Fetched ${rides.length} available rides from API');
        if (femaleOnly == true) {
          debugPrint('🚺 Filtered for female-only rides');
        }
        return rides;
      } else {
        debugPrint('❌ Failed to fetch available rides: ${response.statusCode}');
        return _getFallbackAvailableRides(femaleOnly: femaleOnly); // Fallback to mock data with filter
      }
    } catch (e) {
      debugPrint('❌ Error fetching available rides: $e');
      return _getFallbackAvailableRides(femaleOnly: femaleOnly); // Fallback to mock data with filter
    }
  }

  /// Fallback method for available rides when API fails
  List<Map<String, dynamic>> _getFallbackAvailableRides({bool? femaleOnly}) {
    debugPrint('🔄 Using fallback available rides data');
    
    // Get available rides from mock data
    var availableRides = getAvailableRides();
    
    // Apply female-only filter if requested
    if (femaleOnly == true) {
      availableRides = availableRides.where((ride) {
        return ride['gender_preference'] == 'female_only' ||
               ride['female_only_ride'] == true;
      }).toList();
      debugPrint('🚺 Filtered ${availableRides.length} female-only rides from fallback data');
    }
    
    return availableRides;
  }

  /// Fallback method when API is not available
  Map<String, List<Map<String, dynamic>>> _getFallbackRides() {
    debugPrint('🔄 Using fallback mock data for rides');
    return {
      'current_rides': getCurrentRides(),
      'past_rides': getPastRides(),
      'offered_rides': getOfferedRides(),
    };
  }

  /// Hybrid method that tries API first, then falls back to mock data
  Future<List<Map<String, dynamic>>> getCurrentRidesHybrid() async {
    try {
      final apiRides = await getMyRidesFromAPI();
      return apiRides['current_rides'] ?? [];
    } catch (e) {
      debugPrint('🔄 API failed, using mock current rides');
      return getCurrentRides();
    }
  }

  /// Hybrid method that tries API first, then falls back to mock data
  Future<List<Map<String, dynamic>>> getPastRidesHybrid() async {
    try {
      final apiRides = await getMyRidesFromAPI();
      return apiRides['past_rides'] ?? [];
    } catch (e) {
      debugPrint('🔄 API failed, using mock past rides');
      return getPastRides();
    }
  }

  /// Hybrid method that tries API first, then falls back to mock data
  Future<List<Map<String, dynamic>>> getOfferedRidesHybrid() async {
    try {
      final apiRides = await getMyRidesFromAPI();
      return apiRides['offered_rides'] ?? [];
    } catch (e) {
      debugPrint('🔄 API failed, using mock offered rides');
      return getOfferedRides();
    }
  }

  /// Enhanced booking method that tries API first
  Future<bool> bookSeatHybrid(String rideId, Map<String, dynamic> passengerInfo, int seatsToBook) async {
    try {
      // Try API first
      final success = await joinRideAPI(rideId, seatsToBook);
      if (success) return true;
      
      // Fallback to mock data
      debugPrint('🔄 API booking failed, using mock booking');
      return bookSeat(rideId, passengerInfo, seatsToBook);
    } catch (e) {
      debugPrint('❌ Hybrid booking error: $e');
      return bookSeat(rideId, passengerInfo, seatsToBook);
    }
  }

  /// Enhanced delete method that tries API first
  Future<bool> deleteRideHybrid(String rideId) async {
    try {
      // Try API first
      final success = await deleteOfferedRideAPI(rideId);
      if (success) return true;
      
      // Fallback to mock data
      debugPrint('🔄 API delete failed, using mock delete');
      return deleteRide(rideId);
    } catch (e) {
      debugPrint('❌ Hybrid delete error: $e');
      return deleteRide(rideId);
    }
  }
}
