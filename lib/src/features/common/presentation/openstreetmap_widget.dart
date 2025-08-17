import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

class OpenStreetMapWidget extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final List<LatLng>? markers;
  final Function(LatLng)? onTap;
  final String? title;
  final bool showCurrentLocationButton;

  const OpenStreetMapWidget({
    super.key,
    required this.center,
    this.zoom = 13.0,
    this.markers,
    this.onTap,
    this.title,
    this.showCurrentLocationButton = true,
  });

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  late MapController _mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: [
                if (_selectedLocation != null)
                  TextButton(
                    onPressed: () {
                      Get.back(result: _selectedLocation);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            )
          : null,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: widget.zoom,
              onTap: widget.onTap != null
                  ? (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                      widget.onTap!(point);
                    }
                  : null,
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carwaan.app',
                maxZoom: 19,
              ),
              
              // Markers layer
              if (widget.markers != null || _selectedLocation != null)
                MarkerLayer(
                  markers: [
                    // Original markers
                    if (widget.markers != null)
                      ...widget.markers!.map((point) => Marker(
                        width: 40,
                        height: 40,
                        point: point,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      )),
                    
                    // Selected location marker
                    if (_selectedLocation != null)
                      Marker(
                        width: 40,
                        height: 40,
                        point: _selectedLocation!,
                        child: const Icon(
                          Icons.place,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Current location button
          if (widget.showCurrentLocationButton)
            Positioned(
              right: 16,
              bottom: 80,
              child: FloatingActionButton(
                mini: true,
                onPressed: _goToCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
            ),

          // Map type button
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton(
              mini: true,
              onPressed: _showMapTypeDialog,
              child: const Icon(Icons.layers),
            ),
          ),

          // Instructions overlay
          if (widget.onTap != null && _selectedLocation == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tap on the map to select a location',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToCurrentLocation() {
    // Move to Karachi (default location for Pakistan)
    const karachi = LatLng(24.8607, 67.0011);
    _mapController.move(karachi, 13.0);
    
    // TODO: Get actual current location using geolocator
    Get.snackbar(
      'Location',
      'Showing approximate location. Enable GPS for precise location.',
      duration: const Duration(seconds: 3),
    );
  }

  void _showMapTypeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Standard Map'),
            onTap: () {
              Navigator.pop(context);
              // Standard OSM is already loaded
            },
          ),
          ListTile(
            leading: const Icon(Icons.satellite),
            title: const Text('Satellite'),
            onTap: () {
              Navigator.pop(context);
              Get.snackbar(
                'Info',
                'Satellite view is available with premium map services',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.terrain),
            title: const Text('Terrain'),
            onTap: () {
              Navigator.pop(context);
              Get.snackbar(
                'Info',
                'Terrain view is available with premium map services',
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// Simple map viewer for display only
class SimpleMapViewer extends StatelessWidget {
  final LatLng location;
  final String? title;
  final double zoom;

  const SimpleMapViewer({
    super.key,
    required this.location,
    this.title,
    this.zoom = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: location,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Disable interactions for preview
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carwaan.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: location,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
            if (title != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
