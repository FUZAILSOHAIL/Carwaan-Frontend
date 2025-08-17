import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';

class PassengerReviewsScreen extends StatefulWidget {
  const PassengerReviewsScreen({super.key});

  @override
  State<PassengerReviewsScreen> createState() => _PassengerReviewsScreenState();
}

class _PassengerReviewsScreenState extends State<PassengerReviewsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = Get.find<ApiService>();
  final MessageService messageService = Get.find<MessageService>();

  late TabController _tabController;
  
  List<Map<String, dynamic>> _receivedReviews = [];
  List<Map<String, dynamic>> _givenReviews = [];
  Map<String, dynamic> _reviewSummary = {};
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
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF87CEEB),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF87CEEB),
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Given'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF87CEEB)),
              ),
            )
          : Column(
              children: [
                // Review Summary Card
                if (_reviewSummary.isNotEmpty) _buildReviewSummaryCard(),
                
                // Tab Content
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

  Widget _buildReviewSummaryCard() {
    final averageRating = _reviewSummary['average_rating']?.toDouble() ?? 0.0;
    final totalReviews = _reviewSummary['total_reviews'] ?? 0;
    final ratingDistribution = _reviewSummary['rating_distribution'] as Map<String, dynamic>? ?? {};

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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ],
                  ),
                  Text(
                    '$totalReviews reviews',
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
                    _getRatingText(averageRating),
                    style: const TextStyle(
                      color: Color(0xFF87CEEB),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
            final count = ratingDistribution['$rating'] ?? 0;
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
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF87CEEB)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.end,
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
                    Icons.star_border,
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
                    'Complete some rides to receive reviews',
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
                    Icons.rate_review_outlined,
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
                    'Rate your drivers after completing rides',
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
    final rating = review['overall_rating'] ?? 0;
    final comment = review['comment'] ?? '';
    final reviewerName = isReceived 
        ? (review['reviewer_name'] ?? 'Anonymous Driver')
        : (review['reviewee_name'] ?? 'Anonymous Driver');
    final rideInfo = review['ride_info'] as Map<String, dynamic>? ?? {};
    final createdAt = review['created_at'] ?? '';
    
    // Additional ratings
    final punctualityRating = review['punctuality_rating'];
    final communicationRating = review['communication_rating'];
    final behaviorRating = review['behavior_rating'];
    
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
                  child: Text(
                    reviewerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(rating.toDouble()),
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
                        '${rideInfo['pickup_location'] ?? 'Unknown'} → ${rideInfo['dropoff_location'] ?? 'Unknown'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
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

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 16,
          color: index < rating ? Colors.amber : Colors.grey[600],
        );
      }),
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
      final receivedResponse = await apiService.getReceivedReviews();
      _receivedReviews = List<Map<String, dynamic>>.from(receivedResponse['results'] ?? []);

      // Load given reviews
      final givenResponse = await apiService.getGivenReviews();
      _givenReviews = List<Map<String, dynamic>>.from(givenResponse['results'] ?? []);

      // Load review summary
      final summaryResponse = await apiService.getUserReviewSummary();
      _reviewSummary = summaryResponse;

    } catch (e) {
      messageService.showError('Failed to load reviews: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
