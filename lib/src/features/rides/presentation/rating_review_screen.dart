import 'package:flutter/material.dart';
import '../../../core/models/ride_models.dart';

class RatingReviewScreen extends StatefulWidget {
  final Ride ride;
  final String userRole; // 'driver' or 'passenger'
  
  const RatingReviewScreen({
    super.key,
    required this.ride,
    required this.userRole,
  });

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _positiveTags = [
    'بہترین ڈرائیونگ',
    'صاف گاڑی',
    'مہذب رفتار',
    'وقت کی پابندی',
    'بہترین رفتار',
    'اچھی گفتگو',
    'محفوظ سفر',
    'آرام دہ',
  ];

  final List<String> _negativeTags = [
    'دیر سے آئے',
    'تیز رفتاری',
    'گاڑی صاف نہیں',
    'بہت بات',
    'ایئر کنڈیشن خراب',
    'گاڑی کی آواز',
    'غیر محفوظ ڈرائیونگ',
    'رود ریج',
  ];

  @override
  Widget build(BuildContext context) {
    final targetUser = widget.userRole == 'driver' 
        ? 'مسافر' 
        : widget.ride.driver.fullName;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ریٹنگ اور ریویو'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سفر کی تفصیلات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text('سے: ${widget.ride.pickupLocation}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text('تک: ${widget.ride.dropoffLocation}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('کل کرایہ: ₨${widget.ride.calculatedFarePerPerson.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rating Section
            Text(
              '$targetUser کو ریٹنگ دیں',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Center(
              child: Column(
                children: [
                  if (widget.userRole == 'passenger')
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        widget.ride.driver.fullName[0],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  if (widget.userRole == 'passenger') const SizedBox(height: 8),
                  if (widget.userRole == 'passenger')
                    Text(
                      widget.ride.driver.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 16),
                  _buildStarRating(),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 16,
                      color: _getRatingColor(_rating),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tags Section
            const Text(
              'آپ کے تجربے کے بارے میں',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_rating >= 4) ...[
              Text('کیا اچھا لگا؟', style: TextStyle(color: Colors.green[700])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _positiveTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green[700],
                  );
                }).toList(),
              ),
            ] else if (_rating > 0) ...[
              Text('کیا مسئلہ تھا؟', style: TextStyle(color: Colors.red[700])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _negativeTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: Colors.red[100],
                    checkmarkColor: Colors.red[700],
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Review Text
            const Text(
              'تبصرہ (اختیاری)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'اپنا تجربہ شیئر کریں...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ریٹنگ جمع کریں',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.star,
              size: 40,
              color: index < _rating ? Colors.amber : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 0: return 'ریٹنگ دیں';
      case 1: return 'بہت خراب';
      case 2: return 'خراب';
      case 3: return 'ٹھیک ہے';
      case 4: return 'اچھا';
      case 5: return 'بہترین';
      default: return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 0: return Colors.grey;
      case 1:
      case 2: return Colors.red;
      case 3: return Colors.orange;
      case 4:
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  void _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Mock current user
      const currentUser = User(
        id: 1,
        fullName: 'Current User',
        email: 'current@example.com',
      );

      // Create rating object
      final rating = Rating(
        id: DateTime.now().millisecondsSinceEpoch,
        rater: currentUser,
        ratee: widget.userRole == 'driver' ? currentUser : widget.ride.driver,
        ride: widget.ride,
        rating: _rating,
        review: _reviewController.text.trim().isNotEmpty ? _reviewController.text.trim() : null,
        createdAt: DateTime.now(),
      );

      // Here you would send to API
      await Future.delayed(const Duration(seconds: 1)); // Mock API call
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('آپ کی ریٹنگ جمع ہو گئی'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Go back
        Navigator.pop(context, rating);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ایرر: ریٹنگ جمع نہیں ہو سکی'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
