import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';

class ReviewDriverScreen extends StatefulWidget {
  const ReviewDriverScreen({super.key});

  @override
  State<ReviewDriverScreen> createState() => _ReviewDriverScreenState();
}

class _ReviewDriverScreenState extends State<ReviewDriverScreen> {
  final ApiService apiService = Get.find<ApiService>();
  final MessageService messageService = Get.find<MessageService>();

  late int rideId;
  late Map<String, dynamic> driverInfo;
  late Map<String, dynamic> rideInfo;
  bool isSubmitting = false;

  // Review form fields
  int overallRating = 5;
  int punctualityRating = 5;
  int communicationRating = 5;
  int safetyRating = 5;
  int cleanlinessRating = 5;
  bool wouldRideAgain = true;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    rideId = args['rideId'] as int;
    driverInfo = args['driverInfo'] as Map<String, dynamic>;
    rideInfo = args['rideInfo'] as Map<String, dynamic>? ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Rate Driver', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info card
            _buildDriverCard(),
            const SizedBox(height: 24),

            // Ride info card
            if (rideInfo.isNotEmpty) _buildRideInfoCard(),
            const SizedBox(height: 24),

            // Rating sections
            _buildRatingSection('Overall Experience', overallRating, (rating) {
              setState(() => overallRating = rating);
            }),
            const SizedBox(height: 16),

            _buildRatingSection('Punctuality', punctualityRating, (rating) {
              setState(() => punctualityRating = rating);
            }),
            const SizedBox(height: 16),

            _buildRatingSection('Communication', communicationRating, (rating) {
              setState(() => communicationRating = rating);
            }),
            const SizedBox(height: 16),

            _buildRatingSection('Safety', safetyRating, (rating) {
              setState(() => safetyRating = rating);
            }),
            const SizedBox(height: 16),

            _buildRatingSection('Vehicle Cleanliness', cleanlinessRating, (rating) {
              setState(() => cleanlinessRating = rating);
            }),
            const SizedBox(height: 24),

            // Would ride again toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Would you ride with this driver again?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: wouldRideAgain,
                    onChanged: (value) {
                      setState(() => wouldRideAgain = value);
                    },
                    activeColor: const Color(0xFF87CEEB),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comment section
            const Text(
              'Additional Comments (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share your experience with this driver...',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF87CEEB)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87CEEB),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    final driverName = driverInfo['name'] ?? driverInfo['first_name'] ?? 'Unknown Driver';
    final profilePicture = driverInfo['profile_picture'];
    final driverRating = driverInfo['rating']?.toDouble() ?? 0.0;
    final totalRides = driverInfo['total_rides'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF87CEEB).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF87CEEB),
            backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
            child: profilePicture == null 
                ? Text(
                    driverName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      driverRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$totalRides rides',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'RIDE COMPLETED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfoCard() {
    final pickupLocation = rideInfo['pickup_location'] ?? 'Unknown';
    final dropoffLocation = rideInfo['dropoff_location'] ?? 'Unknown';
    final departureTime = rideInfo['departure_time'] ?? '';
    final fare = rideInfo['fare']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.my_location, color: Color(0xFF87CEEB), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickupLocation,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dropoffLocation,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          if (departureTime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(departureTime),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
          if (fare != '0') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'PKR $fare',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection(String title, int rating, Function(int) onRatingChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final starRating = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starRating),
                child: Icon(
                  Icons.star,
                  size: 36,
                  color: starRating <= rating ? Colors.amber : Colors.grey[600],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(rating),
              style: TextStyle(
                color: _getRatingColor(rating),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5: return 'Excellent';
      case 4: return 'Good';
      case 3: return 'Average';
      case 2: return 'Poor';
      case 1: return 'Very Poor';
      default: return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5: return Colors.green;
      case 4: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 2: return Colors.deepOrange;
      case 1: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Future<void> _submitReview() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      await apiService.createDetailedReview(
        rideId: rideId,
        revieweeId: driverInfo['id'],
        rating: overallRating,
        comment: commentController.text.trim(),
        punctualityRating: punctualityRating,
        communicationRating: communicationRating,
        safetyRating: safetyRating,
        cleanlinessRating: cleanlinessRating,
      );

      messageService.showSuccess('Review submitted successfully!');
      Get.back(result: true); // Return true to indicate successful submission
    } catch (e) {
      messageService.showError('Failed to submit review: $e');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
