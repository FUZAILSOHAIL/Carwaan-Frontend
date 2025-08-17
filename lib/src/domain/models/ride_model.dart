import 'package:carwaan/src/domain/models/user_model.dart';

class RoutePoint {
  final double latitude;
  final double longitude;
  final int sequence;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: json['latitude'],
      longitude: json['longitude'],
      sequence: json['sequence'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude, 'sequence': sequence};
  }
}

class Stop {
  final int id;
  final String locationName;
  final String address;
  final double latitude;
  final double longitude;
  final int sequence;
  final DateTime? scheduledTime;

  Stop({
    required this.id,
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.sequence,
    this.scheduledTime,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      locationName: json['location_name'],
      address: json['address'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      sequence: json['sequence'],
      scheduledTime:
          json['scheduled_time'] != null
              ? DateTime.parse(json['scheduled_time'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_name': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
      'scheduled_time': scheduledTime?.toIso8601String(),
    };
  }
}

class RideStop extends Stop {
  RideStop({
    required super.id,
    required super.locationName,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.sequence,
    super.scheduledTime,
  });

  factory RideStop.fromJson(Map<String, dynamic> json) {
    return RideStop(
      id: json['id'],
      locationName: json['location_name'],
      address: json['address'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      sequence: json['sequence'],
      scheduledTime:
          json['scheduled_time'] != null
              ? DateTime.parse(json['scheduled_time'])
              : null,
    );
  }
}

class RidePassenger {
  final int id;
  final int passenger;
  final int ride;
  final String passengerName;
  final String? passengerPicture;
  final String passengerGender;
  final double passengerRating;
  final String status; // e.g., 'confirmed', 'pending', 'cancelled'
  final DateTime createdAt;

  RidePassenger({
    required this.id,
    required this.passenger,
    required this.ride,
    required this.passengerName,
    this.passengerPicture,
    required this.passengerGender,
    required this.passengerRating,
    required this.status,
    required this.createdAt,
  });

  factory RidePassenger.fromJson(Map<String, dynamic> json) {
    return RidePassenger(
      id: json['id'],
      passenger: json['passenger'],
      ride: json['ride'],
      passengerName: json['passenger_name'],
      passengerPicture: json['passenger_picture'],
      passengerGender: json['passenger_gender'] ?? 'prefer_not_to_say',
      passengerRating: (json['passenger_rating'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger': passenger,
      'ride': ride,
      'passenger_name': passengerName,
      'passenger_picture': passengerPicture,
      'passenger_gender': passengerGender,
      'passenger_rating': passengerRating,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Ride {
  final int id;
  final User driver;
  final double driverRating;
  final DateTime departureTime;
  final String pickupLocation;
  final String dropoffLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final int totalSeats;
  final int availableSeats;
  final String availableSeatsDisplay;
  final String notes;
  final bool recurring;
  final List<String>? recurringDays;
  final String genderPreference;
  final bool hasStops;
  final List<RideStop> stops;
  final List<RoutePoint> routePoints;
  final List<RidePassenger> passengers;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final String
  status; // e.g., 'scheduled', 'in_progress', 'completed', 'cancelled'
  final int timeFlexibilityMinutes;
  final bool isWorkplaceRide;
  final Map<String, dynamic>? comfortFeatures;
  final double averageRating;
  final int currentMalePassengers;
  final int currentFemalePassengers;
  final bool isFull;
  final double pricePerSeat;

  Ride({
    required this.id,
    required this.driver,
    required this.driverRating,
    required this.departureTime,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.totalSeats,
    required this.availableSeats,
    required this.availableSeatsDisplay,
    this.notes = '',
    required this.recurring,
    this.recurringDays,
    required this.genderPreference,
    required this.hasStops,
    required this.stops,
    required this.routePoints,
    required this.passengers,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.status,
    required this.timeFlexibilityMinutes,
    required this.isWorkplaceRide,
    this.comfortFeatures,
    required this.averageRating,
    required this.currentMalePassengers,
    required this.currentFemalePassengers,
    required this.isFull,
    required this.pricePerSeat,
  });

  // Helper methods
  bool isUserEligible(User user) {
    if (genderPreference == 'any') return true;
    if (genderPreference == 'male_only' && user.gender == 'male') return true;
    if (genderPreference == 'female_only' && user.gender == 'female') {
      return true;
    }
    if (genderPreference == 'family_only') {
      return true; // May need additional logic
    }
    return false;
  }

  String getGenderPreferenceDisplay() {
    switch (genderPreference) {
      case 'male_only':
        return 'Male passengers only';
      case 'female_only':
        return 'Female passengers only';
      case 'family_only':
        return 'Families only';
      case 'any':
      default:
        return 'Any gender welcome';
    }
  }

  String getPassengerGenderInfo() {
    return 'M: $currentMalePassengers, F: $currentFemalePassengers';
  }

  // Factories
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      driver: User.fromJson(json['driver']),
      driverRating: (json['driver_rating'] ?? 0).toDouble(),
      departureTime: DateTime.parse(json['departure_time']),
      pickupLocation: json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      pickupLatitude: json['pickup_latitude'],
      pickupLongitude: json['pickup_longitude'],
      dropoffLatitude: json['dropoff_latitude'],
      dropoffLongitude: json['dropoff_longitude'],
      totalSeats: json['total_seats'],
      availableSeats: json['available_seats'],
      availableSeatsDisplay:
          json['available_seats_display'] ?? 
          "${json['available_seats']} seats available",
      notes: json['notes'] ?? '',
      recurring: json['recurring'] ?? false,
      recurringDays:
          json['recurring_days'] != null
              ? List<String>.from(json['recurring_days'])
              : null,
      genderPreference: json['gender_preference'] ?? 'any',
      hasStops: json['has_stops'] ?? false,
      stops:
          json['stops'] != null
              ? (json['stops'] as List)
                  .map((stop) => RideStop.fromJson(stop))
                  .toList()
              : [],
      routePoints:
          json['route_points'] != null
              ? (json['route_points'] as List)
                  .map((point) => RoutePoint.fromJson(point))
                  .toList()
              : [],
      passengers:
          json['passengers'] != null
              ? (json['passengers'] as List)
                  .map((passenger) => RidePassenger.fromJson(passenger))
                  .toList()
              : [],
      estimatedDistanceKm: json['estimated_distance_km']?.toDouble() ?? 0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] ?? 0,
      status: json['status'] ?? 'scheduled',
      timeFlexibilityMinutes: json['time_flexibility_minutes'] ?? 0,
      isWorkplaceRide: json['is_workplace_ride'] ?? false,
      comfortFeatures: json['comfort_features'],
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      currentMalePassengers: json['current_male_passengers'] ?? 0,
      currentFemalePassengers: json['current_female_passengers'] ?? 0,
      isFull: json['is_full'] ?? false,
      pricePerSeat: (json['price_per_seat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver': driver.toJson(),
      'driver_rating': driverRating,
      'departure_time': departureTime.toIso8601String(),
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'dropoff_latitude': dropoffLatitude,
      'dropoff_longitude': dropoffLongitude,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'available_seats_display': availableSeatsDisplay,
      'notes': notes,
      'recurring': recurring,
      'recurring_days': recurringDays,
      'gender_preference': genderPreference,
      'has_stops': hasStops,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'route_points': routePoints.map((point) => point.toJson()).toList(),
      'passengers': passengers.map((passenger) => passenger.toJson()).toList(),
      'estimated_distance_km': estimatedDistanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'status': status,
      'time_flexibility_minutes': timeFlexibilityMinutes,
      'is_workplace_ride': isWorkplaceRide,
      'comfort_features': comfortFeatures,
      'average_rating': averageRating,
      'current_male_passengers': currentMalePassengers,
      'current_female_passengers': currentFemalePassengers,
      'is_full': isFull,
      'price_per_seat': pricePerSeat,
    };
  }
}
