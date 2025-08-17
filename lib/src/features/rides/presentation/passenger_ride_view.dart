import 'package:flutter/material.dart';
import '../../../core/models/ride_models.dart';
import '../../../core/models/location_model.dart';
import '../../../core/services/fare_service.dart';
import '../../../shared/widgets/fare_breakdown_card.dart';

class PassengerRideView extends StatefulWidget {
  final LocationData userLocation;
  final LocationData destination;
  
  const PassengerRideView({
    super.key,
    required this.userLocation,
    required this.destination,
  });

  @override
  State<PassengerRideView> createState() => _PassengerRideViewState();
}

class _PassengerRideViewState extends State<PassengerRideView> {
  final FareCalculationService _fareService = FareCalculationService.instance;
  List<Ride> availableRides = [];
  bool isLoading = true;
  String? selectedGender;
  bool isPeakHour = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  void _loadAvailableRides() {
    // Mock data - replace with API call
    setState(() {
      availableRides = [
        Ride(
          id: 1,
          driver: const User(
            id: 1,
            fullName: 'احمد علی',
            email: 'ahmed@example.com',
            phone: '+92300-1234567',
            averageRating: 4.8,
            totalRatings: 150,
          ),
          pickupLocation: 'گلشن اقبال، کراچی',
          dropoffLocation: widget.destination.address,
          pickupLatitude: 24.8607,
          pickupLongitude: 67.0011,
          dropoffLatitude: widget.destination.latitude,
          dropoffLongitude: widget.destination.longitude,
          departureTime: DateTime.now().add(const Duration(minutes: 15)),
          totalSeats: 4,
          availableSeats: 3,
          status: 'active',
          genderPreference: 'mixed',
          estimatedDistanceKm: 15.0,
          isPeakHours: isPeakHour,
          calculatedFarePerPerson: 250.0,
          totalFare: 1000.0,
        ),
        Ride(
          id: 2,
          driver: const User(
            id: 2,
            fullName: 'فاطمہ خان',
            email: 'fatima@example.com',
            phone: '+92301-9876543',
            averageRating: 4.9,
            totalRatings: 200,
            gender: 'female',
          ),
          pickupLocation: 'گلشن معمار، کراچی',
          dropoffLocation: widget.destination.address,
          pickupLatitude: 24.8570,
          pickupLongitude: 67.0320,
          dropoffLatitude: widget.destination.latitude,
          dropoffLongitude: widget.destination.longitude,
          departureTime: DateTime.now().add(const Duration(minutes: 25)),
          totalSeats: 4,
          availableSeats: 2,
          status: 'active',
          genderPreference: 'female_only',
          estimatedDistanceKm: 12.0,
          isPeakHours: isPeakHour,
          calculatedFarePerPerson: 200.0,
          totalFare: 800.0,
        ),
        Ride(
          id: 3,
          driver: const User(
            id: 3,
            fullName: 'محمد حسن',
            email: 'hassan@example.com',
            phone: '+92302-5647382',
            averageRating: 4.7,
            totalRatings: 120,
            gender: 'male',
          ),
          pickupLocation: 'ملیر، کراچی',
          dropoffLocation: widget.destination.address,
          pickupLatitude: 24.8485,
          pickupLongitude: 67.0295,
          dropoffLatitude: widget.destination.latitude,
          dropoffLongitude: widget.destination.longitude,
          departureTime: DateTime.now().add(const Duration(minutes: 30)),
          totalSeats: 7,
          availableSeats: 5,
          status: 'active',
          genderPreference: 'male_only',
          estimatedDistanceKm: 18.0,
          isPeakHours: isPeakHour,
          calculatedFarePerPerson: 350.0,
          totalFare: 2450.0,
        ),
      ];
      isLoading = false;
    });
  }

  void _requestRide(Ride ride) {
    final fareBreakdown = _fareService.calculateFare(
      distanceKm: ride.estimatedDistanceKm,
      departureTime: ride.departureTime,
      confirmedPassengers: 1,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سواری کی درخواست'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ڈرائیور: ${ride.driver.fullName}'),
            const SizedBox(height: 8),
            Text('روانگی: ${_formatTime(ride.departureTime)}'),
            const SizedBox(height: 8),
            Text('کرایہ: ₨${ride.calculatedFarePerPerson.toStringAsFixed(0)} فی شخص'),
            const SizedBox(height: 16),
            FareBreakdownCard(
              fareBreakdown: fareBreakdown,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('منسوخ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendRideRequest(ride);
            },
            child: const Text('درخواست بھیجیں'),
          ),
        ],
      ),
    );
  }

  void _sendRideRequest(Ride ride) {
    // Implement API call to send ride request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ride.driver.fullName} کو درخواست بھیج دی گئی'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} منٹ میں';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')} بجے';
    }
  }

  Widget _buildGenderFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جنس کی ترجیح',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String?>(
                  title: const Text('تمام'),
                  value: null,
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('صرف خواتین'),
                  value: 'female_only',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('صرف مرد'),
                  value: 'male_only',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Ride> get filteredRides {
    if (selectedGender == null) return availableRides;
    return availableRides
        .where((ride) => ride.genderPreference == selectedGender || ride.genderPreference == 'mixed')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دستیاب سواریاں'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: isPeakHour,
            onChanged: (value) {
              setState(() {
                isPeakHour = value;
                // Recalculate fares based on peak hour
                _loadAvailableRides();
              });
            },
          ),
          const Text('پیک آور'),
          const SizedBox(width: 16),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGenderFilter(),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredRides.length,
                    itemBuilder: (context, index) {
                      final ride = filteredRides[index];
                      return _buildRideCard(ride);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(ride.driver.fullName[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driver.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${ride.driver.averageRating}'),
                          const SizedBox(width: 8),
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          Text(' ${ride.driver.phone}'),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGenderColor(ride.genderPreference),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getGenderText(ride.genderPreference),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Pickup & Destination
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text('سے: ${ride.pickupLocation}')),
                      Text('${ride.availableSeats}/${ride.totalSeats} سیٹس'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text('تک: ${ride.dropoffLocation}')),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Time & Distance
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange),
                const SizedBox(width: 8),
                Text('روانگی: ${_formatTime(ride.departureTime)}'),
                const Spacer(),
                Text('فاصلہ: ${ride.estimatedDistanceKm.toStringAsFixed(1)} کلومیٹر'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Fare
            Row(
              children: [
                if (ride.isPeakHours)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'پیک آور',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                if (ride.isPeakHours) const SizedBox(width: 8),
                const Spacer(),
                Text(
                  '₨${ride.calculatedFarePerPerson.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Request Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ride.availableSeats > 0 ? () => _requestRide(ride) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  ride.availableSeats > 0 ? 'سواری کی درخواست' : 'سیٹ دستیاب نہیں',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenderColor(String preference) {
    switch (preference) {
      case 'female_only':
        return Colors.pink;
      case 'male_only':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _getGenderText(String preference) {
    switch (preference) {
      case 'female_only':
        return 'خواتین';
      case 'male_only':
        return 'مرد';
      default:
        return 'مخلوط';
    }
  }
}
