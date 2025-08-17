import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/message_service.dart';
import '../../../core/services/free_location_service.dart';
import '../../../services/route_calculation_service.dart';

class ImprovedRouteLocationPicker extends StatefulWidget {
  final String title;
  final latlong.LatLng? pickupLocation;
  final latlong.LatLng? dropoffLocation;
  final String? pickupAddress;
  final String? dropoffAddress;

  const ImprovedRouteLocationPicker({
    super.key,
    required this.title,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupAddress,
    this.dropoffAddress,
  });

  @override
  State<ImprovedRouteLocationPicker> createState() => _ImprovedRouteLocationPickerState();
}

class _ImprovedRouteLocationPickerState extends State<ImprovedRouteLocationPicker> {
  final MessageService _messageService = Get.find<MessageService>();
  final TextEditingController _searchController = TextEditingController();

  MapController? _mapController;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  
  // Location state
  latlong.LatLng? _pickupLocation;
  latlong.LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  
  // Search state
  List<LocationResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchTimer;
  bool _showSearchResults = false;
  
  // Route state
  List<latlong.LatLng> _routePoints = [];
  double _routeDistance = 0.0;
  int _routeDuration = 0;
  bool _isCalculatingRoute = false;
  String _routePreference = 'fastest';
  
  // Map state
  latlong.LatLng _currentMapCenter = const latlong.LatLng(24.8607, 67.0011); // Karachi default
  bool _isSelectingPickup = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocations();
  }

  void _initializeLocations() {
    if (widget.pickupLocation != null) {
      _pickupLocation = widget.pickupLocation;
      _pickupAddress = widget.pickupAddress ?? '';
    }
    if (widget.dropoffLocation != null) {
      _dropoffLocation = widget.dropoffLocation;
      _dropoffAddress = widget.dropoffAddress ?? '';
    }
    
    // Set initial map center
    if (_pickupLocation != null) {
      _currentMapCenter = latlong.LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude);
    } else if (_dropoffLocation != null) {
      _currentMapCenter = latlong.LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude);
    }
    
    // Determine what we're selecting first
    if (_pickupLocation == null) {
      _isSelectingPickup = true;
    } else if (_dropoffLocation == null) {
      _isSelectingPickup = false;
    }
    
    _updateMarkersAndRoute();
  }

  void _updateMarkersAndRoute() {
    _updateMarkers();
    if (_pickupLocation != null && _dropoffLocation != null) {
      _calculateRouteWithRoads();
    } else {
      // Clear route if both locations aren't selected
      setState(() {
        _routePoints = [];
        _polylines.clear();
        _routeDistance = 0.0;
        _routeDuration = 0;
      });
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          point: latlong.LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showLocationDialog(true),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      );
    }

    if (_dropoffLocation != null) {
      _markers.add(
        Marker(
          point: latlong.LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showLocationDialog(false),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      );
    }
    
    if (mounted) setState(() {});
  }

  void _showLocationDialog(bool isPickup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isPickup ? 'Pickup Location' : 'Drop-off Location',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isPickup ? _pickupAddress : _dropoffAddress,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF0EA5E9))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isSelectingPickup = isPickup;
              });
              _showSearchBottomSheet();
            },
            child: const Text('Change', style: TextStyle(color: Color(0xFF0EA5E9))),
          ),
        ],
      ),
    );
  }

  // Calculate route using the RouteCalculationService
  Future<void> _calculateRouteWithRoads() async {
    if (_pickupLocation == null || _dropoffLocation == null) return;

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      // Convert route preference string to enum
      RoutePreference preference;
      switch (_routePreference) {
        case 'fastest':
          preference = RoutePreference.fastest;
          break;
        case 'shortest':
          preference = RoutePreference.shortest;
          break;
        case 'recommended':
          preference = RoutePreference.balanced;
          break;
        default:
          preference = RoutePreference.fastest;
      }

      // Use the RouteCalculationService
      final routeService = RouteCalculationService();
      final result = await routeService.calculateRoute(
        start: latlong.LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
        end: latlong.LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
        preference: preference,
      );

      setState(() {
        _routePoints = result.points;
        _routeDistance = result.distanceKm;
        _routeDuration = result.durationMinutes;

        // Clear existing polylines and add new route
        _polylines.clear();
        if (_routePoints.isNotEmpty) {
          _polylines.add(
            Polyline(
              points: _routePoints,
              color: Colors.blue,
              strokeWidth: 4.0,
            ),
          );
        }
      });

      // Fit map to route
      if (_routePoints.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fitMapToRoute();
          }
        });
      }

      debugPrint('✅ Route calculated using RouteCalculationService: ${_routeDistance.toStringAsFixed(1)} km, ${_routePoints.length} points');
      
      // Dispose the service
      routeService.dispose();

    } catch (e) {
      debugPrint('❌ Route calculation error: $e');
      // Fallback to straight line route
      _createStraightLineRoute();
    } finally {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  void _createStraightLineRoute() {
    if (_pickupLocation == null || _dropoffLocation == null) return;
    
    setState(() {
      _routePoints = [
        latlong.LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
        latlong.LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
      ];
      
      _polylines.clear();
      _polylines.add(
        Polyline(
          points: _routePoints,
          color: Colors.orange,
          strokeWidth: 4.0,
        ),
      );
      
      // Calculate straight-line distance as fallback (returns in km directly)
      _routeDistance = _calculateStraightLineDistance(
        _pickupLocation!.latitude, _pickupLocation!.longitude,
        _dropoffLocation!.latitude, _dropoffLocation!.longitude
      );
      _routeDuration = (_routeDistance * 2).round(); // Rough estimate: 2 mins per km
    });
    
    debugPrint('🔶 Created straight-line route: ${_routeDistance.toStringAsFixed(1)} km');
    _fitMapToRoute();
  }

  double _calculateStraightLineDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLatRad = (lat2 - lat1) * (pi / 180);
    final double deltaLngRad = (lng2 - lng1) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _fitMapToRoute() {
    if (_mapController == null || _routePoints.isEmpty) return;

    // Calculate bounds from all route points
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Add some padding to the bounds
    final double latPadding = (maxLat - minLat) * 0.1;
    final double lngPadding = (maxLng - minLng) * 0.1;

    final bounds = LatLngBounds(
      latlong.LatLng(minLat - latPadding, minLng - lngPadding),
      latlong.LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    debugPrint('🗺️ Fitting map to bounds: ${bounds.southWest} to ${bounds.northEast}');

    // Use a slight delay to ensure the map is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_mapController != null && mounted) {
        try {
          _mapController!.fitCamera(
            CameraFit.bounds(
              bounds: bounds, 
              padding: const EdgeInsets.all(80.0)
            )
          );
          debugPrint('✅ Map fitted to route bounds');
        } catch (e) {
          debugPrint('❌ Error fitting map to bounds: $e');
        }
      }
    });
  }

  Future<void> _onMapTap(latlong.LatLng position) async {
    if (_isSelectingPickup) {
      await _setPickupLocation(position);
    } else {
      await _setDropoffLocation(position);
    }
  }

  Future<void> _setPickupLocation(latlong.LatLng position) async {
    setState(() {
      _pickupLocation = latlong.LatLng(position.latitude, position.longitude);
    });
    
    // Get address from coordinates
    try {
      final addresses = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (addresses.isNotEmpty) {
        final place = addresses.first;
        setState(() {
          // Build a more comprehensive address from placemark
          String address = '';
          if (place.street != null && place.street!.isNotEmpty) {
            address = place.street!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            address = place.thoroughfare!;
          } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            address = place.subThoroughfare!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            address = place.locality!;
          } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address = place.subLocality!;
          } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            address = place.subAdministrativeArea!;
          } else {
            address = 'Pickup Location';
          }
          _pickupAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        _pickupAddress = 'Pickup Location';
      });
    }
    
    // Switch to selecting dropoff if not set
    if (_dropoffLocation == null) {
      setState(() {
        _isSelectingPickup = false;
      });
    }
    
    _updateMarkersAndRoute();
  }

  Future<void> _setDropoffLocation(latlong.LatLng position) async {
    setState(() {
      _dropoffLocation = latlong.LatLng(position.latitude, position.longitude);
    });
    
    try {
      final addresses = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (addresses.isNotEmpty) {
        final place = addresses.first;
        setState(() {
          // Build a more comprehensive address from placemark
          String address = '';
          if (place.street != null && place.street!.isNotEmpty) {
            address = place.street!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            address = place.thoroughfare!;
          } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            address = place.subThoroughfare!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            address = place.locality!;
          } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address = place.subLocality!;
          } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            address = place.subAdministrativeArea!;
          } else {
            address = 'Destination';
          }
          _dropoffAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        _dropoffAddress = 'Destination';
      });
    }
    
    _updateMarkersAndRoute();
  }

  void _changeRoutePreference(String preference) {
    setState(() {
      _routePreference = preference;
    });
    _calculateRouteWithRoads();
  }

  // Enhanced search functionality with improved performance and caching
  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    // Reduced debounce time for better responsiveness
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      // Minimum query length check for better performance
      if (query.length < 2) {
        setState(() {
          _searchResults = [];
        });
        return;
      }
      
      // Enhanced search with local suggestions first, then remote
      List<LocationResult> results = [];
      
      // Add popular local destinations for quick access
      if (query.length < 4) {
        results.addAll(_getPopularDestinations(query));
      }
      
      // Perform remote search
      final remoteResults = await FreeLocationService.searchLocations(query);
      
      // Combine and deduplicate results
      final allResults = [...results, ...remoteResults];
      final uniqueResults = _deduplicateResults(allResults);
      
      if (mounted) {
        setState(() {
          _searchResults = uniqueResults.take(8).toList(); // Limit to 8 results for better UI
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        _messageService.showError('Failed to search locations');
        // Show popular destinations as fallback
        setState(() {
          _searchResults = _getPopularDestinations(query);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Get popular destinations for quick selection
  List<LocationResult> _getPopularDestinations(String query) {
    final popularPlaces = [
      LocationResult(
        address: 'Karachi Airport (Jinnah International Airport)',
        latitude: 24.9056,
        longitude: 67.1608,
      ),
      LocationResult(
        address: 'Clifton Beach, Karachi',
        latitude: 24.8138,
        longitude: 67.0299,
      ),
      LocationResult(
        address: 'Dolmen Mall Clifton, Karachi',
        latitude: 24.8157,
        longitude: 67.0308,
      ),
      LocationResult(
        address: 'Lucky One Mall, Karachi',
        latitude: 24.8916,
        longitude: 67.0719,
      ),
      LocationResult(
        address: 'Port Grand, Karachi',
        latitude: 24.8480,
        longitude: 67.0211,
      ),
      LocationResult(
        address: 'Saddar, Karachi',
        latitude: 24.8614,
        longitude: 67.0099,
      ),
      LocationResult(
        address: 'Gulshan-e-Iqbal, Karachi',
        latitude: 24.9207,
        longitude: 67.0969,
      ),
      LocationResult(
        address: 'DHA Phase 2, Karachi',
        latitude: 24.8249,
        longitude: 67.0622,
      ),
    ];

    if (query.isEmpty) {
      return popularPlaces.take(5).toList();
    }

    return popularPlaces
        .where((place) => place.address.toLowerCase().contains(query.toLowerCase()))
        .take(3)
        .toList();
  }

  // Remove duplicate results based on proximity
  List<LocationResult> _deduplicateResults(List<LocationResult> results) {
    final List<LocationResult> unique = [];
    const double proximityThreshold = 0.001; // ~100 meters

    for (final result in results) {
      bool isDuplicate = false;
      
      for (final existing in unique) {
        final distance = _calculateStraightLineDistance(
          result.latitude, result.longitude,
          existing.latitude, existing.longitude,
        );
        
        if (distance < proximityThreshold) {
          isDuplicate = true;
          break;
        }
      }
      
      if (!isDuplicate) {
        unique.add(result);
      }
    }
    
    return unique;
  }

  void _selectSearchResult(LocationResult result) {
    final position = latlong.LatLng(result.latitude, result.longitude);
    
    // Provide haptic feedback for better UX
    if (mounted) {
      // Clear search state first
      setState(() {
        _searchController.clear();
        _searchResults = [];
        _showSearchResults = false;
      });
      
      if (_isSelectingPickup) {
        setState(() {
          _pickupLocation = latlong.LatLng(result.latitude, result.longitude);
          _pickupAddress = _getFirstLineOfAddress(result.address);
          _isSelectingPickup = false; // Auto-switch to dropoff selection for better UX
        });
        
        // Show success message
        _messageService.showSuccess('Pickup location selected');
      } else {
        setState(() {
          _dropoffLocation = latlong.LatLng(result.latitude, result.longitude);
          _dropoffAddress = _getFirstLineOfAddress(result.address);
        });
        
        // Show success message
        _messageService.showSuccess('Destination selected');
      }
      
      // Move map to selected location with smooth animation
      _mapController?.move(position, 16.0);
      
      // Update markers and calculate route
      _updateMarkersAndRoute();
      
      // If both locations are selected, show route calculation message
      if (_pickupLocation != null && _dropoffLocation != null) {
        _messageService.showInfo('Calculating optimal route...');
      }
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _messageService.showError('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _messageService.showError('Location permissions are permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = latlong.LatLng(position.latitude, position.longitude);
      
      // Get address from coordinates
      String address = 'Current Location';
      try {
        final addresses = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (addresses.isNotEmpty) {
          final place = addresses.first;
          // Build a more comprehensive address from placemark
          if (place.street != null && place.street!.isNotEmpty) {
            address = place.street!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            address = place.thoroughfare!;
          } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            address = place.subThoroughfare!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            address = place.locality!;
          } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address = place.subLocality!;
          } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            address = place.subAdministrativeArea!;
          } else {
            address = 'Current Location';
          }
        }
      } catch (e) {
        debugPrint('Failed to get address: $e');
      }
      
      if (_isSelectingPickup) {
        setState(() {
          _pickupLocation = latlong.LatLng(position.latitude, position.longitude);
          _pickupAddress = address;
          _isSelectingPickup = false; // Switch to dropoff selection
        });
      } else {
        setState(() {
          _dropoffLocation = latlong.LatLng(position.latitude, position.longitude);
          _dropoffAddress = address;
        });
      }
      
      // Move map to current location
      _mapController?.move(latLng, 17.0);
      
      _updateMarkersAndRoute();
      
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _messageService.showError('Failed to get current location');
    }
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isSelectingPickup ? 'Select Pickup Location' : 'Select Drop-off Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // Search field
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search for locations...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF0EA5E9)),
                        suffixIcon: _isSearching 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ],
                ),
              ),
              
              // Search results
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: Icon(
                        _isSelectingPickup ? Icons.location_on : Icons.flag,
                        color: _isSelectingPickup ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        _getFirstLineOfAddress(result.address),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _selectSearchResult(result);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSelection() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      _messageService.showError('Please select both pickup and drop-off locations');
      return;
    }

    Navigator.pop(context, {
      'pickup_location': _pickupLocation,
      'dropoff_location': _dropoffLocation,
      'pickup_address': _pickupAddress,
      'dropoff_address': _dropoffAddress,
      'route_distance': _routeDistance,
      'route_duration': _routeDuration,
      'route_preference': _routePreference, // Add route preference to return data
    });
  }

  // Helper method to format distance with proper validation
  String _formatDistance(double distance) {
    // If distance is suspiciously large (>1000 km), it might be in meters
    if (distance > 1000) {
      // Convert from meters to km if it seems like it's in meters
      double correctedDistance = distance / 1000.0;
      return '${correctedDistance.toStringAsFixed(1)} km';
    } else if (distance < 0.01) {
      return '< 0.1 km';
    }
    
    return '${distance.toStringAsFixed(1)} km';
  }

  // Helper method to get only the first meaningful part of the address
  String _getFirstLineOfAddress(String fullAddress) {
    if (fullAddress.isEmpty) return 'Selected Location';
    
    // Split by comma and take the first meaningful part
    final parts = fullAddress.split(',');
    
    // Try to get the most specific part (usually the first part)
    for (final part in parts) {
      final trimmed = part.trim();
      // Skip empty parts, "Pakistan", and very short parts
      if (trimmed.isNotEmpty && 
          !trimmed.toLowerCase().contains('pakistan') && 
          !trimmed.toLowerCase().contains('karachi') &&
          trimmed.length > 2) {
        return trimmed;
      }
    }
    
    // If no meaningful part found, try the first non-empty part
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty && trimmed.length > 1) {
        return trimmed;
      }
    }
    
    // Last fallback - return the original address if all else fails
    return fullAddress.isNotEmpty ? fullAddress : 'Selected Location';
  }

  Widget _buildPreferenceChip(String preference, String label) {
    final isSelected = _routePreference == preference;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _changeRoutePreference(preference);
        }
      },
      selectedColor: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
      backgroundColor: Colors.grey[800],
      side: BorderSide(
        color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey[700]!,
      ),
      checkmarkColor: const Color(0xFF0EA5E9),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background consistent with login screen
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.check, color: Colors.white),
            tooltip: 'Confirm Selection',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Flutter Map with proper container
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentMapCenter,
                initialZoom: 12.0,
                onTap: (tapPosition, point) => _onMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.carwaan.app',
                  maxZoom: 19,
                ),
                PolylineLayer(
                  polylines: _polylines,
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          
            // Search Bar at the top
            Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search TextField
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _isSelectingPickup 
                            ? 'Search pickup location...' 
                            : 'Search drop-off location...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF0EA5E9)),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSearching)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                                ),
                              )
                            else if (_searchController.text.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _showSearchResults = false;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 20, color: Colors.white70),
                              ),
                            IconButton(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location, color: Color(0xFF0EA5E9)),
                              tooltip: 'Use Current Location',
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      onChanged: _onSearchChanged,
                      onTap: () {
                        // Show popular destinations when field is focused
                        if (_searchController.text.isEmpty) {
                          setState(() {
                            _showSearchResults = true;
                            _searchResults = _getPopularDestinations('');
                          });
                        }
                      },
                    ),
                  ),
                  
                  // Search results with enhanced UI
                  if (_showSearchResults && (_searchResults.isNotEmpty || _searchController.text.isEmpty))
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.grey[600]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header for search results
                          if (_searchResults.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _searchController.text.isEmpty 
                                    ? 'Popular Destinations' 
                                    : 'Search Results',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Divider(color: Colors.grey[600], height: 1),
                          ],
                          
                          // Results list
                          Expanded(
                            child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.search_off, color: Colors.grey[400], size: 32),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No locations found',
                                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Try a different search term',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _searchResults.isNotEmpty 
                                        ? _searchResults.length 
                                        : _getPopularDestinations('').length,
                                    itemBuilder: (context, index) {
                                      final result = _searchResults.isNotEmpty 
                                          ? _searchResults[index]
                                          : _getPopularDestinations('')[index];
                                      final isPopular = _searchResults.isEmpty;
                                      
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[700]!,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          leading: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: _isSelectingPickup 
                                                  ? Colors.green.withValues(alpha: 0.2)
                                                  : Colors.red.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              isPopular
                                                  ? Icons.star_outline
                                                  : (_isSelectingPickup ? Icons.location_on : Icons.flag),
                                              color: _isSelectingPickup ? Colors.green : Colors.red,
                                              size: 18,
                                            ),
                                          ),
                                          title: Text(
                                            _getFirstLineOfAddress(result.address),
                                            style: const TextStyle(
                                              fontSize: 14, 
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Row(
                                            children: [
                                              if (isPopular) ...[
                                                Icon(Icons.trending_up, size: 12, color: Colors.orange),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Popular',
                                                  style: TextStyle(fontSize: 11, color: Colors.orange),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                                                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Colors.grey[400],
                                          ),
                                          onTap: () => _selectSearchResult(result),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Location selection toggle (moved below search)
          Positioned(
            top: _showSearchResults && _searchResults.isNotEmpty ? 280 : 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      label: const Text('Select Pickup', style: TextStyle(color: Colors.white)),
                      selected: _isSelectingPickup,
                      onSelected: (selected) {
                        setState(() {
                          _isSelectingPickup = true;
                          _searchResults = [];
                          _showSearchResults = false;
                          _searchController.clear();
                        });
                      },
                      selectedColor: Colors.green.withValues(alpha: 0.3),
                      backgroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey[700]!),
                      avatar: const Icon(Icons.location_on, size: 16, color: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChip(
                      label: const Text('Select Drop-off', style: TextStyle(color: Colors.white)),
                      selected: !_isSelectingPickup,
                      onSelected: (selected) {
                        setState(() {
                          _isSelectingPickup = false;
                          _searchResults = [];
                          _showSearchResults = false;
                          _searchController.clear();
                        });
                      },
                      selectedColor: Colors.red.withValues(alpha: 0.3),
                      backgroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey[700]!),
                      avatar: const Icon(Icons.flag, size: 16, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Route information panel with bottom padding
          Positioned(
            bottom: 100, // Add space for the confirm button
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickupAddress.isNotEmpty ? _pickupAddress : 'Select pickup location',
                          style: TextStyle(
                            fontWeight: _pickupLocation != null ? FontWeight.w500 : FontWeight.normal,
                            color: _pickupLocation != null ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dropoffAddress.isNotEmpty ? _dropoffAddress : 'Select destination',
                          style: TextStyle(
                            fontWeight: _dropoffLocation != null ? FontWeight.w500 : FontWeight.normal,
                            color: _dropoffLocation != null ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Route Info
                  if (_routeDistance > 0) ...[
                    Divider(color: Colors.grey[700]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.straighten, color: Color(0xFF0EA5E9), size: 16),
                            const SizedBox(height: 4),
                            Text(
                              _formatDistance(_routeDistance),
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF0EA5E9), size: 16),
                            const SizedBox(height: 4),
                            Text(
                              '$_routeDuration min',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ],
                        ),
                        if (_isCalculatingRoute)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                            ),
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.route, color: Color(0xFF0EA5E9), size: 16),
                              const SizedBox(height: 4),
                              Text(
                                _routePreference.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    // Route Preference Selector
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPreferenceChip('fastest', 'Fastest'),
                        _buildPreferenceChip('shortest', 'Shortest'),
                        _buildPreferenceChip('recommended', 'Best'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Confirm button at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Confirm Route',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
