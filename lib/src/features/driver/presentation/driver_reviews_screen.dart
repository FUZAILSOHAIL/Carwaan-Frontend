import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/controllers/auth_controller.dart';

class DriverReviewsScreen extends StatefulWidget {
  const DriverReviewsScreen({super.key});

  @override
  State<DriverReviewsScreen> createState() => _DriverReviewsScreenState();
}

class _DriverReviewsScreenState extends State<DriverReviewsScreen>
    with TickerProviderStateMixin {
  final ApiService apiService = Get.find<ApiService>();
  final MessageService messageService = Get.find<MessageService>();
  final AuthController authController = Get.find<AuthController>();

  late TabController _tabController;
  
  List<dynamic> _receivedReviews = [];
  List<dynamic> _givenReviews = [];
  Map<String, dynamic>? _reviewSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Reviews', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF87CEEB),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF87CEEB),
          tabs: const [
            Tab(text: 'Reviews Received'),
            Tab(text: 'Reviews Given'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB)))
          : Column(
              children: [
                // Review Summary Card
                if (_reviewSummary != null) _buildReviewSummary(),
                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReceivedReviewsTab(),
                      _buildGivenReviewsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReviewSummary() {
    final summary = _reviewSummary!;
    final averageRating = summary['average_rating']?.toDouble() ?? 0.0;
    final totalReviews = summary['total_reviews'] ?? 0;
    final ratingDistribution = summary['rating_distribution'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF87CEEB).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getRatingText(averageRating),
                        style: const TextStyle(
                          color: Color(0xFF87CEEB),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$totalReviews review${totalReviews != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStarRating(averageRating),
                  const SizedBox(height: 8),
                  Text(
                    'Driver Rating',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Rating Distribution
          const Text(
            'Rating Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = ratingDistribution['$rating'] ?? summary['${_getStarCountKey(rating)}'] ?? 0;
            final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    '$rating',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF87CEEB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : 
          index < rating ? Icons.star_half : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildReceivedReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: const Color(0xFF87CEEB),
      child: _receivedReviews.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No reviews received yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete rides to receive reviews',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _receivedReviews.length,
              itemBuilder: (context, index) {
                final review = _receivedReviews[index];
                return _buildReviewCard(review, isReceived: true);
              },
            ),
    );
  }

  Widget _buildGivenReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: const Color(0xFF87CEEB),
      child: _givenReviews.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No reviews given yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete rides and review passengers',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _givenReviews.length,
              itemBuilder: (context, index) {
                final review = _givenReviews[index];
                return _buildReviewCard(review, isReceived: false);
              },
            ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, {required bool isReceived}) {
    final overallRating = review['overall_rating'] ?? 0;
    final comment = review['comment'] ?? '';
    final createdAt = review['created_at_formatted'] ?? review['created_at'] ?? '';
    final rideRoute = review['ride_route'] ?? '';
    
    final otherPersonName = isReceived 
        ? review['reviewer_name'] ?? 'Unknown'
        : review['reviewee_name'] ?? 'Unknown';
    
    final otherPersonPicture = isReceived 
        ? review['reviewer_picture']
        : review['reviewee_picture'];

    // Additional ratings
    final punctualityRating = review['punctuality_rating'];
    final communicationRating = review['communication_rating'];
    final behaviorRating = review['behavior_rating'];
    final rideInfo = review['ride_info'] as Map<String, dynamic>? ?? {};

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF87CEEB),
                  backgroundImage: otherPersonPicture != null 
                      ? NetworkImage(otherPersonPicture)
                      : null,
                  child: otherPersonPicture == null 
                      ? Text(
                          otherPersonName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherPersonName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rideRoute.isNotEmpty ? rideRoute : 'Ride completed',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(overallRating.toDouble()),
              ],
            ),
            
            // Ride Info
            if (rideInfo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route, color: Color(0xFF87CEEB), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${rideInfo['pickup_location'] ?? ''} → ${rideInfo['dropoff_location'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Detailed Ratings
            if (punctualityRating != null || communicationRating != null || behaviorRating != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (punctualityRating != null)
                    _buildMiniRating('Punctuality', punctualityRating),
                  if (communicationRating != null)
                    _buildMiniRating('Communication', communicationRating),
                  if (behaviorRating != null)
                    _buildMiniRating('Behavior', behaviorRating),
                ],
              ),
            ],
            
            // Comment
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isReceived)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Received',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Given',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMiniRating(String label, int rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 12,
              color: index < rating ? Colors.amber : Colors.grey[600],
            );
          }),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Average';
    if (rating >= 2.0) return 'Below Average';
    return 'Poor';
  }

  String _getStarCountKey(int rating) {
    switch (rating) {
      case 5: return 'five_star_count';
      case 4: return 'four_star_count';
      case 3: return 'three_star_count';
      case 2: return 'two_star_count';
      case 1: return 'one_star_count';
      default: return 'one_star_count';
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime).inDays;
      
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Yesterday';
      if (difference < 7) return '${difference}d ago';
      if (difference < 30) return '${(difference / 7).floor()}w ago';
      if (difference < 365) return '${(difference / 30).floor()}mo ago';
      return '${(difference / 365).floor()}y ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load received reviews
      _receivedReviews = await apiService.getMyReceivedReviews();

      // Load given reviews  
      _givenReviews = await apiService.getMyGivenReviews();

      // Load review summary if user ID is available
      final userId = authController.currentUser.value?.id;
      if (userId != null) {
        try {
          _reviewSummary = await apiService.getUserReviewSummary(userId);
        } catch (e) {
          // If summary fails, continue without it
          debugPrint('Failed to load review summary: $e');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      messageService.showError('Failed to load reviews: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
