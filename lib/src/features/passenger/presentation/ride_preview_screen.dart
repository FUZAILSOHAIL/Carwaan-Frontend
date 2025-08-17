import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/passenger_details_widget.dart';

class RidePreviewScreen extends StatefulWidget {
  final int rideId;

  const RidePreviewScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<RidePreviewScreen> createState() => _RidePreviewScreenState();
}

class _RidePreviewScreenState extends State<RidePreviewScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  
  bool _isLoading = true;
  Map<String, dynamic>? _rideData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRideDetails();
  }

  Future<void> _loadRideDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.getRidePassengerDetails(widget.rideId);
      
      setState(() {
        _rideData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading ride details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRide() async {
    try {
      // Validate that we have the required location data
      final pickupLocation = _rideData?['ride_info']?['pickup_location'];
      final dropoffLocation = _rideData?['ride_info']?['dropoff_location'];
      final pickupLat = _rideData?['ride_info']?['pickup_latitude'];
      final pickupLng = _rideData?['ride_info']?['pickup_longitude'];
      final dropoffLat = _rideData?['ride_info']?['dropoff_latitude'];
      final dropoffLng = _rideData?['ride_info']?['dropoff_longitude'];

      if (pickupLocation == null || dropoffLocation == null) {
        Get.snackbar(
          'Error',
          'Unable to get ride location details. Please try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await _showJoinConfirmationDialog();
      if (!confirmed) return;

      // Show loading dialog
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sending ride request...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Use the ride request API (not join) - same as passenger dashboard
      await _apiService.createRideRequest(
        rideId: widget.rideId,
        pickupLocation: pickupLocation.toString(),
        dropoffLocation: dropoffLocation.toString(),
        pickupLatitude: double.tryParse(pickupLat?.toString() ?? '0') ?? 0.0,
        pickupLongitude: double.tryParse(pickupLng?.toString() ?? '0') ?? 0.0,
        dropoffLatitude: double.tryParse(dropoffLat?.toString() ?? '0') ?? 0.0,
        dropoffLongitude: double.tryParse(dropoffLng?.toString() ?? '0') ?? 0.0,
        message: 'Hi, I would like to join your ride from the ride details page.',
      );

      Get.back(); // Close loading dialog

      // If we get here without exception, request was successful
      Get.snackbar(
        'Success',
        'Ride request sent successfully! The driver will review your request.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      
      // Navigate back to passenger dashboard and show requests tab
      Get.offAllNamed('/passenger-dashboard');
    } catch (e) {
      Get.back(); // Close loading dialog if open
      
      // Handle specific error messages
      String errorMessage = 'Failed to send ride request: $e';
      if (e.toString().contains('404')) {
        errorMessage = 'Ride not found or no longer available.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Invalid request. Please check ride details and try again.';
      } else if (e.toString().contains('already')) {
        errorMessage = 'You have already requested to join this ride.';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<bool> _showJoinConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Request to Join Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to send a request to join this ride?'),
            const SizedBox(height: 8),
            const Text(
              'The driver will review your request and respond accordingly.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (_rideData != null) ...[
              Text(
                'Cost: PKR ${_formatPrice(_rideData!['ride_info']['price_per_seat'])}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              Text(
                'Duration: ${(_rideData!['ride_info']['estimated_duration_minutes'] ?? 0).toString()} minutes',
              ),
              Text(
                'Distance: ${(_rideData!['ride_info']['estimated_distance_km'] ?? 0.0).toStringAsFixed(2)} km',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading ride details...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRideDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_rideData == null) {
      return const Center(
        child: Text('No ride data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRideDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PassengerDetailsWidget(
          rideInfo: _rideData!['ride_info'] ?? {},
          passengerDetails: _rideData!['passenger_details'] ?? {},
          onJoinRide: _joinRide,
        ),
      ),
    );
  }

  /// Format price with proper null safety and number formatting
  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    
    // If it's already a string, try to parse it
    if (price is String) {
      final parsed = double.tryParse(price);
      if (parsed != null) {
        return parsed.toStringAsFixed(0); // Remove decimal places for whole numbers
      }
      return price; // Return as-is if can't parse
    }
    
    // If it's a number, format it
    if (price is num) {
      return price.toStringAsFixed(price % 1 == 0 ? 0 : 2); // No decimals for whole numbers, 2 for decimals
    }
    
    return price.toString();
  }
}
