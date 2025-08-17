import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';

class ReviewsScreen extends StatefulWidget {
  final String? rideId;
  final String? userId;
  final String title;

  const ReviewsScreen({
    super.key,
    this.rideId,
    this.userId,
    this.title = 'Reviews',
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> with TickerProviderStateMixin {
  final ApiService _apiService = Get.find<ApiService>();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _receivedReviews = [];
  List<Map<String, dynamic>> _givenReviews = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Stats
  double _averageReceivedRating = 0.0;
  int _totalReceivedReviews = 0;
  double _averageGivenRating = 0.0;
  int _totalGivenReviews = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('🔄 Loading reviews...');
      
      // Load received reviews (reviews about the user)
      await _loadReceivedReviews();
      
      // Load given reviews (reviews the user has written)
      await _loadGivenReviews();
      
      _calculateStats();
      
    } catch (e) {
      debugPrint('❌ Error loading reviews: $e');
      setState(() {
        _errorMessage = 'Failed to load reviews: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReceivedReviews() async {
    try {
      final response = widget.userId != null 
          ? await _apiService.get('/reviews/user/${widget.userId}/received/')
          : await _apiService.get('/reviews/my-received/');
      
      if (response.statusCode == 200) {
        _receivedReviews = List<Map<String, dynamic>>.from(response.data);
        debugPrint('✅ Loaded ${_receivedReviews.length} received reviews');
      }
    } catch (e) {
      debugPrint('❌ Error loading received reviews: $e');
      _receivedReviews = _getMockReceivedReviews();
    }
  }

  Future<void> _loadGivenReviews() async {
    try {
      final response = widget.userId != null 
          ? await _apiService.get('/reviews/user/${widget.userId}/given/')
          : await _apiService.get('/reviews/my-given/');
      
      if (response.statusCode == 200) {
        _givenReviews = List<Map<String, dynamic>>.from(response.data);
        debugPrint('✅ Loaded ${_givenReviews.length} given reviews');
      }
    } catch (e) {
      debugPrint('❌ Error loading given reviews: $e');
      _givenReviews = _getMockGivenReviews();
    }
  }

  void _calculateStats() {
    // Calculate received reviews stats
    if (_receivedReviews.isNotEmpty) {
      _totalReceivedReviews = _receivedReviews.length;
      double totalRating = 0;
      for (var review in _receivedReviews) {
        totalRating += (review['rating'] ?? 0).toDouble();
      }
      _averageReceivedRating = totalRating / _totalReceivedReviews;
    }

    // Calculate given reviews stats
    if (_givenReviews.isNotEmpty) {
      _totalGivenReviews = _givenReviews.length;
      double totalRating = 0;
      for (var review in _givenReviews) {
        totalRating += (review['rating'] ?? 0).toDouble();
      }
      _averageGivenRating = totalRating / _totalGivenReviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Received',
              icon: const Icon(Icons.thumb_up_outlined),
            ),
            Tab(
              text: 'Given',
              icon: const Icon(Icons.rate_review_outlined),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceivedReviewsTab(),
                    _buildGivenReviewsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Reviews',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReviews,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedReviewsTab() {
    return Column(
      children: [
        // Stats header
        _buildStatsHeader(
          title: 'Reviews About You',
          averageRating: _averageReceivedRating,
          totalReviews: _totalReceivedReviews,
        ),
        
        // Reviews list
        Expanded(
          child: _receivedReviews.isEmpty
              ? _buildEmptyState('No reviews received yet')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _receivedReviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = _receivedReviews[index];
                    return _buildReviewCard(review, isReceived: true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGivenReviewsTab() {
    return Column(
      children: [
        // Stats header
        _buildStatsHeader(
          title: 'Reviews You\'ve Given',
          averageRating: _averageGivenRating,
          totalReviews: _totalGivenReviews,
        ),
        
        // Reviews list
        Expanded(
          child: _givenReviews.isEmpty
              ? _buildEmptyState('No reviews given yet')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _givenReviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = _givenReviews[index];
                    return _buildReviewCard(review, isReceived: false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader({
    required String title,
    required double averageRating,
    required int totalReviews,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.star,
                value: totalReviews > 0 ? averageRating.toStringAsFixed(1) : '--',
                label: 'Average Rating',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.reviews,
                value: totalReviews.toString(),
                label: 'Total Reviews',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, {required bool isReceived}) {
    final rating = (review['rating'] ?? 0).toDouble();
    final reviewerName = isReceived 
        ? (review['reviewer_name'] ?? review['reviewer']?['name'] ?? 'Anonymous')
        : (review['reviewee_name'] ?? review['reviewee']?['name'] ?? 'Anonymous');
    final comment = review['comment'] ?? review['review_text'] ?? '';
    final createdAt = review['created_at'] ?? review['date'];
    final rideInfo = review['ride'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with reviewer info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRatingStars(rating),
              ],
            ),
            
            // Comment
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            
            // Ride info
            if (rideInfo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.route, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${rideInfo['pickup_location'] ?? 'Unknown'} → ${rideInfo['dropoff_location'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 16,
        );
      }),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.reviews_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  // Mock data for testing
  List<Map<String, dynamic>> _getMockReceivedReviews() {
    return [
      {
        'id': '1',
        'reviewer_name': 'Ahmed Ali',
        'rating': 5,
        'comment': 'Excellent driver! Very punctual and safe driving.',
        'created_at': '2024-07-20T10:30:00Z',
        'ride': {
          'pickup_location': 'DHA Phase 5',
          'dropoff_location': 'Clifton',
        }
      },
      {
        'id': '2',
        'reviewer_name': 'Sara Khan',
        'rating': 4,
        'comment': 'Good ride experience. Comfortable car.',
        'created_at': '2024-07-18T14:15:00Z',
        'ride': {
          'pickup_location': 'Gulshan',
          'dropoff_location': 'Saddar',
        }
      },
    ];
  }

  List<Map<String, dynamic>> _getMockGivenReviews() {
    return [
      {
        'id': '3',
        'reviewee_name': 'Maria Khan',
        'rating': 5,
        'comment': 'Great driver, very professional!',
        'created_at': '2024-07-19T16:45:00Z',
        'ride': {
          'pickup_location': 'Nazimabad',
          'dropoff_location': 'Korangi',
        }
      },
    ];
  }
}
