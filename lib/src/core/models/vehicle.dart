class Vehicle {
  final String id;
  final String userId;
  final String make;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final int totalSeats;
  final int availableSeats;
  final double fuelAverage;
  final String? imageUrl;
  final VehicleType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Additional fields to match Django model
  final String fuelType;
  final String? engineCapacity;
  final bool hasAc;
  final String acType;
  final bool hasMusicSystem;
  final bool hasPhoneCharger;
  final bool smokingAllowed;
  final bool isVerified;
  final bool insuranceValid;
  final bool fitnessCertificateValid;
  final String verificationStatus;
  final bool isPrimary;
  final String? notes;
  final String? registrationBookImageUrl;
  final String? carImageUrl;

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.totalSeats,
    int? availableSeats,
    this.fuelAverage = 10.0,
    this.imageUrl,
    required this.type,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    // Additional fields with defaults
    this.fuelType = 'petrol',
    this.engineCapacity,
    this.hasAc = true,
    this.acType = 'standard',
    this.hasMusicSystem = true,
    this.hasPhoneCharger = false,
    this.smokingAllowed = false,
    this.isVerified = false,
    this.insuranceValid = true,
    this.fitnessCertificateValid = true,
    this.verificationStatus = 'pending',
    this.isPrimary = false,
    this.notes,
    this.registrationBookImageUrl,
    this.carImageUrl,
  }) : availableSeats = availableSeats ?? (totalSeats > 0 ? totalSeats - 1 : 0);

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final totalSeats = int.tryParse(json['seating_capacity']?.toString() ?? 
                                   json['total_seats']?.toString() ?? 
                                   json['seats']?.toString() ?? '4') ?? 4;
    return Vehicle(
      id: json['id']?.toString() ?? '',
      userId: json['owner']?.toString() ?? json['user_id']?.toString() ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year']?.toString() ?? '',
      color: json['color'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      totalSeats: totalSeats,
      availableSeats: int.tryParse(json['available_seats_for_ride']?.toString() ?? 
                                  json['available_seats']?.toString() ?? '') ?? (totalSeats > 0 ? totalSeats - 1 : 0),
      fuelAverage: double.tryParse(json['fuel_average']?.toString() ?? '10.0') ?? 10.0,
      imageUrl: json['image_url'] ?? json['car_image'],
      type: VehicleType.fromString(json['vehicle_type'] ?? json['type'] ?? 'sedan'),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      // Additional fields
      fuelType: json['fuel_type'] ?? 'petrol',
      engineCapacity: json['engine_capacity'],
      hasAc: json['has_ac'] ?? true,
      acType: json['ac_type'] ?? 'standard',
      hasMusicSystem: json['has_music_system'] ?? true,
      hasPhoneCharger: json['has_phone_charger'] ?? false,
      smokingAllowed: json['smoking_allowed'] ?? false,
      isVerified: json['is_verified'] ?? false,
      insuranceValid: json['insurance_valid'] ?? true,
      fitnessCertificateValid: json['fitness_certificate_valid'] ?? true,
      verificationStatus: json['verification_status'] ?? 'pending',
      isPrimary: json['is_primary'] ?? false,
      notes: json['notes'],
      registrationBookImageUrl: json['registration_book_image'] ?? json['car_registration_book_image'],
      carImageUrl: json['car_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'seating_capacity': totalSeats,
      'total_seats': totalSeats,
      'available_seats_for_ride': availableSeats,
      'fuel_average': fuelAverage,
      'image_url': imageUrl,
      'vehicle_type': type.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Additional fields
      'fuel_type': fuelType,
      'engine_capacity': engineCapacity,
      'has_ac': hasAc,
      'ac_type': acType,
      'has_music_system': hasMusicSystem,
      'has_phone_charger': hasPhoneCharger,
      'smoking_allowed': smokingAllowed,
      'is_verified': isVerified,
      'insurance_valid': insuranceValid,
      'fitness_certificate_valid': fitnessCertificateValid,
      'verification_status': verificationStatus,
      'is_primary': isPrimary,
      'notes': notes,
      'registration_book_image': registrationBookImageUrl,
      'car_registration_book_image': registrationBookImageUrl,
      'car_image': carImageUrl,
    };
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    String? year,
    String? color,
    String? licensePlate,
    int? totalSeats,
    int? availableSeats,
    double? fuelAverage,
    String? imageUrl,
    VehicleType? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Additional fields
    String? fuelType,
    String? engineCapacity,
    bool? hasAc,
    String? acType,
    bool? hasMusicSystem,
    bool? hasPhoneCharger,
    bool? smokingAllowed,
    bool? isVerified,
    bool? insuranceValid,
    bool? fitnessCertificateValid,
    String? verificationStatus,
    bool? isPrimary,
    String? notes,
    String? registrationBookImageUrl,
    String? carImageUrl,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      fuelAverage: fuelAverage ?? this.fuelAverage,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Additional fields
      fuelType: fuelType ?? this.fuelType,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      hasAc: hasAc ?? this.hasAc,
      acType: acType ?? this.acType,
      hasMusicSystem: hasMusicSystem ?? this.hasMusicSystem,
      hasPhoneCharger: hasPhoneCharger ?? this.hasPhoneCharger,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      isVerified: isVerified ?? this.isVerified,
      insuranceValid: insuranceValid ?? this.insuranceValid,
      fitnessCertificateValid: fitnessCertificateValid ?? this.fitnessCertificateValid,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
      registrationBookImageUrl: registrationBookImageUrl ?? this.registrationBookImageUrl,
      carImageUrl: carImageUrl ?? this.carImageUrl,
    );
  }

  String get displayName => '$make $model ($year)';
  String get fullDisplayName => '$make $model $year - $color';
  
  // Helper getter for backward compatibility
  int get seats => totalSeats;
  
  // Helper to get seats available for ride (excluding driver)
  int get seatsForRide => availableSeats;
}

enum VehicleType {
  sedan,
  hatchback,
  suv,
  crossover,
  coupe,
  convertible,
  pickup,
  van,
  other;

  static VehicleType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sedan':
        return VehicleType.sedan;
      case 'hatchback':
        return VehicleType.hatchback;
      case 'suv':
        return VehicleType.suv;
      case 'crossover':
        return VehicleType.crossover;
      case 'coupe':
        return VehicleType.coupe;
      case 'convertible':
        return VehicleType.convertible;
      case 'pickup':
        return VehicleType.pickup;
      case 'van':
        return VehicleType.van;
      default:
        return VehicleType.other;
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.hatchback:
        return 'Hatchback';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.crossover:
        return 'Crossover';
      case VehicleType.coupe:
        return 'Coupe';
      case VehicleType.convertible:
        return 'Convertible';
      case VehicleType.pickup:
        return 'Pickup Truck';
      case VehicleType.van:
        return 'Van';
      case VehicleType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.sedan:
      case VehicleType.hatchback:
        return '🚗';
      case VehicleType.suv:
      case VehicleType.crossover:
        return '�';
      case VehicleType.coupe:
        return '🏎️';
      case VehicleType.convertible:
        return '�️';
      case VehicleType.van:
        return '🚐';
      case VehicleType.pickup:
        return '🛻';
      case VehicleType.other:
        return '🚗';
    }
  }
}
