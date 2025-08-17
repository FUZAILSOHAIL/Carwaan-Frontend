import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_config.dart';

/// Route preference for calculating different types of routes
enum RoutePreference {
  fastest,    // Prioritize time
  shortest,   // Prioritize distance
  balanced,   // Balance between time and distance
}

/// Represents a route with detailed information
class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final Duration duration;
  final String polyline;
  final RoutePreference preference;
  final List<String> instructions;
  final Map<String, dynamic> metadata;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.duration,
    required this.polyline,
    required this.preference,
    this.instructions = const [],
    this.metadata = const {},
  });

  // Getter for compatibility with existing code
  List<LatLng>? get routeGeometry => points.isNotEmpty ? points : null;
  int get durationMinutes => duration.inMinutes;

  @override
  String toString() {
    return 'RouteResult(distance: ${distanceKm}km, duration: ${durationMinutes}min, provider: ${metadata['provider']})';
  }
}

/// Exception thrown when routing fails
class RoutingException implements Exception {
  final String message;
  final String? provider;
  final int? statusCode;

  RoutingException(this.message, {this.provider, this.statusCode});

  @override
  String toString() => 'RoutingException: $message';
}

/// Service for calculating routes using our backend API with built-in fallback
class RouteCalculationService {
  final Dio _dio;

  RouteCalculationService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  /// Calculate route between two points with specified preference
  /// This method uses our backend API which has OpenRouteService + Haversine fallback
  Future<RouteResult> calculateRoute({
    required LatLng start,
    required LatLng end,
    RoutePreference preference = RoutePreference.fastest,
    List<LatLng>? waypoints,
  }) async {
    // Check if start and end are the same
    if (_isSameLocation(start, end)) {
      return RouteResult(
        points: [start],
        distanceKm: 0.0,
        duration: Duration.zero,
        polyline: '',
        preference: preference,
        instructions: ['You are already at your destination'],
        metadata: {'provider': 'Local', 'sameLocation': true},
      );
    }

    try {
      if (waypoints != null && waypoints.isNotEmpty) {
        return await _calculateWithWaypoints(start, end, preference, waypoints);
      } else {
        return await _calculateSimpleRoute(start, end, preference);
      }
    } catch (e) {
      // If backend fails completely, use local fallback
      debugPrint('Backend route calculation failed: $e');
      return _calculateLocalFallback(start, end, preference);
    }
  }

