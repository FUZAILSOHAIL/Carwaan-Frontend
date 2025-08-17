import 'dart:math';
import '../constants/app_config.dart';
import '../models/ride_models.dart';
import './api_service.dart';

class FareCalculationService {
  static FareCalculationService? _instance;
  static FareCalculationService get instance => _instance ??= FareCalculationService._();
  FareCalculationService._();

  /// Calculate individual fare for a passenger based on their specific distance
  FareBreakdown calculateIndividualFare({
    required double passengerDistanceKm,
    required DateTime departureTime,
    double baseFareRate = AppConfig.baseFareRate,
  }) {
    // Check if it's peak hours
    bool isPeakHours = _isPeakHours(departureTime);
    double currentRate = isPeakHours ? baseFareRate * 2.0 : baseFareRate;
    
    // Calculate fare for this passenger's individual distance
    double individualFare = passengerDistanceKm * currentRate;
    
    return FareBreakdown(
      baseFareRate: baseFareRate,
      distanceKm: passengerDistanceKm,
      baseFare: passengerDistanceKm * baseFareRate,
      isPeakHours: isPeakHours,
      peakMultiplier: isPeakHours ? 2.0 : 1.0,
      totalFare: individualFare,
      confirmedPassengers: 1,
      farePerPerson: individualFare,
    );
  }

  /// Calculate fare for a ride (legacy method for backward compatibility)
  FareBreakdown calculateFare({
    required double distanceKm,
    required DateTime departureTime,
    required int confirmedPassengers,
    double baseFareRate = AppConfig.baseFareRate,
  }) {
    // Base fare calculation
    double baseFare = distanceKm * baseFareRate;
    
    // Check if it's peak hours
    bool isPeakHours = _isPeakHours(departureTime);
    double peakMultiplier = isPeakHours ? 2.0 : 1.0;
    
    // Apply peak hour multiplier
    double totalFare = baseFare * peakMultiplier;
    
    // Calculate per person fare (including driver in count)
    int totalPeople = confirmedPassengers + 1; // +1 for driver
    double farePerPerson = totalPeople > 1 ? totalFare / totalPeople : totalFare;
    
    return FareBreakdown(
      baseFareRate: baseFareRate,
      distanceKm: distanceKm,
      baseFare: baseFare,
      isPeakHours: isPeakHours,
      peakMultiplier: peakMultiplier,
      totalFare: totalFare,
      confirmedPassengers: confirmedPassengers,
      farePerPerson: farePerPerson,
    );
  }

  /// Calculate estimated fare (before confirmation)
  FareBreakdown calculateEstimatedFare({
    required double distanceKm,
    required DateTime departureTime,
    required int estimatedPassengers,
    double baseFareRate = AppConfig.baseFareRate,
  }) {
    double baseFare = distanceKm * baseFareRate;
    bool isPeakHours = _isPeakHours(departureTime);
    double peakMultiplier = isPeakHours ? 2.0 : 1.0;
    double totalFare = baseFare * peakMultiplier;
    
    // Use estimated passenger count for calculation
    int totalPeople = max(estimatedPassengers + 1, 1);
    double estimatedFarePerPerson = totalFare / totalPeople;
    
    return FareBreakdown(
      baseFareRate: baseFareRate,
      distanceKm: distanceKm,
      baseFare: baseFare,
      isPeakHours: isPeakHours,
      peakMultiplier: peakMultiplier,
      totalFare: totalFare,
      confirmedPassengers: 0, // Not confirmed yet
      farePerPerson: 0.0, // Will be calculated when confirmed
      estimatedFarePerPerson: estimatedFarePerPerson,
    );
  }

  /// Check if given time is during peak hours
  bool _isPeakHours(DateTime dateTime) {
    int hour = dateTime.hour;
    
    // Morning peak: 8 AM - 10 AM
    bool morningPeak = hour >= AppConfig.morningPeakStart[0] && 
                      hour < AppConfig.morningPeakEnd[0];
    
    // Evening peak: 5 PM - 7 PM
    bool eveningPeak = hour >= AppConfig.eveningPeakStart[0] && 
                      hour < AppConfig.eveningPeakEnd[0];
    
    return morningPeak || eveningPeak;
  }

  /// Get peak hours status text
  String getPeakHoursText(DateTime dateTime) {
    if (_isPeakHours(dateTime)) {
      int hour = dateTime.hour;
      if (hour >= AppConfig.morningPeakStart[0] && hour < AppConfig.morningPeakEnd[0]) {
        return 'Morning Peak Hours (8-10 AM)'; // Morning peak hours
      } else {
        return 'Evening Peak Hours (5-7 PM)'; // Evening peak hours
      }
    }
    return 'Normal Time'; // Normal time
  }

