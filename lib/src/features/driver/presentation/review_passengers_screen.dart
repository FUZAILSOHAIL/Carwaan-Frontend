import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';

class ReviewPassengersScreen extends StatefulWidget {
  const ReviewPassengersScreen({super.key});

  @override
  State<ReviewPassengersScreen> createState() => _ReviewPassengersScreenState();
}

class _ReviewPassengersScreenState extends State<ReviewPassengersScreen> {
  final ApiService apiService = Get.find<ApiService>();
  final MessageService messageService = Get.find<MessageService>();

  late int rideId;
  late List<dynamic> passengers;
  int currentPassengerIndex = 0;
  bool isSubmitting = false;

  // Review form fields
  int overallRating = 5;
  int punctualityRating = 5;
  int communicationRating = 5;
  int behaviorRating = 5;
  bool wouldRideAgain = true;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    rideId = args['rideId'] as int;
    passengers = args['passengers'] as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    if (passengers.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Review Passengers', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'All passengers reviewed!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final currentPassenger = passengers[currentPassengerIndex];
    final totalPassengers = passengers.length;
    final currentProgress = currentPassengerIndex + 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Review Passengers ($currentProgress/$totalPassengers)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: currentProgress / totalPassengers,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF87CEEB)),
            ),
            const SizedBox(height: 24),

            // Passenger info card
            _buildPassengerCard(currentPassenger),
            const SizedBox(height: 24),

            // Rating sections
            _buildRatingSection('Overall Rating', overallRating, (rating) {
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

            _buildRatingSection('Behavior', behaviorRating, (rating) {
              setState(() => behaviorRating = rating);
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
                      'Would you ride with this passenger again?',
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
                hintText: 'Share your experience with this passenger...',
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

            // Action buttons
            Row(
              children: [
                if (currentPassengerIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPassenger,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (currentPassengerIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF87CEEB),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        : Text(
                            currentPassengerIndex == totalPassengers - 1
                                ? 'Submit Review'
                                : 'Next Passenger',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(Map<String, dynamic> passenger) {
    final name = passenger['name'] ?? 'Unknown';
    final profilePicture = passenger['profile_picture'];
    final gender = passenger['gender'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF87CEEB).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF87CEEB),
            backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
            child: profilePicture == null 
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
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
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (gender.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    gender.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                  size: 32,
                  color: starRating <= rating ? Colors.amber : Colors.grey[600],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _previousPassenger() {
    if (currentPassengerIndex > 0) {
      setState(() {
        currentPassengerIndex--;
        _resetForm();
      });
    }
  }

  void _resetForm() {
    overallRating = 5;
    punctualityRating = 5;
    communicationRating = 5;
    behaviorRating = 5;
    wouldRideAgain = true;
    commentController.clear();
  }

  Future<void> _submitReview() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final currentPassenger = passengers[currentPassengerIndex];

      await apiService.createDetailedReview(
        rideId: rideId,
        revieweeId: currentPassenger['id'],
        rating: overallRating,
        comment: commentController.text.trim(),
        punctualityRating: punctualityRating,
        communicationRating: communicationRating,
        safetyRating: behaviorRating,
        cleanlinessRating: behaviorRating,
      );

      messageService.showSuccess('Review submitted successfully');

      // Move to next passenger or finish
      if (currentPassengerIndex < passengers.length - 1) {
        setState(() {
          currentPassengerIndex++;
          _resetForm();
        });
      } else {
        // All passengers reviewed, go back to driver dashboard reviews tab
        Get.offNamed('/driver-dashboard', arguments: {'initialTabIndex': 3}); // Tab index 3 is Reviews
        messageService.showSuccess('All passenger reviews completed!');
      }
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
