class User {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String gender;
  final double averageRating;
  final bool hasCar;
  final String? carModel;
  final String? carColor;
  final String? licensePlate;
  final String? email;
  final String? phone;
  final bool isVerified;
  final String role;
  final String? userType; // Add userType field
  final String? fullName;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? address;
  final String? workplace;
  final String? workplaceAddress;
  final double? workplaceLatitude;
  final double? workplaceLongitude;
  final String? homeAddress;
  final double? homeLatitude;
  final double? homeLongitude;
  final List<String>? preferredDays;
  final dynamic preferredDepartureTimes;
  final dynamic preferredMusic;
  final String smokingPreference;
  final String acPreference;
  final String chatPreference;
  final dynamic paymentMethods;
  final int totalRatings;
  
  // Driver verification fields
  final bool isDriver;
  final String? driverVerificationStatus;
  final String? cnicNumber;
  final String? driverLicenseNumber;
  
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.gender,
    this.averageRating = 0.0,
    this.hasCar = false,
    this.carModel,
    this.carColor,
    this.licensePlate,
    this.email,
    this.phone,
    this.isVerified = false,
    this.role = 'user',
    this.userType, // Add userType parameter
    this.fullName,
    this.bio,
    this.dateOfBirth,
    this.address,
    this.workplace,
    this.workplaceAddress,
    this.workplaceLatitude,
    this.workplaceLongitude,
    this.homeAddress,
    this.homeLatitude,
    this.homeLongitude,
    this.preferredDays,
    this.preferredDepartureTimes,
    this.preferredMusic,
    this.smokingPreference = 'no_preference',
    this.acPreference = 'no_preference',
    this.chatPreference = 'no_preference',
    this.paymentMethods,
    this.totalRatings = 0,
    this.isDriver = false,
    this.driverVerificationStatus,
    this.cnicNumber,
    this.driverLicenseNumber,
  });
  
  // Getters
  String get computedFullName => fullName ?? '$firstName $lastName';
  
  bool get isDriverVerified => isDriver && driverVerificationStatus == 'verified';
  
  bool get isAdmin => role == 'admin';
  
  // Helper methods
  String getGenderDisplay() {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
        return 'Not specified';
      default:
        return 'Not specified';
    }
  }

  String getSmokingPreferenceDisplay() {
    switch (smokingPreference) {
      case 'no_smoking':
        return 'No Smoking';
      case 'smoking_allowed':
        return 'Smoking Allowed';
      case 'no_preference':
        return 'No Preference';
      default:
        return 'No Preference';
    }
  }

  String getACPreferenceDisplay() {
    switch (acPreference) {
      case 'ac_required':
        return 'AC Required';
      case 'no_ac':
        return 'No AC';
      case 'no_preference':
        return 'No Preference';
      default:
        return 'No Preference';
    }
  }

  String getChatPreferenceDisplay() {
    switch (chatPreference) {
      case 'chatty':
        return 'Enjoy Conversation';
      case 'quiet':
        return 'Prefer Quiet';
      case 'no_preference':
        return 'No Preference';
      default:
        return 'No Preference';
    }
  }
  
  // Create a user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0, // Ensure id is not null
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePicture: json['profile_picture'],
      gender: json['gender'] ?? 'prefer_not_to_say',
      averageRating: _parseDouble(json['driver_rating'] ?? json['average_rating'] ?? 0) ?? 0.0,
      hasCar: json['has_car'] ?? false,
      carModel: json['car_model'],
      carColor: json['car_color'],
      licensePlate: json['license_plate'],
      email: json['email'],
      phone: json['phone'],
      isVerified: json['is_verified'] ?? false,
      role: json['role'] ?? 'user',
      userType: json['user_type'], // Add userType mapping
      fullName: json['full_name'],
      bio: json['bio'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      address: json['address'],
      workplace: json['workplace'],
      workplaceAddress: json['workplace_address'],
      workplaceLatitude: _parseDouble(json['workplace_latitude']),
      workplaceLongitude: _parseDouble(json['workplace_longitude']),
      homeAddress: json['home_address'],
      homeLatitude: _parseDouble(json['home_latitude']),
      homeLongitude: _parseDouble(json['home_longitude']),
      preferredDays: json['preferred_days'] != null ? List<String>.from(json['preferred_days']) : null,
      preferredDepartureTimes: json['preferred_departure_times'],
      preferredMusic: json['preferred_music'],
      smokingPreference: json['smoking_preference'] ?? 'no_preference',
      acPreference: json['ac_preference'] ?? 'no_preference',
      chatPreference: json['chat_preference'] ?? 'no_preference',
      paymentMethods: json['payment_methods'],
      totalRatings: (json['total_driver_reviews'] as int? ?? 0) + (json['total_passenger_reviews'] as int? ?? 0), // Combine both review counts
      isDriver: json['is_driver'] ?? false,
      driverVerificationStatus: json['driver_verification_status'],
      cnicNumber: json['cnic_number'],
      driverLicenseNumber: json['driver_license_number'],
    );
  }
  
  // Convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture': profilePicture,
      'gender': gender,
      'average_rating': averageRating,
      'has_car': hasCar,
      'car_model': carModel,
      'car_color': carColor,
      'license_plate': licensePlate,
      'email': email,
      'phone': phone,
      'is_verified': isVerified,
      'role': role,
      'user_type': userType,
      'full_name': fullName ?? '$firstName $lastName',
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'workplace': workplace,
      'workplace_address': workplaceAddress,
      'workplace_latitude': workplaceLatitude,
      'workplace_longitude': workplaceLongitude,
      'home_address': homeAddress,
      'home_latitude': homeLatitude,
      'home_longitude': homeLongitude,
      'preferred_days': preferredDays,
      'preferred_departure_times': preferredDepartureTimes,
      'preferred_music': preferredMusic,
      'smoking_preference': smokingPreference,
      'ac_preference': acPreference,
      'chat_preference': chatPreference,
      'payment_methods': paymentMethods,
      'total_ratings': totalRatings,
      'is_driver': isDriver,
      'driver_verification_status': driverVerificationStatus,
      'cnic_number': cnicNumber,
      'driver_license_number': driverLicenseNumber,
    };
  }

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? profilePicture,
    String? gender,
    double? averageRating,
    bool? hasCar,
    String? carModel,
    String? carColor,
    String? licensePlate,
    String? email,
    String? phone,
    bool? isVerified,
    String? role,
    String? userType,
    String? fullName,
    String? bio,
    DateTime? dateOfBirth,
    String? address,
    String? workplace,
    String? workplaceAddress,
    double? workplaceLatitude,
    double? workplaceLongitude,
    String? homeAddress,
    double? homeLatitude,
    double? homeLongitude,
    List<String>? preferredDays,
    dynamic preferredDepartureTimes,
    dynamic preferredMusic,
    String? smokingPreference,
    String? acPreference,
    String? chatPreference,
    dynamic paymentMethods,
    int? totalRatings,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePicture: profilePicture ?? this.profilePicture,
      gender: gender ?? this.gender,
      averageRating: averageRating ?? this.averageRating,
      hasCar: hasCar ?? this.hasCar,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      licensePlate: licensePlate ?? this.licensePlate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      userType: userType ?? this.userType,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      workplace: workplace ?? this.workplace,
      workplaceAddress: workplaceAddress ?? this.workplaceAddress,
      workplaceLatitude: workplaceLatitude ?? this.workplaceLatitude,
      workplaceLongitude: workplaceLongitude ?? this.workplaceLongitude,
      homeAddress: homeAddress ?? this.homeAddress,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      preferredDays: preferredDays ?? this.preferredDays,
      preferredDepartureTimes: preferredDepartureTimes ?? this.preferredDepartureTimes,
      preferredMusic: preferredMusic ?? this.preferredMusic,
      smokingPreference: smokingPreference ?? this.smokingPreference,
      acPreference: acPreference ?? this.acPreference,
      chatPreference: chatPreference ?? this.chatPreference,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }

  // Helper method to safely parse double values from API responses
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}