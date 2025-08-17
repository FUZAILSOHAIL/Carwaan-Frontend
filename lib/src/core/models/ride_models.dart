import 'package:latlong2/latlong.dart';

class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? gender;
  final bool hasCar;
  final double averageRating;
  final int totalRatings;
  final String? profilePicture;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.gender,
    this.hasCar = false,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.profilePicture,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'] ?? json['username'],
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      hasCar: json['has_car'] ?? false,
      averageRating: _parseDouble(json['average_rating']) ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      profilePicture: json['profile_picture'],
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'])
          : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'has_car': hasCar,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'profile_picture': profilePicture,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Ride {
  final int id;
  final User driver;
  final String pickupLocation;
  final String dropoffLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final DateTime departureTime;
  final int totalSeats;
  final int availableSeats;
  final String status;
  final String genderPreference;
  final double estimatedDistanceKm;
  final bool isPeakHours;
  final double calculatedFarePerPerson;
  final double totalFare;
  final double baseFareRate;
  final int currentMalePassengers;
  final int currentFemalePassengers;
  final List<RidePassenger> passengers;
  final FareBreakdown? fareBreakdown;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final bool isScheduled;
  final DateTime? bookingDeadline;

  const Ride({
    required this.id,
    required this.driver,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.status,
    required this.genderPreference,
    required this.estimatedDistanceKm,
    this.isPeakHours = false,
    this.calculatedFarePerPerson = 0.0,
    this.totalFare = 0.0,
    this.baseFareRate = 30.0,
    this.currentMalePassengers = 0,
    this.currentFemalePassengers = 0,
    this.passengers = const [],
    this.fareBreakdown,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.isScheduled = false,
    this.bookingDeadline,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      driver: User.fromJson(json['driver']),
      pickupLocation: json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      pickupLatitude: json['pickup_latitude']?.toDouble(),
      pickupLongitude: json['pickup_longitude']?.toDouble(),
      dropoffLatitude: json['dropoff_latitude']?.toDouble(),
      dropoffLongitude: json['dropoff_longitude']?.toDouble(),
      departureTime: DateTime.parse(json['departure_time']),
      totalSeats: json['total_seats'],
      availableSeats: json['available_seats'],
      status: json['status'],
      genderPreference: json['gender_preference'],
      estimatedDistanceKm: json['estimated_distance_km']?.toDouble() ?? 0.0,
      isPeakHours: json['is_peak_hours'] ?? false,
      calculatedFarePerPerson: json['calculated_fare_per_person']?.toDouble() ?? 0.0,
      totalFare: json['total_fare']?.toDouble() ?? 0.0,
      baseFareRate: json['base_fare_rate']?.toDouble() ?? 30.0,
      currentMalePassengers: json['current_male_passengers'] ?? 0,
      currentFemalePassengers: json['current_female_passengers'] ?? 0,
      passengers: (json['passengers'] as List?)
          ?.map((p) => RidePassenger.fromJson(p))
          .toList() ?? [],
      fareBreakdown: json['fare_breakdown'] != null 
          ? FareBreakdown.fromJson(json['fare_breakdown'])
          : null,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
      notes: json['notes'],
      isScheduled: json['is_scheduled'] ?? false,
      bookingDeadline: json['booking_deadline'] != null 
          ? DateTime.parse(json['booking_deadline'])
          : null,
    );
  }

  bool get isActive => ['scheduled', 'started', 'in_progress'].contains(status);
  bool get canStart => status == 'scheduled';
  bool get canComplete => ['started', 'in_progress'].contains(status);
  bool get isFull => availableSeats <= 0;
  bool get isFemaleOnly => genderPreference == 'female_only';
  
  LatLng? get pickupLatLng => 
      pickupLatitude != null && pickupLongitude != null 
          ? LatLng(pickupLatitude!, pickupLongitude!)
          : null;
          
  LatLng? get dropoffLatLng => 
      dropoffLatitude != null && dropoffLongitude != null 
          ? LatLng(dropoffLatitude!, dropoffLongitude!)
          : null;

  int get confirmedPassengerCount => 
      passengers.where((p) => p.status == 'confirmed').length;

  String get statusDisplayText {
    switch (status) {
      case 'scheduled': return 'منظور شدہ'; // Scheduled
      case 'started': return 'شروع ہو گئی'; // Started
      case 'in_progress': return 'جاری ہے'; // In Progress
      case 'completed': return 'مکمل'; // Completed
      case 'cancelled': return 'منسوخ'; // Cancelled
      default: return status;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ride && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class RidePassenger {
  final int id;
  final User passenger;
  final String status;
  final double contributionAmount;
  final String? pickupNote;
  final DateTime? requestedAt;
  final DateTime? confirmedAt;

  const RidePassenger({
    required this.id,
    required this.passenger,
    required this.status,
    this.contributionAmount = 0.0,
    this.pickupNote,
    this.requestedAt,
    this.confirmedAt,
  });

  factory RidePassenger.fromJson(Map<String, dynamic> json) {
    return RidePassenger(
      id: json['id'],
      passenger: User.fromJson(json['passenger']),
      status: json['status'],
      contributionAmount: json['contribution_amount']?.toDouble() ?? 0.0,
      pickupNote: json['pickup_note'],
      requestedAt: json['requested_at'] != null 
          ? DateTime.parse(json['requested_at'])
          : null,
      confirmedAt: json['confirmed_at'] != null 
          ? DateTime.parse(json['confirmed_at'])
          : null,
    );
  }

  String get statusDisplayText {
    switch (status) {
      case 'pending': return 'انتظار میں'; // Pending
      case 'confirmed': return 'تصدیق شدہ'; // Confirmed
      case 'cancelled': return 'منسوخ'; // Cancelled
      case 'completed': return 'مکمل'; // Completed
      default: return status;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RidePassenger && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class FareBreakdown {
  final double baseFareRate;
  final double distanceKm;
  final double baseFare;
  final bool isPeakHours;
  final double peakMultiplier;
  final double totalFare;
  final int confirmedPassengers;
  final double farePerPerson;
  final double? estimatedFarePerPerson;

  const FareBreakdown({
    required this.baseFareRate,
    required this.distanceKm,
    required this.baseFare,
    required this.isPeakHours,
    required this.peakMultiplier,
    required this.totalFare,
    required this.confirmedPassengers,
    required this.farePerPerson,
    this.estimatedFarePerPerson,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    return FareBreakdown(
      baseFareRate: json['base_fare_rate']?.toDouble() ?? 30.0,
      distanceKm: json['distance_km']?.toDouble() ?? 0.0,
      baseFare: json['base_fare']?.toDouble() ?? 0.0,
      isPeakHours: json['is_peak_hours'] ?? false,
      peakMultiplier: json['peak_multiplier']?.toDouble() ?? 1.0,
      totalFare: json['total_fare']?.toDouble() ?? 0.0,
      confirmedPassengers: json['confirmed_passengers'] ?? 0,
      farePerPerson: json['fare_per_person']?.toDouble() ?? 0.0,
      estimatedFarePerPerson: json['estimated_fare_per_person']?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FareBreakdown &&
        other.baseFareRate == baseFareRate &&
        other.distanceKm == distanceKm &&
        other.totalFare == totalFare;
  }

  @override
  int get hashCode => 
      baseFareRate.hashCode ^ distanceKm.hashCode ^ totalFare.hashCode;
}

class RideRequest {
  final int id;
  final Ride ride;
  final User passenger;
  final String status;
  final String? message;
  final DateTime requestedAt;
  final String? pickupNote;

  const RideRequest({
    required this.id,
    required this.ride,
    required this.passenger,
    required this.status,
    this.message,
    required this.requestedAt,
    this.pickupNote,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'],
      ride: Ride.fromJson(json['ride']),
      passenger: User.fromJson(json['passenger']),
      status: json['status'],
      message: json['message'],
      requestedAt: DateTime.parse(json['requested_at']),
      pickupNote: json['pickup_note'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Rating {
  final int id;
  final User rater;
  final User ratee;
  final Ride ride;
  final int rating;
  final String? review;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.rater,
    required this.ratee,
    required this.ride,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      rater: User.fromJson(json['rater']),
      ratee: User.fromJson(json['ratee']),
      ride: Ride.fromJson(json['ride']),
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rating && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
