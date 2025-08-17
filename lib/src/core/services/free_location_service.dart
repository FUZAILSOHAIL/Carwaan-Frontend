import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class FreeLocationService {
  // Get your free LocationIQ token from: https://locationiq.com/
  // Free tier: 5,000 requests/day
  // 1. Sign up at locationiq.com
  // 2. Go to dashboard and copy your token
  // 3. Replace 'pk.YOUR_LOCATIONIQ_TOKEN_HERE' with your actual token
  static const String _locationIQToken = 'pk.YOUR_LOCATIONIQ_TOKEN_HERE';
  static const Duration _timeout = Duration(seconds: 10);
  
  /// For now, we'll primarily use Nominatim (no token required)
  /// but LocationIQ is available for better performance

  /// Search for locations using multiple free APIs with fallback
  static Future<List<LocationResult>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      // First try Nominatim (no token required, reliable)
      return await _searchWithNominatim(query);
    } catch (e) {
      debugPrint('Nominatim failed: $e');
      try {
        // Fallback to LocationIQ (if token is configured)
        if (_locationIQToken != 'pk.YOUR_LOCATIONIQ_TOKEN_HERE') {
          return await _searchWithLocationIQ(query);
        } else {
          throw Exception('LocationIQ token not configured');
        }
      } catch (e2) {
        debugPrint('LocationIQ failed: $e2');
        // Final fallback to hardcoded major cities for Pakistan
        return _getFallbackLocations(query);
      }
    }
  }

  /// Primary: LocationIQ API (free tier: 5000 requests/day)
  static Future<List<LocationResult>> _searchWithLocationIQ(String query) async {
    final url = Uri.parse(
      'https://eu1.locationiq.com/v1/search.php'
      '?key=$_locationIQToken'
      '&q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=10'
      '&addressdetails=1'
      '&countrycodes=pk', // Restrict to Pakistan
    );

    final response = await http.get(url).timeout(_timeout);
    
    if (response.statusCode == 200) {
      final List results = json.decode(response.body);
      return results.map((place) => LocationResult.fromLocationIQ(place)).toList();
    } else {
      throw Exception('LocationIQ API error: ${response.statusCode}');
    }
  }

  /// Fallback 1: Nominatim (OpenStreetMap) - Free, no rate limits
  static Future<List<LocationResult>> _searchWithNominatim(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=10'
      '&addressdetails=1'
      '&countrycodes=pk', // Restrict to Pakistan
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'Carwaan-App/1.0', // Required by Nominatim
      },
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final List results = json.decode(response.body);
      return results.map((place) => LocationResult.fromNominatim(place)).toList();
    } else {
      throw Exception('Nominatim API error: ${response.statusCode}');
    }
  }

  /// Fallback 2: Hardcoded major Pakistani cities
  static List<LocationResult> _getFallbackLocations(String query) {
    final pakistanCities = [
      LocationResult(
        address: 'Karachi, Sindh, Pakistan',
        latitude: 24.8607,
        longitude: 67.0011,
        city: 'Karachi',
        state: 'Sindh',
      ),
      LocationResult(
        address: 'Lahore, Punjab, Pakistan',
        latitude: 31.5204,
        longitude: 74.3587,
        city: 'Lahore',
        state: 'Punjab',
      ),
      LocationResult(
        address: 'Islamabad, Federal Capital Territory, Pakistan',
        latitude: 33.6844,
        longitude: 73.0479,
        city: 'Islamabad',
        state: 'Federal Capital Territory',
      ),
      LocationResult(
        address: 'Rawalpindi, Punjab, Pakistan',
        latitude: 33.5651,
        longitude: 73.0169,
        city: 'Rawalpindi',
        state: 'Punjab',
      ),
      LocationResult(
        address: 'Faisalabad, Punjab, Pakistan',
        latitude: 31.4504,
        longitude: 73.1350,
        city: 'Faisalabad',
        state: 'Punjab',
      ),
      LocationResult(
        address: 'Multan, Punjab, Pakistan',
        latitude: 30.1575,
        longitude: 71.5249,
        city: 'Multan',
        state: 'Punjab',
      ),
      LocationResult(
        address: 'Peshawar, Khyber Pakhtunkhwa, Pakistan',
        latitude: 34.0151,
        longitude: 71.5249,
        city: 'Peshawar',
        state: 'Khyber Pakhtunkhwa',
      ),
      LocationResult(
        address: 'Quetta, Balochistan, Pakistan',
        latitude: 30.1798,
        longitude: 66.9750,
        city: 'Quetta',
        state: 'Balochistan',
      ),
    ];

    // Filter cities based on query
    final lowerQuery = query.toLowerCase();
    return pakistanCities
        .where((city) => 
            city.address.toLowerCase().contains(lowerQuery) ||
            city.city?.toLowerCase().contains(lowerQuery) == true)
        .toList();
  }

  /// Reverse geocoding - get address from coordinates
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Try LocationIQ first
      return await _reverseGeocodeLocationIQ(latitude, longitude);
    } catch (e) {
      try {
        // Fallback to Nominatim
        return await _reverseGeocodeNominatim(latitude, longitude);
      } catch (e2) {
        return 'Unknown Location ($latitude, $longitude)';
      }
    }
  }

  static Future<String> _reverseGeocodeLocationIQ(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://eu1.locationiq.com/v1/reverse.php'
      '?key=$_locationIQToken'
      '&lat=$latitude'
      '&lon=$longitude'
      '&format=json'
      '&addressdetails=1',
    );

    final response = await http.get(url).timeout(_timeout);
    
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['display_name'] ?? 'Unknown Location';
    } else {
      throw Exception('LocationIQ reverse geocoding failed');
    }
  }

  static Future<String> _reverseGeocodeNominatim(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$latitude'
      '&lon=$longitude'
      '&format=json'
      '&addressdetails=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'Carwaan-App/1.0',
      },
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['display_name'] ?? 'Unknown Location';
    } else {
      throw Exception('Nominatim reverse geocoding failed');
    }
  }

  /// Get current location using device GPS
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // This would typically use geolocator package
      // For now, return Karachi as default
      return const LatLng(24.8607, 67.0011);
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to address
  static Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      // First try Nominatim
      return await _reverseGeocodeWithNominatim(latitude, longitude);
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      return 'Unknown Location';
    }
  }

  /// Reverse geocode using Nominatim
  static Future<String> _reverseGeocodeWithNominatim(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$latitude'
      '&lon=$longitude'
      '&format=json'
      '&addressdetails=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'Carwaan-App/1.0',
      },
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['display_name'] ?? 'Unknown Location';
    } else {
      throw Exception('Nominatim reverse geocoding failed');
    }
  }
}

class LocationResult {
  final String address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;

  LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.postcode,
  });

  factory LocationResult.fromLocationIQ(Map<String, dynamic> json) {
    return LocationResult(
      address: json['display_name'] ?? 'Unknown Location',
      latitude: double.parse(json['lat'] ?? '0'),
      longitude: double.parse(json['lon'] ?? '0'),
      city: json['address']?['city'] ?? json['address']?['town'] ?? json['address']?['village'],
      state: json['address']?['state'],
      country: json['address']?['country'],
      postcode: json['address']?['postcode'],
    );
  }

  factory LocationResult.fromNominatim(Map<String, dynamic> json) {
    return LocationResult(
      address: json['display_name'] ?? 'Unknown Location',
      latitude: double.parse(json['lat'] ?? '0'),
      longitude: double.parse(json['lon'] ?? '0'),
      city: json['address']?['city'] ?? json['address']?['town'] ?? json['address']?['village'],
      state: json['address']?['state'],
      country: json['address']?['country'],
      postcode: json['address']?['postcode'],
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  String toString() => address;
}