  /// Calculate multiple route options (fastest, shortest, balanced)
  Future<List<RouteResult>> calculateAlternatives({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final requestData = {
        'start_lat': start.latitude,
        'start_lng': start.longitude,
        'end_lat': end.latitude,
        'end_lng': end.longitude,
      };

      final response = await _dio.post(
        '/api/routes/alternatives/',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List;
        
        return routes.map((routeData) {
          final preference = _parsePreference(routeData['preference']);
          return _parseBackendResponse(routeData, preference);
        }).toList();
      } else {
        throw RoutingException(
          'Backend alternatives API error: ${response.statusMessage}',
          provider: 'Backend',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback: calculate each route individually
      debugPrint('Backend alternatives failed, using individual calculations: $e');
      return await _calculateAlternativesFallback(start, end);
    }
  }

  /// Calculate simple route without waypoints
  Future<RouteResult> _calculateSimpleRoute(
    LatLng start,
    LatLng end,
    RoutePreference preference,
  ) async {
    final requestData = {
      'start_lat': start.latitude,
      'start_lng': start.longitude,
      'end_lat': end.latitude,
      'end_lng': end.longitude,
      'preference': _getPreferenceString(preference),
    };

    final response = await _dio.post(
      '/api/routes/calculate/',
      data: requestData,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode == 200) {
      return _parseBackendResponse(response.data, preference);
    } else {
      throw RoutingException(
        'Backend API error: ${response.statusMessage}',
        provider: 'Backend',
        statusCode: response.statusCode,
      );
    }
  }

  /// Calculate route with waypoints
  Future<RouteResult> _calculateWithWaypoints(
    LatLng start,
    LatLng end,
    RoutePreference preference,
    List<LatLng> waypoints,
  ) async {
    // Build coordinates array: start -> waypoints -> end
    List<List<double>> coordinates = [
      [start.longitude, start.latitude],
    ];
    
    coordinates.addAll(waypoints.map((wp) => [wp.longitude, wp.latitude]));
    coordinates.add([end.longitude, end.latitude]);

    final requestData = {
      'coordinates': coordinates,
      'preference': _getPreferenceString(preference),
    };

    final response = await _dio.post(
      '/api/routes/waypoints/',
      data: requestData,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode == 200) {
      return _parseBackendResponse(response.data, preference);
    } else {
      throw RoutingException(
        'Backend waypoints API error: ${response.statusMessage}',
        provider: 'Backend',
        statusCode: response.statusCode,
      );
    }
  }

  /// Parse response from our backend API
  RouteResult _parseBackendResponse(Map<String, dynamic> data, RoutePreference preference) {
    final distanceKm = (data['distance_km'] ?? 0.0).toDouble();
    final durationMinutes = (data['duration_minutes'] ?? 0.0).toDouble();
    final polylineString = data['polyline']?.toString() ?? '';
    final provider = data['provider'] ?? 'backend';
    final instructions = (data['instructions'] as List?)?.cast<String>() ?? [];

    // Decode polyline to get route points if available
    List<LatLng> points = [];
    if (polylineString.isNotEmpty) {
      try {
        // First, try to parse as JSON array (from OpenRouteService via our backend)
        if (polylineString.startsWith('[')) {
          final List<dynamic> coordsList = jsonDecode(polylineString);
          points = coordsList.map((coord) {
            if (coord is List && coord.length >= 2) {
              return LatLng(coord[0].toDouble(), coord[1].toDouble()); // [lat, lng] format
            }
            return LatLng(0.0, 0.0);
          }).toList();
        } else {
          // Try to decode as Google's encoded polyline (from Google Maps provider)
          final decoded = decodePolyline(polylineString);
          points = decoded.map((point) => LatLng(point[0].toDouble(), point[1].toDouble())).toList();
        }
      } catch (e) {
        debugPrint('Failed to decode polyline: $e');
        debugPrint('Polyline string: ${polylineString.substring(0, min(100, polylineString.length))}...');
        // Use start and end points as fallback
        points = [
          LatLng(data['start_lat']?.toDouble() ?? 0.0, data['start_lng']?.toDouble() ?? 0.0),
          LatLng(data['end_lat']?.toDouble() ?? 0.0, data['end_lng']?.toDouble() ?? 0.0),
        ];
      }
    }

    return RouteResult(
      points: points,
      distanceKm: distanceKm,
      duration: Duration(minutes: durationMinutes.round()),
      polyline: polylineString,
      preference: preference,
      instructions: instructions,
      metadata: {
        'provider': provider,
        'backendResponse': data,
        'error': data['error'],
        'fallbackUsed': data['error']?.toString().contains('Haversine') ?? false,
      },
    );
  }

  /// Calculate alternatives using individual route calculations
  Future<List<RouteResult>> _calculateAlternativesFallback(LatLng start, LatLng end) async {
    final List<Future<RouteResult?>> futures = RoutePreference.values.map((preference) =>
        calculateRoute(start: start, end: end, preference: preference)
        .then<RouteResult?>((result) => result)
        .catchError((e) {
          debugPrint('Error calculating route for $preference: $e');
          return null;
        })).toList();

    final results = await Future.wait(futures);
    return results.whereType<RouteResult>().toList();
  }

  /// Local fallback calculation using Haversine distance
  RouteResult _calculateLocalFallback(LatLng start, LatLng end, RoutePreference preference) {
    final distance = _calculateHaversineDistance(start, end);
    final duration = _estimateDrivingTime(distance, preference);

    return RouteResult(
      points: [start, end],
      distanceKm: distance,
      duration: duration,
      polyline: '',
      preference: preference,
      instructions: [
        'Head towards ${end.latitude.toStringAsFixed(4)}, ${end.longitude.toStringAsFixed(4)}',
        'You have arrived at your destination'
      ],
      metadata: {
        'provider': 'LocalFallback',
        'method': 'Haversine',
        'note': 'Straight-line approximation - backend unavailable'
      },
    );
  }

  /// Calculate Haversine distance between two points
  double _calculateHaversineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = start.latitude * (pi / 180);
    final double lat2Rad = end.latitude * (pi / 180);
    final double deltaLatRad = (end.latitude - start.latitude) * (pi / 180);
    final double deltaLngRad = (end.longitude - start.longitude) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Estimate driving time based on distance and preference
  Duration _estimateDrivingTime(double distanceKm, RoutePreference preference) {
    double averageSpeedKmh;
    
    switch (preference) {
      case RoutePreference.fastest:
        averageSpeedKmh = 60; // Assume faster roads
        break;
      case RoutePreference.shortest:
        averageSpeedKmh = 40; // Assume slower, more direct roads
        break;
      case RoutePreference.balanced:
        averageSpeedKmh = 50; // Balanced speed
        break;
    }
    
    final double hours = distanceKm / averageSpeedKmh;
    return Duration(minutes: (hours * 60).round());
  }

  /// Check if two locations are the same (within a small threshold)
  bool _isSameLocation(LatLng start, LatLng end, {double threshold = 0.0001}) {
    return (start.latitude - end.latitude).abs() < threshold &&
           (start.longitude - end.longitude).abs() < threshold;
  }

  /// Convert RoutePreference enum to string for API
  String _getPreferenceString(RoutePreference preference) {
    switch (preference) {
      case RoutePreference.fastest:
        return 'fastest';
      case RoutePreference.shortest:
        return 'shortest';
      case RoutePreference.balanced:
        return 'balanced';
    }
  }

  /// Parse preference string back to enum
  RoutePreference _parsePreference(String? preferenceStr) {
    switch (preferenceStr?.toLowerCase()) {
      case 'fastest':
        return RoutePreference.fastest;
      case 'shortest':
        return RoutePreference.shortest;
      case 'balanced':
        return RoutePreference.balanced;
      default:
        return RoutePreference.fastest;
    }
  }

  /// Check if the backend route service is available
  Future<bool> isServiceAvailable() async {
    try {
      final response = await _dio.get('/api/routes/status/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _dio.close();
  }
}
