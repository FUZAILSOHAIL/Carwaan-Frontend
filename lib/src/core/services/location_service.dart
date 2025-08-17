import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/location_model.dart';
import '../constants/app_config.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return true;
  }

  /// Get current location
  Future<LocationData> getCurrentLocation() async {
    await checkLocationPermission();

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    return await getLocationFromCoordinates(position.latitude, position.longitude);
  }

  /// Get location data from coordinates
  Future<LocationData> getLocationFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        String name = place.name ?? '';
        String street = place.street ?? '';
        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';
        String area = place.subAdministrativeArea ?? '';
        
        // Create a readable address
        List<String> addressParts = [];
        if (name.isNotEmpty && name != street) addressParts.add(name);
        if (street.isNotEmpty) addressParts.add(street);
        if (subLocality.isNotEmpty && subLocality != locality) addressParts.add(subLocality);
        if (locality.isNotEmpty) addressParts.add(locality);
        
        String address = addressParts.join(', ');
        String displayName = subLocality.isNotEmpty ? subLocality : (locality.isNotEmpty ? locality : name);
        
        // Check if this is a known Karachi area
        String? urduName = _getUrduNameForArea(displayName);
        
        return LocationData(
          name: displayName,
          address: address,
          latitude: latitude,
          longitude: longitude,
          urduName: urduName,
          area: area,
          city: place.administrativeArea,
        );
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    
    // Fallback if geocoding fails
    return LocationData(
      name: 'Selected Location',
      address: 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Search for places using Nominatim (OpenStreetMap)
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      // First, search in predefined Karachi areas
      List<PlaceSearchResult> karachiResults = _searchKarachiAreas(query);
      
      // Then search using Nominatim
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}, Karachi, Pakistan'
          '&format=json'
          '&limit=10'
          '&addressdetails=1'
          '&bounded=1'
          '&viewbox=66.8,25.1,67.5,24.7' // Karachi bounding box
        ),
        headers: {
          'User-Agent': 'Carwaan/1.0.0',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> results = json.decode(response.body);
        List<PlaceSearchResult> searchResults = results.map((result) {
          return PlaceSearchResult(
            placeId: result['place_id'].toString(),
            name: result['display_name'].split(',')[0],
            description: result['display_name'],
            latitude: double.tryParse(result['lat']),
            longitude: double.tryParse(result['lon']),
          );
        }).toList();

        // Combine Karachi areas with Nominatim results
        karachiResults.addAll(searchResults);
        return karachiResults;
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    return _searchKarachiAreas(query);
  }

  /// Search in predefined Karachi areas
  List<PlaceSearchResult> _searchKarachiAreas(String query) {
    String queryLower = query.toLowerCase();
    
    return AppConfig.karachiAreas
        .where((area) => 
          area['name'].toString().toLowerCase().contains(queryLower) ||
          area['urdu'].toString().contains(query))
        .map((area) => PlaceSearchResult(
          placeId: 'karachi_${area['name'].toString().replaceAll(' ', '_')}',
          name: area['name'],
          description: '${area['name']}, ${area['urdu']}, Karachi',
          latitude: area['lat'],
          longitude: area['lng'],
        ))
        .toList();
  }

  /// Get Urdu name for known Karachi areas
  String? _getUrduNameForArea(String areaName) {
    for (var area in AppConfig.karachiAreas) {
      if (area['name'].toString().toLowerCase() == areaName.toLowerCase()) {
        return area['urdu'];
      }
    }
    return null;
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  /// Get suggestions based on user's current location
  Future<List<PlaceSearchResult>> getNearbyPopularPlaces() async {
    try {
      LocationData currentLocation = await getCurrentLocation();
      
      // Return nearby popular areas from Karachi
      return AppConfig.karachiAreas
          .map((area) => PlaceSearchResult(
            placeId: 'popular_${area['name'].toString().replaceAll(' ', '_')}',
            name: area['name'],
            description: '${area['name']}, ${area['urdu']}, Karachi',
            latitude: area['lat'],
            longitude: area['lng'],
          ))
          .where((area) => calculateDistance(
            currentLocation.latitude, 
            currentLocation.longitude, 
            area.latitude!, 
            area.longitude!
          ) < 20) // Within 20km
          .take(5)
          .toList();
    } catch (e) {
      // Return some default popular places if location fails
      return AppConfig.karachiAreas
          .take(5)
          .map((area) => PlaceSearchResult(
            placeId: 'default_${area['name'].toString().replaceAll(' ', '_')}',
            name: area['name'],
            description: '${area['name']}, ${area['urdu']}, Karachi',
            latitude: area['lat'],
            longitude: area['lng'],
          ))
          .toList();
    }
  }
}
