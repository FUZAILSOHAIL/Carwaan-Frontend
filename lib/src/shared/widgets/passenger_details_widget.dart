import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';

class PassengerDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> rideInfo;
  final Map<String, dynamic> passengerDetails;
  final VoidCallback? onJoinRide;

  const PassengerDetailsWidget({
    super.key,
    required this.rideInfo,
    required this.passengerDetails,
    this.onJoinRide,
  });

  /// Helper method to format price with proper null safety and formatting
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

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final passengers = passengerDetails['passengers'] as List<dynamic>? ?? [];
    final totalPassengers = passengerDetails['total_passengers'] ?? 0;
    final availableSeats = passengerDetails['available_seats'] ?? 0;
    final genderBreakdown = passengerDetails['gender_breakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ride Information Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${rideInfo['pickup_location']} → ${rideInfo['dropoff_location']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text('${rideInfo['driver_name']}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${rideInfo['driver_rating']?.toStringAsFixed(1) ?? '0.0'}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text('${rideInfo['estimated_duration_minutes']} min'),
                      const SizedBox(width: 16),
                      const Icon(Icons.straighten, size: 16),
                      const SizedBox(width: 4),
                      Text('${rideInfo['estimated_distance_km']} km'),
                      const SizedBox(width: 16),
                      const Icon(Icons.attach_money, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'PKR ${_formatPrice(rideInfo['price_per_seat'])}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Seat Availability
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seat Availability',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        availableSeats > 0 ? Icons.event_seat : Icons.event_seat_outlined,
                        color: availableSeats > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$availableSeats seat(s) available',
                        style: TextStyle(
                          fontSize: 16,
                          color: availableSeats > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$totalPassengers passenger(s) already joined'),
                  
                  // Gender breakdown
                  if (genderBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (genderBreakdown['male'] > 0) ...[
                          const Icon(Icons.male, size: 16, color: Colors.blue),
                          Text(' ${genderBreakdown['male']}'),
                          const SizedBox(width: 16),
                        ],
                        if (genderBreakdown['female'] > 0) ...[
                          const Icon(Icons.female, size: 16, color: Colors.pink),
                          Text(' ${genderBreakdown['female']}'),
                          const SizedBox(width: 16),
                        ],
                        if (genderBreakdown['other'] > 0) ...[
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          Text(' ${genderBreakdown['other']}'),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Current Passengers
          if (passengers.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Passengers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...passengers.map((passenger) => _buildPassengerItem(passenger)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Gender Preferences Warning
          if (rideInfo['is_female_only'] == true && authController.currentUser.value?.gender != 'female') ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This is a female-only ride. Only female passengers can join.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Join Ride Button
          if (availableSeats > 0 && 
              !(rideInfo['is_female_only'] == true && authController.currentUser.value?.gender != 'female')) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onJoinRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Join Ride - PKR ${_formatPrice(rideInfo['price_per_seat'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else if (availableSeats == 0) ...[
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ride is Full',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerItem(Map<String, dynamic> passenger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Profile picture or avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: passenger['gender'] == 'female' 
                ? Colors.pink.shade100 
                : Colors.blue.shade100,
            backgroundImage: passenger['profile_picture'] != null 
                ? NetworkImage(passenger['profile_picture']) 
                : null,
            child: passenger['profile_picture'] == null
                ? Icon(
                    passenger['gender'] == 'female' ? Icons.female : Icons.male,
                    color: passenger['gender'] == 'female' ? Colors.pink : Colors.blue,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Passenger info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      passenger['gender'] == 'female' ? Icons.female : Icons.male,
                      size: 14,
                      color: passenger['gender'] == 'female' ? Colors.pink : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      passenger['gender']?.toString().capitalize ?? 'Unknown',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      passenger['rating']?.toStringAsFixed(1) ?? '0.0',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
