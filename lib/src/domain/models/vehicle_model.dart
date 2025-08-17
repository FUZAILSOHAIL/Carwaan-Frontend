class Vehicle {
  final int id;
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;
  final String vehicleType;
  final String fuelType;
  final String? engineCapacity;
  final double? fuelAverage;
  final int totalSeats;
  final int availableSeatsForRide;
  final bool hasAc;
  final String acType;
  final bool hasMusicSystem;
  final bool hasPhoneCharger;
  final bool smokingAllowed;
  final bool isVerified;
  final bool insuranceValid;
  final bool fitnessCertificateValid;
  final bool isActive;
  final bool isPrimary;
  final String? notes;
  final String fullName;
  final String displayName;
  final int passengerCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.vehicleType,
    required this.fuelType,
    this.engineCapacity,
    this.fuelAverage,
    required this.totalSeats,
    required this.availableSeatsForRide,
    required this.hasAc,
    required this.acType,
    required this.hasMusicSystem,
    required this.hasPhoneCharger,
    required this.smokingAllowed,
    required this.isVerified,
    required this.insuranceValid,
    required this.fitnessCertificateValid,
    required this.isActive,
    required this.isPrimary,
    this.notes,
    required this.fullName,
    required this.displayName,
    required this.passengerCapacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 2020,
      color: json['color'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'sedan',
      fuelType: json['fuel_type'] ?? 'petrol',
      engineCapacity: json['engine_capacity'],
      fuelAverage: json['fuel_average'] != null 
          ? (json['fuel_average'] is String 
              ? double.tryParse(json['fuel_average']) 
              : json['fuel_average'].toDouble())
          : null,
      totalSeats: json['total_seats'] ?? 4,
      availableSeatsForRide: json['available_seats_for_ride'] ?? 3,
      hasAc: json['has_ac'] ?? true,
      acType: json['ac_type'] ?? 'standard',
      hasMusicSystem: json['has_music_system'] ?? true,
      hasPhoneCharger: json['has_phone_charger'] ?? false,
      smokingAllowed: json['smoking_allowed'] ?? false,
      isVerified: json['is_verified'] ?? false,
      insuranceValid: json['insurance_valid'] ?? true,
      fitnessCertificateValid: json['fitness_certificate_valid'] ?? true,
      isActive: json['is_active'] ?? true,
      isPrimary: json['is_primary'] ?? false,
      notes: json['notes'],
      fullName: json['full_name'] ?? '${json['make'] ?? ''} ${json['model'] ?? ''} (${json['year'] ?? ''})',
      displayName: json['display_name'] ?? '${json['make'] ?? ''} ${json['model'] ?? ''} - ${json['license_plate'] ?? ''}',
      passengerCapacity: json['passenger_capacity'] ?? 3,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'vehicle_type': vehicleType,
      'fuel_type': fuelType,
      'engine_capacity': engineCapacity,
      'fuel_average': fuelAverage,
      'total_seats': totalSeats,
      'available_seats_for_ride': availableSeatsForRide,
      'has_ac': hasAc,
      'ac_type': acType,
      'has_music_system': hasMusicSystem,
      'has_phone_charger': hasPhoneCharger,
      'smoking_allowed': smokingAllowed,
      'is_verified': isVerified,
      'insurance_valid': insuranceValid,
      'fitness_certificate_valid': fitnessCertificateValid,
      'is_active': isActive,
      'is_primary': isPrimary,
      'notes': notes,
    };
  }

  // Helper methods
  String get vehicleDisplayName => '$make $model ($year)';
  String get plateDisplay => licensePlate.toUpperCase();
  String get capacityDisplay => '$availableSeatsForRide passengers';
  
  List<String> get features {
    List<String> features = [];
    if (hasAc) features.add('AC');
    if (hasMusicSystem) features.add('Music');
    if (hasPhoneCharger) features.add('Charging');
    if (!smokingAllowed) features.add('No Smoking');
    return features;
  }
}
