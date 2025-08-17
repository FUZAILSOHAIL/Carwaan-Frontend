import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';

class RateRideDialog extends StatefulWidget {
  final Map<String, dynamic> ride;
  final String revieweeId;
  final String revieweeName;
  final String reviewType; // 'passenger_to_driver' or 'driver_to_passenger'

  const RateRideDialog({
    super.key,
    required this.ride,
    required this.revieweeId,
    required this.revieweeName,
    required this.reviewType,
  });

  @override
  State<RateRideDialog> createState() => _RateRideDialogState();
}

class _RateRideDialogState extends State<RateRideDialog> {
  final ApiService _apiService = Get.find<ApiService>();
  final TextEditingController _commentController = TextEditingController();
  
  int _rating = 0;
  int _punctualityRating = 5;
  int _cleanlinessRating = 5;
  int _communicationRating = 5;
  int _safetyRating = 5;
  bool _isSubmitting = false;
  String _errorMessage = '';
  bool _showDetailedRatings = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Please select a rating';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      debugPrint('🌐 Submitting enhanced review via API...');
      
      // Use the new detailed review API if detailed ratings are shown
      if (_showDetailedRatings) {
        await _apiService.createDetailedReview(
          rideId: widget.ride['id'],
          revieweeId: int.parse(widget.revieweeId),
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          punctualityRating: _punctualityRating,
          cleanlinessRating: _cleanlinessRating,
          communicationRating: _communicationRating,
          safetyRating: _safetyRating,
        );
      } else {
        // Use the simple rate ride API for basic reviews
        await _apiService.rateRide(
          widget.ride['id'], 
          _rating, 
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        );
      }

      debugPrint('✅ Review submitted successfully');
      Get.find<MessageService>().showSuccess('Review submitted successfully!');
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('❌ Error submitting review: $e');
      setState(() {
        _errorMessage = 'Failed to submit review. Please try again.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRatingDriver = widget.reviewType == 'passenger_to_driver';
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isRatingDriver ? Icons.drive_eta : Icons.person,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate ${isRatingDriver ? 'Driver' : 'Passenger'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.revieweeName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Ride info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.ride['pickup_location'] ?? 'Unknown'} → ${widget.ride['dropoff_location'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rating stars
            const Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _rating >= starIndex ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),

            // Toggle for detailed ratings
            if (widget.reviewType == 'passenger_to_driver') ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  setState(() {
                    _showDetailedRatings = !_showDetailedRatings;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showDetailedRatings ? Icons.expand_less : Icons.expand_more,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showDetailedRatings ? 'Hide Detailed Ratings' : 'Show Detailed Ratings',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Detailed ratings section
            if (_showDetailedRatings) ...[
              const SizedBox(height: 20),
              const Text(
                'Rate specific aspects:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildDetailedRatingRow(
                'Punctuality',
                Icons.schedule,
                _punctualityRating,
                (rating) => setState(() => _punctualityRating = rating),
              ),
              
              _buildDetailedRatingRow(
                'Cleanliness',
                Icons.cleaning_services,
                _cleanlinessRating,
                (rating) => setState(() => _cleanlinessRating = rating),
              ),
              
              _buildDetailedRatingRow(
                'Communication',
                Icons.chat_bubble_outline,
                _communicationRating,
                (rating) => setState(() => _communicationRating = rating),
              ),
              
              _buildDetailedRatingRow(
                'Safety',
                Icons.shield_outlined,
                _safetyRating,
                (rating) => setState(() => _safetyRating = rating),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Comment field
            const Text(
              'Leave a comment (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: isRatingDriver 
                    ? 'How was the driving? Was the driver punctual and polite?'
                    : 'How was the passenger? Were they respectful and on time?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
            ),
            
            // Error message
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatingRow(
    String title,
    IconData icon,
    int rating,
    Function(int) onRatingChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    rating >= starIndex ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