  /// Calculate fare savings when splitting
  Map<String, dynamic> calculateSavings({
    required double totalFare,
    required int passengers,
  }) {
    double farePerPerson = passengers > 1 ? totalFare / passengers : totalFare;
    double savings = passengers > 1 ? totalFare - farePerPerson : 0.0;
    double savingsPercentage = passengers > 1 ? (savings / totalFare) * 100 : 0.0;
    
    return {
      'total_fare': totalFare,
      'fare_per_person': farePerPerson,
      'savings_amount': savings,
      'savings_percentage': savingsPercentage,
      'passenger_count': passengers,
    };
  }

  /// Get fare display text in English
  String getFareDisplayText(double fare) {
    return 'Rs. ${fare.toStringAsFixed(0)}';
  }

  /// Get distance display text in English
  String getDistanceDisplayText(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} meters';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Validate fare calculation inputs
  bool isValidFareCalculation({
    required double distanceKm,
    required int passengers,
  }) {
    return distanceKm > 0 && distanceKm < 1000 && passengers > 0 && passengers <= 6;
  }

  /// Get fare breakdown explanation
  List<String> getFareExplanation(FareBreakdown breakdown) {
    List<String> explanation = [];
    
    explanation.add('Distance: ${getDistanceDisplayText(breakdown.distanceKm)}');
    explanation.add('Base Rate: Rs. ${breakdown.baseFareRate.toInt()}/km');
    explanation.add('Base Fare: ${getFareDisplayText(breakdown.baseFare)}');
    
    if (breakdown.isPeakHours) {
      explanation.add('Peak Hour Multiplier: ×${breakdown.peakMultiplier}');
    }
    
    explanation.add('Total Fare: ${getFareDisplayText(breakdown.totalFare)}');
    
    if (breakdown.confirmedPassengers > 0) {
      explanation.add('Passengers: ${breakdown.confirmedPassengers + 1} people');
      explanation.add('Per Person: ${getFareDisplayText(breakdown.farePerPerson)}');
    } else if (breakdown.estimatedFarePerPerson != null) {
      explanation.add('Estimated Per Person: ${getFareDisplayText(breakdown.estimatedFarePerPerson!)}');
    }
    
    return explanation;
  }

  /// Calculate fare using API
  Future<FareBreakdown> calculateFareAPI({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required int seats,
    DateTime? departureTime,
  }) async {
    try {
      final result = await apiService.calculateFare(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        seats: seats,
        departureTime: departureTime?.toIso8601String(),
      );
      
      return FareBreakdown(
        baseFareRate: result['per_km_rate']?.toDouble() ?? AppConfig.baseFareRate,
        distanceKm: result['distance_km']?.toDouble() ?? 0.0,
        baseFare: result['base_fare']?.toDouble() ?? 0.0,
        isPeakHours: result['is_peak_hours'] ?? false,
        peakMultiplier: result['peak_multiplier']?.toDouble() ?? 1.0,
        totalFare: result['total_fare']?.toDouble() ?? 0.0,
        confirmedPassengers: seats,
        farePerPerson: result['per_seat_fare']?.toDouble() ?? 0.0,
      );
    } catch (e) {
      // Fallback to local calculation if API fails
      final distance = _calculateDistance(pickupLat, pickupLng, dropoffLat, dropoffLng);
      return calculateFare(
        distanceKm: distance,
        departureTime: departureTime ?? DateTime.now(),
        confirmedPassengers: seats,
      );
    }
  }

  /// Calculate individual passenger fare using API
  Future<FareBreakdown> calculateIndividualFareAPI({
    required double passengerDistanceKm,
    required DateTime departureTime,
  }) async {
    try {
      final result = await apiService.calculateIndividualFare(
        passengerDistanceKm: passengerDistanceKm,
        departureTime: departureTime.toIso8601String(),
      );
      
      return FareBreakdown(
        baseFareRate: result['rate_per_km']?.toDouble() ?? AppConfig.baseFareRate,
        distanceKm: passengerDistanceKm,
        baseFare: result['base_amount']?.toDouble() ?? 0.0,
        isPeakHours: result['is_peak_hour'] ?? false,
        peakMultiplier: result['peak_multiplier']?.toDouble() ?? 1.0,
        totalFare: result['fare_amount']?.toDouble() ?? 0.0,
        confirmedPassengers: 1,
        farePerPerson: result['fare_amount']?.toDouble() ?? 0.0,
      );
    } catch (e) {
      // Fallback to local calculation if API fails
      return calculateIndividualFare(
        passengerDistanceKm: passengerDistanceKm,
        departureTime: departureTime,
      );
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth radius in meters
    double phi1 = lat1 * pi / 180;
    double phi2 = lat2 * pi / 180;
    double deltaPhi = (lat2 - lat1) * pi / 180;
    double deltaLambda = (lon2 - lon1) * pi / 180;

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
               cos(phi1) * cos(phi2) *
               sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return (R * c) / 1000; // Return distance in kilometers
  }
}
