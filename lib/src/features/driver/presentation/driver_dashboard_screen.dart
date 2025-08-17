import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../user_profile/presentation/user_profile_screen.dart';
import '../../../screens/notification_settings_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with TickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final MessageService messageService = Get.find<MessageService>();
  final ApiService apiService = Get.find<ApiService>();

  late TabController _tabController;
  
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _upcomingRides = [];
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final initialTabIndex = args?['initialTabIndex'] ?? 0;
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialTabIndex);
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Driver Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car, color: Colors.white),
            onPressed: () => Get.toNamed('/vehicle-management'),
            tooltip: 'My Vehicles',
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => Get.to(() => NotificationSettingsScreen()),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Get.to(() => const UserProfileScreen()),
            tooltip: 'Profile',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF87CEEB), // Sky blue
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF87CEEB),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'My Rides'),
            Tab(text: 'Requests'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildMyRidesTab(),
                _buildRequestsTab(),
                _buildReviewsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/create-ride'),
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Create Ride', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _dashboardData?['ride_statistics'];
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF87CEEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for FAB
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            const Text(
              'Quick Stats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.directions_car,
                    title: 'Total Rides',
                    value: '${stats?['total_rides'] ?? 0}',
                    color: const Color(0xFF87CEEB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Passengers',
                    value: '${stats?['total_passengers'] ?? 0}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    title: 'Rating',
                    value: '${stats?['average_rating']?.toStringAsFixed(1) ?? '0.0'}',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money,
                    title: 'Earnings',
                    value: 'PKR ${stats?['total_earnings'] ?? 0}',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.add_road,
              title: 'Create New Ride',
              subtitle: 'Offer a ride to passengers',
              onTap: () => Get.toNamed('/create-ride'),
            ),
            _buildActionCard(
              icon: Icons.verified_user,
              title: 'Driver Verification',
              subtitle: 'Complete your driver verification',
              onTap: () => Get.toNamed('/driver-verification'),
            ),
            _buildActionCard(
              icon: Icons.directions_car_outlined,
              title: 'Manage Vehicles',
              subtitle: 'Add or edit your vehicles',
              onTap: () => Get.toNamed('/vehicle-management'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRidesTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF87CEEB),
      child: _upcomingRides.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.no_transfer,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No upcoming rides',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a ride to start sharing',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for FAB
              itemCount: _upcomingRides.length,
              itemBuilder: (context, index) {
                final ride = _upcomingRides[index];
                return _buildRideCard(ride);
              },
            ),
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF87CEEB),
      child: _pendingRequests.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ride requests will appear here',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for FAB
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                final request = _pendingRequests[index];
                return _buildRequestCard(request);
              },
            ),
    );
  }

  Widget _buildReviewsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF87CEEB),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Reviews',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'View your reviews and ratings',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/driver-reviews'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All Reviews'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF87CEEB),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF87CEEB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final String status = ride['status'] ?? 'scheduled';
    final seatsLeft = int.tryParse(ride['seats_left']?.toString() ?? '0') ?? (ride['available_seats'] is int ? ride['available_seats'] : int.tryParse(ride['available_seats']?.toString() ?? '0')) ?? 0;
    final totalSeats = int.tryParse(ride['total_seats']?.toString() ?? '0') ?? 0;
    final pendingRequestsCount = int.tryParse(ride['pending_requests_count']?.toString() ?? '0') ?? 0;
    final passengers = ride['passengers'] as List<dynamic>? ?? [];
    final pickupLocation = ride['pickup_location'] ?? 'Unknown';
    final dropoffLocation = ride['dropoff_location'] ?? 'Unknown';
    final departureTime = ride['departure_time'] ?? '';
    final price = double.tryParse(ride['price_per_seat']?.toString() ?? '0') ?? 0.0;
    final femaleOnly = ride['female_only_ride'] ?? false;

    // Determine available actions based on ride status
    final canStart = status == 'scheduled'; // Driver can start ride anytime if scheduled
    final canComplete = status == 'in_progress';
    final canCancel = status == 'scheduled' || status == 'in_progress';

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with route and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$pickupLocation → $dropoffLocation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(departureTime),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRideStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRideStatusColor(status).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: _getRideStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ride details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.airline_seat_recline_normal, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$seatsLeft/$totalSeats seats available',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (price > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.green, size: 16),
                            Text(
                              'PKR $price per seat',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (femaleOnly) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.female, color: Colors.pink, size: 16),
                            const Text(
                              'Female Only',
                              style: TextStyle(
                                color: Colors.pink,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (pendingRequestsCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingRequestsCount request${pendingRequestsCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Current passengers
            if (passengers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Passengers:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      passengers.map((p) => p['user']?['first_name'] ?? p['passenger']?['first_name'] ?? 'Unknown').join(', '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Column(
              children: [
                // Start ride button (only for scheduled rides)
                if (canStart) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startRide(int.tryParse((ride['id'] ?? '').toString()) ?? 0),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Complete ride button (only for in-progress rides)
                if (canComplete) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _completeRide(int.tryParse((ride['id'] ?? '').toString()) ?? 0),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Complete Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // View requests button
                if (pendingRequestsCount > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewRequests(int.tryParse((ride['id'] ?? '').toString()) ?? 0),
                      icon: const Icon(Icons.people, size: 18),
                      label: Text('View Requests ($pendingRequestsCount)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF87CEEB),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Cancel button
                if (canCancel) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelRide(int.tryParse((ride['id'] ?? '').toString()) ?? 0),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final passenger = request['passenger'];

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF87CEEB),
                  child: Text(
                    (passenger['first_name'] ?? 'U')[0].toUpperCase(),
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
                        '${passenger['first_name'] ?? ''} ${passenger['last_name'] ?? ''}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${request['pickup_location']} → ${request['dropoff_location']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request['message']?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request['message'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(int.tryParse((request['id'] ?? '').toString()) ?? 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectRequest(int.tryParse((request['id'] ?? '').toString()) ?? 0),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRideStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return const Color(0xFF87CEEB);
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load dashboard data
      final dashboardFuture = apiService.getDriverDashboard();
      final upcomingRidesFuture = apiService.getUpcomingRides();
      final pendingRequestsFuture = apiService.getPendingRideRequests();

      final results = await Future.wait([
        dashboardFuture,
        upcomingRidesFuture,
        pendingRequestsFuture,
      ]);

      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        _upcomingRides = results[1] as List<dynamic>;
        _pendingRequests = results[2] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      messageService.showError('Failed to load dashboard data: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  void _startRide(int rideId) async {
    try {
      await apiService.startRideEnhanced(rideId);
      messageService.showSuccess('Ride started! Status changed to In Progress.');
      _refreshData();
      
      // Show helpful tip for new drivers
      Get.snackbar(
        'Ride Started',
        'Your ride is now in progress. Don\'t forget to complete it when finished.',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.info_outline, color: Colors.white),
      );
    } catch (e) {
      messageService.showError('Failed to start ride: $e');
    }
  }

  void _acceptRequest(int requestId) async {
    try {
      await apiService.acceptRideRequest(requestId);
      messageService.showSuccess('Request accepted successfully');
      _refreshData();
    } catch (e) {
      messageService.showError('Failed to accept request: $e');
    }
  }

  void _rejectRequest(int requestId) async {
    try {
      await apiService.rejectRideRequest(requestId);
      messageService.showSuccess('Request rejected');
      _refreshData();
    } catch (e) {
      messageService.showError('Failed to reject request: $e');
    }
  }

  void _viewRequests(int rideId) {
    // Switch to the requests tab (index 2)
    _tabController.animateTo(2);
  }

  void _completeRide(int rideId) async {
    try {
      final response = await apiService.completeRide(rideId);
      messageService.showSuccess('Ride completed successfully!');
      _refreshData();
      
      // Check if there are passengers to review
      if (response['can_review_passengers'] == true) {
        final passengers = response['reviewable_passengers'] as List<dynamic>?;
        if (passengers != null && passengers.isNotEmpty) {
          // Show review dialog with more emphasis
          Get.dialog(
            AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.rate_review, color: Color(0xFF87CEEB)),
                  const SizedBox(width: 8),
                  const Text('Review Passengers'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your ride has been completed! Please take a moment to review ${passengers.length} passenger${passengers.length > 1 ? 's' : ''} from this ride.'),
                  const SizedBox(height: 12),
                  const Text(
                    'Your feedback helps maintain a safe and reliable ride-sharing community.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.grey[900],
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
              contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Review Later', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    _navigateToReviewScreen(rideId, passengers);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Review Now'),
                ),
              ],
            ),
          );
        }
      } else {
        // No passengers to review, show completion message
        Get.snackbar(
          'Ride Completed',
          'Your ride has been marked as completed.',
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      messageService.showError('Failed to complete ride: $e');
    }
  }

  void _navigateToReviewScreen(int rideId, List<dynamic> passengers) {
    Get.toNamed('/review-passengers', arguments: {
      'rideId': rideId,
      'passengers': passengers,
    });
  }

  void _cancelRide(int rideId) async {
    // Show confirmation dialog
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride? All passengers will be notified of the cancellation. This action cannot be undone.'),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Yes, Cancel Ride', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Use the dedicated cancelRide API method which should handle passenger notifications
        await apiService.cancelRide(rideId);
        messageService.showSuccess('Ride cancelled successfully. All passengers have been notified.');
        _refreshData();
      } catch (e) {
        messageService.showError('Failed to cancel ride: $e');
      }
    }
  }

  String _formatDateTime(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await authController.logout();
        Get.offAllNamed('/user-selection');
      } catch (e) {
        messageService.showError('Logout failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
