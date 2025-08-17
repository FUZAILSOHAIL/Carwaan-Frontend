// ignore_for_file: avoid_print, undefined_class, undefined_method, uri_does_not_exist, dangling_library_doc_comments

/*
 * LEGACY FILE - MOVED TO LEGACY FOLDER
 * 
 * This file contains outdated examples for OpenRouteService integration
 * and is kept for reference only. It should not be used in new code.
 * 
 * Current routing implementation uses RouteCalculationService instead.
 */

/// Example usage of the updated OpenRouteService in Flutter
/// This shows how to use the service after the backend integration

import '../core/services/openroute_service.dart';

class RouteExampleController {
  final OpenRouteService _routeService = OpenRouteService();

  /// Example: Get distance and duration for a single route
  Future<void> calculateSingleRoute() async {
    final result = await _routeService.getDistanceAndDuration(
      startLat: 24.939106,
      startLng: 67.033946,
      endLat: 24.926132,
      endLng: 67.092689,
      preference: 'fastest', // optional: 'fastest', 'shortest', 'balanced'
    );

    if (result != null && result['success'] == true) {
      print('Distance: ${result['distance_km']} km');
      print('Duration: ${result['duration_minutes']} minutes');
      print('Provider: ${result['provider']}');
      print('Polyline: ${result['polyline']}');
    } else {
      print('Error: ${result?['error'] ?? 'Unknown error'}');
    }
  }

  /// Example: Get multiple route alternatives
  Future<void> getMultipleRoutes() async {
    final routes = await _routeService.getRouteAlternatives(
      startLat: 24.939106,
      startLng: 67.033946,
      endLat: 24.926132,
      endLng: 67.092689,
    );

    if (routes.isNotEmpty) {
      for (var route in routes) {
        print('${route['preference'].toString().toUpperCase()} ROUTE:');
        print('  Distance: ${route['distance_km']} km');
        print('  Duration: ${route['duration_minutes']} minutes');
        print('  Provider: ${route['provider']}');
        print('');
      }
    } else {
      print('No routes found');
    }
  }

  /// Example: Calculate route with waypoints
  Future<void> calculateRouteWithWaypoints() async {
    final coordinates = [
      [67.033946, 24.939106], // Start: [lng, lat]
      [67.050000, 24.930000], // Waypoint: [lng, lat]
      [67.092689, 24.926132], // End: [lng, lat]
    ];

    final result = await _routeService.getRouteWithWaypoints(
      coordinates: coordinates,
    );

    if (result != null && result['success'] == true) {
      print('Total Distance: ${result['distance_km']} km');
      print('Total Duration: ${result['duration_minutes']} minutes');
      print('Polyline: ${result['polyline']}');
    } else {
      print('Error: ${result?['error'] ?? 'Unknown error'}');
    }
  }

  /// Example: Use in a widget for ride booking
  Future<Map<String, dynamic>?> calculateRideRoute({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    try {
      // Calculate fastest route for ride estimation
      final result = await _routeService.getDistanceAndDuration(
        startLat: pickupLat,
        startLng: pickupLng,
        endLat: dropoffLat,
        endLng: dropoffLng,
        preference: 'fastest',
      );

      if (result != null && result['success'] == true) {
        return {
          'distance': result['distance_km'],
          'duration': result['duration_minutes'],
          'polyline': result['polyline'],
          'success': true,
        };
      } else {
        return {
          'success': false,
          'error': result?['error'] ?? 'Route calculation failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception: $e',
      };
    }
  }
}
