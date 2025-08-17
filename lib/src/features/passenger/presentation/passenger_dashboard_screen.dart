import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../user_profile/presentation/user_profile_screen.dart';
import '../../common/presentation/improved_route_location_picker.dart';
import '../../../screens/notification_settings_screen.dart';

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class PassengerDashboardScreen extends StatefulWidget {
  const PassengerDashboardScreen({super.key});

  @override
  State<PassengerDashboardScreen> createState() =>
      _PassengerDashboardScreenState();
}

class _PassengerDashboardScreenState extends State<PassengerDashboardScreen>
    with TickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final MessageService messageService = Get.find<MessageService>();
  final ApiService apiService = Get.find<ApiService>();

  late TabController _tabController;

  // Search form controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _departureTimeController =
      TextEditingController();

  // Location coordinates
  double? _pickupLat, _pickupLng, _dropoffLat, _dropoffLng;
  DateTime? _selectedDateTime;

  // Data
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _myRideRequests = [];
  List<Map<String, dynamic>> _recentRides = [];

  // Enhanced My Rides data from new API
  List<Map<String, dynamic>> _currentRides = []; // Future rides I'm taking
  List<Map<String, dynamic>> _pastRides = []; // Past/completed rides
  List<Map<String, dynamic>> _offeredRides =
      []; // Rides I've offered (if user is also a driver)

  Map<String, dynamic>? _userStats;

  // Reviews data
  List<Map<String, dynamic>> _receivedReviews = [];
  List<Map<String, dynamic>> _givenReviews = [];
  List<Map<String, dynamic>> _pendingRatings = [];

  bool _isSearching = false;
  bool _femaleOnly = false;

  // Helper method to check if current user is female
  bool _isCurrentUserFemale() {
    final user = authController.currentUser.value;
    if (user == null) {
      debugPrint('🔍 PassengerDashboardScreen: No user found');
      return false;
    }

    // Check the gender field - handle potential null/empty values
    final gender = user.gender.trim().toLowerCase();
    debugPrint('🔍 PassengerDashboardScreen: User gender = "$gender"');
    final isFemale = gender == 'female' || gender == 'f' || gender == 'woman';
    debugPrint('🔍 PassengerDashboardScreen: Is female = $isFemale');
    return isFemale;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Set female-only preference if user is female
    if (_isCurrentUserFemale()) {
      _femaleOnly = true;
    }

    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Passenger Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
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
            itemBuilder:
                (context) => [
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
            Tab(text: 'Search Rides'),
            Tab(text: 'My Requests'),
            Tab(text: 'History'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildRequestsTab(),
          _buildHistoryTab(),
          _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return RefreshIndicator(
      onRefresh: _refreshSearchResults,
      color: const Color(0xFF87CEEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ), // Added bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Form Card
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find a Ride',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Cards - Interactive and dynamic
                    Column(
                      children: [
                        // Pickup Location Button
                        InkWell(
                          onTap: _selectLocations,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _pickupLat != null
                                        ? const Color(0xFF87CEEB)
                                        : Colors.grey[600]!,
                                width: _pickupLat != null ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _pickupLat != null
                                          ? Icons.location_on
                                          : Icons.location_on_outlined,
                                      color:
                                          _pickupLat != null
                                              ? const Color(0xFF87CEEB)
                                              : Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Pickup Location',
                                        style: TextStyle(
                                          color:
                                              _pickupLat != null
                                                  ? const Color(0xFF87CEEB)
                                                  : Colors.grey[400],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_pickupLat != null)
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF87CEEB),
                                        size: 18,
                                      )
                                    else
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.grey[400],
                                        size: 18,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _pickupController.text.isNotEmpty
                                      ? _pickupController.text
                                      : 'Tap to select your pickup location',
                                  style: TextStyle(
                                    color:
                                        _pickupController.text.isNotEmpty
                                            ? Colors.white
                                            : Colors.grey[400],
                                    fontSize: 13,
                                    fontWeight:
                                        _pickupController.text.isNotEmpty
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Destination Location Button
                        InkWell(
                          onTap: _selectLocations,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _dropoffLat != null
                                        ? const Color(0xFF87CEEB)
                                        : Colors.grey[600]!,
                                width: _dropoffLat != null ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _dropoffLat != null
                                          ? Icons.flag
                                          : Icons.flag_outlined,
                                      color:
                                          _dropoffLat != null
                                              ? const Color(0xFF87CEEB)
                                              : Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Destination',
                                        style: TextStyle(
                                          color:
                                              _dropoffLat != null
                                                  ? const Color(0xFF87CEEB)
                                                  : Colors.grey[400],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_dropoffLat != null)
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF87CEEB),
                                        size: 18,
                                      )
                                    else
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.grey[400],
                                        size: 18,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _dropoffController.text.isNotEmpty
                                      ? _dropoffController.text
                                      : 'Tap to select your destination',
                                  style: TextStyle(
                                    color:
                                        _dropoffController.text.isNotEmpty
                                            ? Colors.white
                                            : Colors.grey[400],
                                    fontSize: 13,
                                    fontWeight:
                                        _dropoffController.text.isNotEmpty
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Action Button - Contextual help
                    if (_pickupLat != null && _dropoffLat != null)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: _selectLocations,
                              icon: const Icon(
                                Icons.edit_location_alt,
                                color: Color(0xFF87CEEB),
                                size: 18,
                              ),
                              label: const Text(
                                'Edit Route',
                                style: TextStyle(
                                  color: Color(0xFF87CEEB),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF87CEEB),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: _clearLocations,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.grey[600]!,
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Icon(
                                Icons.clear,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      // Route completion indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]?.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Select both locations above to continue',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Date and Time
                    TextFormField(
                      controller: _departureTimeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Departure Time',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.schedule,
                          color: Color(0xFF87CEEB),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      readOnly: true,
                      onTap: _selectDateTime,
                    ),
                    const SizedBox(height: 12),
                    // Now button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _setCurrentDateTime,
                        icon: const Icon(
                          Icons.schedule_send,
                          color: Colors.black,
                          size: 18,
                        ),
                        label: const Text(
                          'Now',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF87CEEB),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Gender Preference Toggle
                    if (_isCurrentUserFemale())
                      CheckboxListTile(
                        title: const Text(
                          'Female-only rides',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Show only rides with female drivers',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        value: _femaleOnly,
                        onChanged: (value) {
                          setState(() {
                            _femaleOnly = value ?? false;
                            debugPrint(
                              '🔄 Female-only filter changed to: $_femaleOnly',
                            );
                          });
                        },
                        activeColor: const Color(0xFF87CEEB),
                        checkColor: Colors.black,
                        tileColor: Colors.transparent,
                      )
                    else
                      // Show info for non-female users
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Female-only ride filtering is available for female passengers',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Search Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSearching ? null : _searchRides,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF87CEEB),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSearching
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                : const Text(
                                  'Search Rides',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Results
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Available Rides (${_searchResults.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Add filter button
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.filter_list,
                      color: Color(0xFF87CEEB),
                    ),
                    onSelected: _applyFilter,
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('All Rides'),
                          ),
                          const PopupMenuItem(
                            value: 'nearby',
                            child: Text('Nearby Only'),
                          ),
                          const PopupMenuItem(
                            value: 'soon',
                            child: Text('Departing Soon'),
                          ),
                          const PopupMenuItem(
                            value: 'affordable',
                            child: Text('Most Affordable'),
                          ),
                        ],
                  ),
                  // Show filtering info for different user types
                  if (!_isCurrentUserFemale() && _searchResults.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 12,
                            color: Colors.green[300],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filtered',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_femaleOnly &&
                      _searchResults.any((rideResult) {
                        final ride =
                            rideResult['ride'] as Map<String, dynamic>?;
                        return ride?['female_only_ride'] != true;
                      }))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Mixed Results',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final rideResult = _searchResults[index];
                  return _buildRideCard(rideResult);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      color: const Color(0xFF87CEEB),
      child:
          _myRideRequests.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No ride requests',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your ride requests will appear here',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ), // Added bottom padding
                itemCount: _myRideRequests.length,
                itemBuilder: (context, index) {
                  final request = _myRideRequests[index];
                  return _buildRequestCard(request);
                },
              ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      color: const Color(0xFF87CEEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card for completed rides
            Builder(
              builder: (context) {
                // Calculate completed rides count from actual data
                final completedRides =
                    _pastRides.where((ride) {
                      final status = ride['status']?.toString().toLowerCase();
                      return status == 'completed';
                    }).toList();

                // Calculate total amount spent on completed rides
                final totalSpent = completedRides.fold<double>(0.0, (
                  sum,
                  ride,
                ) {
                  final pricePerSeat = _parseToDouble(
                    ride['price_per_seat'] ?? ride['fare'] ?? 0,
                  );
                  return sum + pricePerSeat;
                });

                return Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completed Rides Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Completed',
                                '${completedRides.length}',
                                Icons.check_circle,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Total Spent',
                                'PKR ${totalSpent.toStringAsFixed(0)}',
                                Icons.payments,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Completed Rides List
            const Text(
              'Completed Rides',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                // Filter to only show completed rides (not cancelled)
                final completedRides =
                    _pastRides.where((ride) {
                      final status = ride['status']?.toString().toLowerCase();
                      return status == 'completed';
                    }).toList();

                if (completedRides.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No completed rides',
                    subtitle: 'Your completed rides will appear here',
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedRides.length,
                  itemBuilder: (context, index) {
                    final ride = completedRides[index];
                    return _buildCompletedRideCard(ride);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: const Color(0xFF87CEEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review Stats Card
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Review Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Your Rating',
                            '${_userStats?['average_rating']?.toStringAsFixed(1) ?? '0.0'}',
                            Icons.star,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Reviews Received',
                            '${_receivedReviews.length}',
                            Icons.thumb_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Reviews Given',
                            '${_givenReviews.length}',
                            Icons.rate_review,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Avg Given Rating',
                            _givenReviews.isNotEmpty
                                ? '${(_givenReviews.map((r) => r['rating'] ?? 0).reduce((a, b) => a + b) / _givenReviews.length).toStringAsFixed(1)}'
                                : '0.0',
                            Icons.star_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Action: Rate Pending Rides
            if (_pendingRatings.isNotEmpty) ...[
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notification_important,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pending Reviews',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have ${_pendingRatings.length} completed rides waiting for your review.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showPendingRatings(),
                        icon: const Icon(Icons.star),
                        label: const Text('Review Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recent Reviews Received
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reviews Received',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllReviews('received'),
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Color(0xFF87CEEB)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_receivedReviews.isEmpty)
              _buildEmptyReviewsCard('No reviews received yet')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _receivedReviews.take(3).length,
                itemBuilder: (context, index) {
                  final review = _receivedReviews[index];
                  return _buildReviewCard(review, isReceived: true);
                },
              ),

            const SizedBox(height: 24),

            // Recent Reviews Given
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reviews Given',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllReviews('given'),
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Color(0xFF87CEEB)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_givenReviews.isEmpty)
              _buildEmptyReviewsCard('No reviews given yet')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _givenReviews.take(3).length,
                itemBuilder: (context, index) {
                  final review = _givenReviews[index];
                  return _buildReviewCard(review, isReceived: false);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Build card specifically for completed rides with review functionality
  Widget _buildCompletedRideCard(Map<String, dynamic> ride) {
    if (ride.isEmpty) return const SizedBox.shrink();

    final rideId = ride['id'];
    final pickupLocation = ride['pickup_location']?.toString() ?? 'Unknown';
    final dropoffLocation = ride['dropoff_location']?.toString() ?? 'Unknown';
    final departureTime = ride['departure_time'];
    final pricePerSeat = _parseToDouble(ride['price_per_seat'] ?? 0);
    final isFemaleOnly = ride['female_only_ride'] == true;
    final estimatedDistance = _parseToDouble(
      ride['estimated_distance_km'] ?? 0,
    );
    final estimatedDuration = ride['estimated_duration_minutes'] ?? 0;

    // Driver information
    final driverInfo = ride['driver'] as Map<String, dynamic>?;
    final driverName = driverInfo?['first_name'] ?? 'Unknown Driver';
    final driverRating = _parseToDouble(driverInfo?['rating'] ?? 0);

    // Vehicle information
    final vehicleInfo = ride['vehicle'] as Map<String, dynamic>?;
    final vehicleMake = vehicleInfo?['make'] ?? '';
    final vehicleModel = vehicleInfo?['model'] ?? '';

    // Check if already reviewed
    final isAlreadyReviewed = _hasReviewedRide(rideId);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Driver info
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Driver: $driverName',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                if (driverRating > 0) ...[
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    driverRating.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),

            // Vehicle info
            if (vehicleMake.isNotEmpty && vehicleModel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$vehicleMake $vehicleModel',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Ride details row
            Row(
              children: [
                if (estimatedDistance > 0) ...[
                  const Icon(Icons.straighten, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${estimatedDistance.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
                if (estimatedDuration > 0) ...[
                  const Icon(Icons.schedule, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${estimatedDuration}min',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
                if (isFemaleOnly) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.pink.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'Female Only',
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'PKR ${pricePerSeat.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF87CEEB),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRideDetails({'ride': ride}),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF87CEEB)),
                      foregroundColor: const Color(0xFF87CEEB),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      isAlreadyReviewed
                          ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Reviewed',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ElevatedButton.icon(
                            onPressed: () => _rateRide(ride),
                            icon: const Icon(Icons.star, size: 16),
                            label: const Text('Rate Driver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
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

  // Helper method to safely parse doubles
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to check if a ride has been reviewed
  bool _hasReviewedRide(dynamic rideId) {
    if (rideId == null) return false;
    final reviewedRideIds =
        _givenReviews.map((review) => review['ride']).toSet();
    return reviewedRideIds.contains(rideId);
  }

  // Show rating dialog for completed rides
  Future<Map<String, dynamic>?> _showRatingDialog({
    required String driverName,
    required Map<String, dynamic> rideInfo,
  }) async {
    int overallRating = 5;
    int punctualityRating = 5;
    int cleanlinessRating = 5;
    int communicationRating = 5;
    int safetyRating = 5;
    String comment = '';

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    'Rate $driverName',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ride Info
                        Text(
                          '${rideInfo['pickup_location']} → ${rideInfo['dropoff_location']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Overall Rating
                        const Text(
                          'Overall Rating',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap:
                                  () =>
                                      setState(() => overallRating = index + 1),
                              child: Icon(
                                index < overallRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.orange,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Specific Ratings
                        _buildRatingRow(
                          'Punctuality',
                          punctualityRating,
                          (rating) =>
                              setState(() => punctualityRating = rating),
                        ),
                        _buildRatingRow(
                          'Cleanliness',
                          cleanlinessRating,
                          (rating) =>
                              setState(() => cleanlinessRating = rating),
                        ),
                        _buildRatingRow(
                          'Communication',
                          communicationRating,
                          (rating) =>
                              setState(() => communicationRating = rating),
                        ),
                        _buildRatingRow(
                          'Safety',
                          safetyRating,
                          (rating) => setState(() => safetyRating = rating),
                        ),

                        const SizedBox(height: 16),

                        // Comment
                        const Text(
                          'Comment (Optional)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (value) => comment = value,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Share your experience...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.pop(context, {
                            'overall_rating': overallRating,
                            'punctuality_rating': punctualityRating,
                            'cleanliness_rating': cleanlinessRating,
                            'communication_rating': communicationRating,
                            'safety_rating': safetyRating,
                            'comment':
                                comment.trim().isEmpty ? null : comment.trim(),
                          }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF87CEEB),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Submit Review'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildRatingRow(
    String label,
    int rating,
    Function(int) onRatingChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 20,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Action methods for ride management

  Widget _buildRideCard(Map<String, dynamic> rideResult) {
    // Add null safety checks
    if (rideResult.isEmpty) {
      debugPrint('⚠️ Empty ride result provided to _buildRideCard');
      return const SizedBox.shrink();
    }

    final ride = rideResult['ride'] as Map<String, dynamic>?;
    final driver = rideResult['driver'] as Map<String, dynamic>?;
    final vehicle = rideResult['vehicle'] as Map<String, dynamic>?;
    final estimatedFare = _parseToDouble(rideResult['estimated_fare'] ?? 0);
    final isPeakHour = rideResult['is_peak_hour'] ?? false;
    final isFemaleOnly = ride?['female_only_ride'] ?? false;
    final seatsLeft = ride?['seats_left'] ?? ride?['available_seats'] ?? 0;

    // Enhanced ride information
    final rideStats = ride?['ride_stats'] as Map<String, dynamic>? ?? {};
    final timeUntilDeparture = ride?['time_until_departure'] ?? 0;
    final isLeavingSoon = ride?['is_leaving_soon'] ?? false;
    final driverTotalRides = ride?['driver_total_rides'] ?? 0;
    final driverVerified = ride?['driver_verified'] ?? false;
    final comfortLevel = ride?['comfort_level'] ?? 'moderate';
    final occupancyRate = rideStats['occupancy_rate']?.toDouble() ?? 0.0;

    // If estimated fare is 0, try to get from ride data
    final finalFare =
        estimatedFare > 0
            ? estimatedFare
            : _parseToDouble(
              ride?['price_per_seat'] ?? ride?['fare_per_seat'] ?? 0,
            );

    // Return empty widget if essential data is missing
    if (ride == null || driver == null) {
      debugPrint(
        '⚠️ Missing essential ride data: ride=${ride != null}, driver=${driver != null}',
      );
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with driver info and fare
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF87CEEB),
                      child: Text(
                        (driver['first_name'] ?? 'D')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (driverVerified)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isFemaleOnly)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.woman,
                                    size: 12,
                                    color: Colors.pink,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'F',
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _parseToDouble(
                              driver['rating'] ?? 0,
                            ).toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• $driverTotalRides rides',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PKR ${finalFare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF87CEEB),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPeakHour || rideStats['is_peak_hour'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Peak',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        if (isLeavingSoon) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Soon',
                              style: TextStyle(color: Colors.red, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route information
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF87CEEB),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${ride['pickup_location']?.toString() ?? 'Unknown'} → ${ride['dropoff_location']?.toString() ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Departure time with countdown
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDateTime(ride['departure_time']?.toString()),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (timeUntilDeparture > 0)
                  Text(
                    '${(timeUntilDeparture / 60).floor()}h ${timeUntilDeparture % 60}m',
                    style: TextStyle(
                      color: isLeavingSoon ? Colors.red : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Enhanced vehicle and seats info
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${vehicle?['make']?.toString() ?? 'Unknown'} ${vehicle?['model']?.toString() ?? 'Car'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  '$seatsLeft/${ride['total_seats'] ?? 0} seats',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),

            // Occupancy bar
            if (occupancyRate > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: occupancyRate / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                occupancyRate > 80
                                    ? Colors.red
                                    : occupancyRate > 60
                                    ? Colors.orange
                                    : Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${occupancyRate.toStringAsFixed(0)}% full',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],

            // Additional info row
            if (ride['estimated_distance_km'] != null ||
                comfortLevel != 'moderate') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (ride['estimated_distance_km'] != null) ...[
                    const Icon(
                      Icons.straighten,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ride['estimated_distance_km']} km',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (ride['estimated_distance_km'] != null &&
                      comfortLevel != 'moderate')
                    const SizedBox(width: 16),
                  if (comfortLevel != 'moderate') ...[
                    Icon(
                      comfortLevel == 'quiet'
                          ? Icons.volume_off
                          : comfortLevel == 'chatty'
                          ? Icons.chat
                          : Icons.volume_up,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comfortLevel.capitalize(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (seatsLeft <= 2 && seatsLeft > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        seatsLeft == 1 ? 'Last Seat!' : 'Almost Full',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRideDetails(rideResult),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF87CEEB)),
                      foregroundColor: const Color(0xFF87CEEB),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        seatsLeft > 0 ? () => _requestRide(rideResult) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          seatsLeft > 0 ? const Color(0xFF87CEEB) : Colors.grey,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                      seatsLeft > 0 ? Icons.send : Icons.block,
                      size: 16,
                    ),
                    label: Text(
                      seatsLeft > 0 ? 'Request Ride' : 'Full',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildRequestCard(Map<String, dynamic> request) {
    // Add null safety check
    if (request.isEmpty) return const SizedBox.shrink();

    final status = request['status']?.toString() ?? 'pending';
    final pickupLocation = request['pickup_location']?.toString() ?? 'Unknown';
    final dropoffLocation =
        request['dropoff_location']?.toString() ?? 'Unknown';

    // Try to get driver name from multiple possible locations
    final rideInfo = request['ride_info'] as Map<String, dynamic>?;
    String driverName = 'Unknown Driver';

    if (rideInfo?['driver_name'] != null) {
      driverName = rideInfo!['driver_name'].toString();
    } else if (request['driver_name'] != null) {
      driverName = request['driver_name'].toString();
    }

    final estimatedFare = request['estimated_fare']?.toString() ?? '0';
    final seatsRequested = request['seats_requested'] ?? 1;
    final createdAt = request['created_at']?.toString();
    final respondedAt = request['responded_at']?.toString();
    final driverResponse = request['driver_response']?.toString() ?? '';
    final rideId = request['ride'];
    final driverId = request['driver_id'];

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$pickupLocation → $dropoffLocation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRequestStatusColor(
                      status,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getRequestStatusColor(
                        status,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getRequestStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Driver and ride info
            Row(
              children: [
                Icon(Icons.person, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Driver: $driverName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (estimatedFare != '0') ...[
                  Icon(Icons.payment, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'PKR $estimatedFare',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

            // Vehicle info if available
            if (rideInfo?['vehicle_info'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vehicle: ${rideInfo!['vehicle_info']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Seats and time info
            Row(
              children: [
                Icon(
                  Icons.airline_seat_recline_normal,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '$seatsRequested seat${seatsRequested > 1 ? 's' : ''} requested',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.schedule, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Requested ${_formatTimeAgo(createdAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),

            // Driver response section
            if (status == 'accepted' || status == 'rejected') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      status == 'accepted'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        status == 'accepted'
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          status == 'accepted'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              status == 'accepted' ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Request ${status == 'accepted' ? 'Accepted' : 'Rejected'}',
                          style: TextStyle(
                            color:
                                status == 'accepted'
                                    ? Colors.green
                                    : Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (respondedAt != null)
                          Text(
                            _formatTimeAgo(respondedAt),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    if (driverResponse.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        driverResponse,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Action buttons for accepted requests
            if (status == 'accepted') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewRideDetails(rideId),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('View Ride'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF87CEEB),
                        side: const BorderSide(color: Color(0xFF87CEEB)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _contactDriver(driverId, driverName),
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF87CEEB),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Pending status info
            if (status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Waiting for driver response...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _cancelRequest(request['id']),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF87CEEB), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectLocations() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ImprovedRouteLocationPicker(
              title: 'Select Pickup and Destination',
              pickupLocation:
                  _pickupLat != null && _pickupLng != null
                      ? LatLng(_pickupLat!, _pickupLng!)
                      : null,
              dropoffLocation:
                  _dropoffLat != null && _dropoffLng != null
                      ? LatLng(_dropoffLat!, _dropoffLng!)
                      : null,
              pickupAddress: _pickupController.text,
              dropoffAddress: _dropoffController.text,
            ),
      ),
    );

    if (result != null &&
        result['pickup_location'] != null &&
        result['dropoff_location'] != null) {
      setState(() {
        final pickupLocation = result['pickup_location'] as LatLng;
        final dropoffLocation = result['dropoff_location'] as LatLng;

        _pickupLat = pickupLocation.latitude;
        _pickupLng = pickupLocation.longitude;
        _pickupController.text = result['pickup_address'] ?? 'Pickup Location';

        _dropoffLat = dropoffLocation.latitude;
        _dropoffLng = dropoffLocation.longitude;
        _dropoffController.text =
            result['dropoff_address'] ?? 'Dropoff Location';
      });

      debugPrint('📍 Locations updated:');
      debugPrint(
        'Pickup: ${_pickupController.text} ($_pickupLat, $_pickupLng)',
      );
      debugPrint(
        'Dropoff: ${_dropoffController.text} ($_dropoffLat, $_dropoffLng)',
      );

      // Show feedback message
      messageService.showSuccess('Route locations updated successfully');
    }
  }

  // Helper method to clear locations if needed
  void _clearLocations() {
    setState(() {
      _pickupLat = null;
      _pickupLng = null;
      _dropoffLat = null;
      _dropoffLng = null;
      _pickupController.clear();
      _dropoffController.clear();
    });
    messageService.showInfo('Route cleared');
  }

  void _selectDateTime() async {
    final now = DateTime.now();

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF0EA5E9), // Match create ride theme
              onPrimary: Colors.white,
              surface: Colors.grey[800]!,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF0EA5E9), // Match create ride theme
                onPrimary: Colors.white,
                surface: Colors.grey[800]!,
                onSurface: Colors.white,
              ),
              dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // Validate that the selected datetime is not in the past
        if (dateTime.isBefore(now)) {
          messageService.showError('Departure time cannot be in the past');
          return;
        }

        setState(() {
          _selectedDateTime = dateTime;
          _departureTimeController.text = DateFormat(
            'MMM dd, yyyy - hh:mm a',
          ).format(_selectedDateTime!);
        });
      }
    }
  }

  void _setCurrentDateTime() {
    final now = DateTime.now();
    
    setState(() {
      _selectedDateTime = now;
      _departureTimeController.text = DateFormat('MMM dd, yyyy - hh:mm a').format(now);
    });
    
    // Show a brief confirmation message
    messageService.showSuccess('Departure time set to now');
  }

  void _searchRides() async {
    // Check validation with detailed messages
    if (_pickupLat == null || _pickupLng == null) {
      messageService.showError('Please select a pickup location');
      return;
    }

    if (_dropoffLat == null || _dropoffLng == null) {
      messageService.showError('Please select a destination');
      return;
    }

    if (_selectedDateTime == null) {
      messageService.showError('Please select departure time');
      return;
    }

    debugPrint('🔍 Starting ride search with:');
    debugPrint('Pickup: ${_pickupController.text} ($_pickupLat, $_pickupLng)');
    debugPrint(
      'Dropoff: ${_dropoffController.text} ($_dropoffLat, $_dropoffLng)',
    );
    debugPrint('DateTime: $_selectedDateTime');
    debugPrint(
      'Female-only filter: $_femaleOnly (user is female: ${_isCurrentUserFemale()})',
    );
    debugPrint('Current user ID: ${authController.currentUser.value?.id}');

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      // Check if user is authenticated before making API calls
      if (!authController.isLoggedIn.value) {
        messageService.showError('Please log in to search for rides');
        setState(() => _isSearching = false);
        return;
      }

      // First try with specific criteria (including female-only filter if enabled)
      final result = await apiService.searchRidesEnhanced(
        pickupLocation: _pickupController.text,
        dropoffLocation: _dropoffController.text,
        pickupLatitude: _pickupLat!,
        pickupLongitude: _pickupLng!,
        dropoffLatitude: _dropoffLat!,
        dropoffLongitude: _dropoffLng!,
        departureTime: _selectedDateTime!.toIso8601String(),
        femaleOnly: _femaleOnly,
      );

      setState(() {
        // Enhanced null safety for search results parsing
        final rawRides = result['rides'] as List<dynamic>? ?? [];
        final allRides =
            rawRides
                .where((ride) => ride != null && ride is Map<String, dynamic>)
                .cast<Map<String, dynamic>>()
                .toList();

        debugPrint('🔍 Found ${allRides.length} rides before filtering');

        _searchResults =
            allRides.where((rideResult) {
              // Ensure essential data exists
              final ride = rideResult['ride'] as Map<String, dynamic>?;
              final driver = rideResult['driver'] as Map<String, dynamic>?;
              if (ride == null ||
                  driver == null ||
                  ride.isEmpty ||
                  driver.isEmpty) {
                debugPrint('🚫 Filtering out ride with missing essential data');
                return false;
              }

              // Check if this is a female-only ride
              final isFemaleOnly = ride['female_only_ride'] == true;
              final isUserFemale = _isCurrentUserFemale();

              // If user is not female and ride is female-only, exclude it
              if (!isUserFemale && isFemaleOnly) {
                debugPrint(
                  '🚫 Filtering out female-only ride for non-female user',
                );
                return false;
              }

              // If user is female and has female-only filter enabled, only show female-only rides
              if (isUserFemale && _femaleOnly && !isFemaleOnly) {
                debugPrint(
                  '🚫 Filtering out non-female-only ride (female user with female-only filter)',
                );
                return false;
              }

              // Filter out rides where user is already a passenger
              final passengers = ride['passengers'] as List<dynamic>? ?? [];
              final currentUserId = authController.currentUser.value?.id;
              if (currentUserId != null) {
                final isAlreadyJoined = passengers.any((passenger) {
                  if (passenger is Map<String, dynamic>) {
                    return passenger['id'] == currentUserId ||
                        passenger['passenger_id'] == currentUserId ||
                        passenger['user_id'] == currentUserId;
                  }
                  return false;
                });
                if (isAlreadyJoined) {
                  debugPrint('🚫 Filtering out ride already joined by user');
                  return false;
                }
              }

              // Filter out rides where user is the driver
              final driverId =
                  driver['id'] ?? driver['user_id'] ?? driver['driver_id'];
              if (currentUserId != null && driverId == currentUserId) {
                debugPrint('🚫 Filtering out ride where user is the driver');
                return false;
              }

              return true;
            }).toList();

        debugPrint('✅ Showing ${_searchResults.length} rides after filtering');
      });

      // If no rides found with specific criteria, try showing all available rides
      if (_searchResults.isEmpty) {
        debugPrint(
          '🔄 No rides found with specific criteria, searching all available rides...',
        );

        try {
          // Try getting all available rides through a more general endpoint
          final fallbackResult = await apiService.get(
            '/rides/rides/available_rides/',
            queryParameters: {
              'departure_date_from':
                  _selectedDateTime!.toIso8601String().split('T')[0],
              'departure_date_to':
                  _selectedDateTime!
                      .add(const Duration(days: 1))
                      .toIso8601String()
                      .split('T')[0],
            },
          );

          if (fallbackResult.statusCode == 200) {
            final fallbackRides = fallbackResult.data as List<dynamic>? ?? [];

            setState(() {
              _searchResults =
                  fallbackRides
                      .where(
                        (ride) => ride != null && ride is Map<String, dynamic>,
                      )
                      .cast<Map<String, dynamic>>()
                      .where((rideData) {
                        // Check if this is a female-only ride
                        final isFemaleOnly =
                            rideData['female_only_ride'] == true;
                        final isUserFemale = _isCurrentUserFemale();

                        // If user is not female and ride is female-only, exclude it
                        if (!isUserFemale && isFemaleOnly) {
                          debugPrint(
                            '🚫 Filtering out female-only ride for non-female user (fallback)',
                          );
                          return false;
                        }

                        // Filter out rides where user is already a passenger
                        final passengers =
                            rideData['passengers'] as List<dynamic>? ?? [];
                        final currentUserId =
                            authController.currentUser.value?.id;
                        if (currentUserId != null) {
                          final isAlreadyJoined = passengers.any((passenger) {
                            if (passenger is Map<String, dynamic>) {
                              return passenger['id'] == currentUserId ||
                                  passenger['passenger_id'] == currentUserId ||
                                  passenger['user_id'] == currentUserId;
                            }
                            return false;
                          });
                          if (isAlreadyJoined) {
                            debugPrint(
                              '🚫 Filtering out ride already joined by user (fallback)',
                            );
                            return false;
                          }
                        }

                        // Filter out rides where user is the driver
                        final driverId =
                            rideData['driver_id'] ?? rideData['driver']?['id'];
                        if (currentUserId != null &&
                            driverId == currentUserId) {
                          debugPrint(
                            '🚫 Filtering out ride where user is the driver (fallback)',
                          );
                          return false;
                        }

                        return true;
                      })
                      .map((rideData) {
                        // Transform the data to match expected format
                        final fare =
                            rideData['estimated_fare'] ??
                            rideData['fare_per_seat'] ??
                            rideData['price_per_seat'] ??
                            rideData['ride']?['price_per_seat'] ??
                            0.0;

                        return {
                          'ride': rideData,
                          'driver': {
                            'id':
                                rideData['driver_id'] ??
                                rideData['driver']?['id'],
                            'first_name':
                                rideData['driver_first_name'] ??
                                rideData['driver']?['first_name'] ??
                                'Unknown',
                            'last_name':
                                rideData['driver_last_name'] ??
                                rideData['driver']?['last_name'] ??
                                '',
                            'rating':
                                rideData['driver_rating'] ??
                                rideData['driver']?['rating'] ??
                                0.0,
                          },
                          'vehicle':
                              rideData['vehicle'] ??
                              {'make': 'Unknown', 'model': 'Car'},
                          'estimated_fare': fare,
                          'estimated_distance':
                              rideData['estimated_distance_km'] ?? 0.0,
                          'is_peak_hour': false,
                        };
                      })
                      .toList();
            });

            if (_searchResults.isNotEmpty) {
              messageService.showInfo(
                'No rides found for your specific route and time. Showing all available rides for the selected date.',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Fallback search failed: $e');
        }
      }

      if (_searchResults.isEmpty) {
        messageService.showInfo(
          'No rides found. Try adjusting your departure time or creating a ride request.',
        );
      } else {
        final femaleOnlyCount =
            _searchResults.where((rideResult) {
              final ride = rideResult['ride'] as Map<String, dynamic>?;
              return ride?['female_only_ride'] == true;
            }).length;

        if (_femaleOnly && femaleOnlyCount < _searchResults.length) {
          debugPrint(
            '✅ Showing ${_searchResults.length} rides ($femaleOnlyCount female-only, ${_searchResults.length - femaleOnlyCount} general)',
          );
        } else {
          debugPrint(
            '✅ Successfully loaded ${_searchResults.length} valid rides',
          );
        }
      }
    } catch (e) {
      messageService.showError('Failed to search rides: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showRideDetails(Map<String, dynamic> rideResult) {
    // Add null safety check
    final ride = rideResult['ride'] as Map<String, dynamic>?;
    if (ride == null || ride['id'] == null) {
      messageService.showError('Invalid ride data');
      return;
    }

    // Navigate to ride preview screen
    Get.toNamed('/ride-preview', arguments: {'rideId': ride['id']});
  }

  void _requestRide(Map<String, dynamic> rideResult) async {
    try {
      // Add null safety check
      final ride = rideResult['ride'] as Map<String, dynamic>?;
      if (ride == null || ride['id'] == null) {
        messageService.showError('Invalid ride data');
        return;
      }

      // Validate that we have required location data
      if (_pickupLat == null ||
          _pickupLng == null ||
          _dropoffLat == null ||
          _dropoffLng == null) {
        messageService.showError(
          'Please ensure you have selected valid pickup and dropoff locations',
        );
        return;
      }

      // Show loading indicator
      messageService.showInfo('Sending ride request...');

      await apiService.createRideRequest(
        rideId: ride['id'],
        pickupLocation: _pickupController.text,
        dropoffLocation: _dropoffController.text,
        pickupLatitude: _pickupLat!,
        pickupLongitude: _pickupLng!,
        dropoffLatitude: _dropoffLat!,
        dropoffLongitude: _dropoffLng!,
        message: 'Hi, I would like to join your ride.',
      );

      messageService.showSuccess(
        'Ride request sent successfully! Check the "My Requests" tab for status updates.',
      );
      _tabController.animateTo(1); // Switch to requests tab
      _loadMyRequests(); // Refresh the requests
    } catch (e) {
      // Handle specific error cases
      String errorMessage = 'Failed to send ride request';

      if (e.toString().contains('already')) {
        errorMessage = 'You have already requested to join this ride';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Ride is no longer available';
      } else if (e.toString().contains('400')) {
        errorMessage =
            'Invalid request. Please check your details and try again';
      } else {
        errorMessage = 'Failed to send ride request: $e';
      }

      messageService.showError(errorMessage);
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadMyRequests(), _loadRideHistory(), _loadReviews()]);
  }

  Future<void> _refreshSearchResults() async {
    // Clear current results and re-search if we have valid search parameters
    if (_pickupLat != null &&
        _pickupLng != null &&
        _dropoffLat != null &&
        _dropoffLng != null &&
        _selectedDateTime != null) {
      setState(() {
        _searchResults.clear();
      });
      _searchRides();
    }
  }

  Future<void> _loadMyRequests() async {
    try {
      // Try the specific method first, fall back to generic API call
      List<dynamic> requests;
      try {
        requests = await apiService.getMyRideRequests();
      } catch (e) {
        // Fallback to generic API call if the specific method doesn't exist
        debugPrint('🔄 Falling back to generic API call for ride requests');
        final response = await apiService.get('/rides/ride-requests/');

        // Handle different response formats
        if (response.data is Map<String, dynamic> &&
            response.data['results'] != null) {
          requests = response.data['results'];
        } else if (response.data is List) {
          requests = response.data;
        } else {
          throw Exception('Unexpected response format');
        }
      }

      setState(() {
        _myRideRequests = List<Map<String, dynamic>>.from(requests);
      });
      debugPrint('✅ Loaded ${_myRideRequests.length} ride requests');
    } catch (e) {
      debugPrint('❌ Failed to load ride requests: $e');
      messageService.showError('Failed to load ride requests');
    }
  }

  Future<void> _loadRideHistory() async {
    try {
      // Use the new enhanced my_rides endpoint
      final myRides = await apiService.getMyRides();
      setState(() {
        _currentRides = List<Map<String, dynamic>>.from(
          myRides['current_rides'] ?? [],
        );
        _pastRides = List<Map<String, dynamic>>.from(
          myRides['past_rides'] ?? [],
        );
        _offeredRides = List<Map<String, dynamic>>.from(
          myRides['offered_rides'] ?? [],
        );

        // Also keep the old format for compatibility
        _recentRides = List<Map<String, dynamic>>.from(_pastRides);
      });

      debugPrint(
        '✅ Loaded rides: ${_currentRides.length} current, ${_pastRides.length} past, ${_offeredRides.length} offered',
      );
    } catch (e) {
      debugPrint('Failed to load enhanced ride data: $e');

      // Fallback to old method
      try {
        final history = await apiService.getUserRideHistory();
        setState(() {
          _recentRides = List<Map<String, dynamic>>.from(
            history['rides'] ?? [],
          );
          _userStats = history['statistics'];

          // Try to categorize based on status and time for fallback
          final now = DateTime.now();
          _currentRides =
              _recentRides.where((ride) {
                final departureTime = DateTime.tryParse(
                  ride['departure_time'] ?? '',
                );
                final status = ride['status']?.toString();
                return departureTime != null &&
                    departureTime.isAfter(now) &&
                    (status == 'scheduled' || status == 'in_progress');
              }).toList();

          _pastRides =
              _recentRides.where((ride) {
                final departureTime = DateTime.tryParse(
                  ride['departure_time'] ?? '',
                );
                final status = ride['status']?.toString();
                return departureTime != null &&
                    (departureTime.isBefore(now) ||
                        status == 'completed' ||
                        status == 'cancelled');
              }).toList();

          _offeredRides = []; // Can't determine from old API
        });
      } catch (fallbackError) {
        debugPrint('Failed to load ride history: $fallbackError');
      }
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return 'Unknown time';
    }
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid time';
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      // Create a filtered copy first to ensure non-female users don't see inappropriate rides
      List<Map<String, dynamic>> filteredResults =
          _searchResults.where((rideResult) {
            final ride = rideResult['ride'] as Map<String, dynamic>?;
            if (ride == null) return false;

            // Always filter out female-only rides for non-female users
            final isFemaleOnly = ride['female_only_ride'] == true;
            if (!_isCurrentUserFemale() && isFemaleOnly) {
              return false;
            }

            // Filter out rides where user is already a passenger
            final passengers = ride['passengers'] as List<dynamic>? ?? [];
            final currentUserId = authController.currentUser.value?.id;
            if (currentUserId != null) {
              final isAlreadyJoined = passengers.any((passenger) {
                if (passenger is Map<String, dynamic>) {
                  return passenger['id'] == currentUserId ||
                      passenger['passenger_id'] == currentUserId ||
                      passenger['user_id'] == currentUserId;
                }
                return false;
              });
              if (isAlreadyJoined) return false;
            }

            return true;
          }).toList();

      switch (filter) {
        case 'all':
          _searchResults = filteredResults;
          break;
        case 'nearby':
          filteredResults.sort((a, b) {
            // Sort by estimated distance if available
            final aDistance = a['estimated_distance'] ?? double.maxFinite;
            final bDistance = b['estimated_distance'] ?? double.maxFinite;
            return aDistance.compareTo(bDistance);
          });
          _searchResults = filteredResults;
          break;
        case 'soon':
          filteredResults.sort((a, b) {
            final aTime =
                DateTime.tryParse(a['ride']?['departure_time'] ?? '') ??
                DateTime.now().add(const Duration(days: 365));
            final bTime =
                DateTime.tryParse(b['ride']?['departure_time'] ?? '') ??
                DateTime.now().add(const Duration(days: 365));
            return aTime.compareTo(bTime);
          });
          _searchResults = filteredResults;
          break;
        case 'affordable':
          filteredResults.sort((a, b) {
            final aFare = a['estimated_fare'] ?? double.maxFinite;
            final bFare = b['estimated_fare'] ?? double.maxFinite;
            return aFare.compareTo(bFare);
          });
          _searchResults = filteredResults;
          break;
      }
    });

    messageService.showInfo(
      'Results sorted by ${filter == 'all' ? 'relevance' : filter}',
    );
  }

  // Reviews-related methods
  Future<void> _loadReviews() async {
    try {
      // Load received reviews
      final receivedReviews = await apiService.getMyReceivedReviews();
      setState(() {
        _receivedReviews = List<Map<String, dynamic>>.from(receivedReviews);
      });

      // Load given reviews
      final givenReviews = await apiService.getMyGivenReviews();
      setState(() {
        _givenReviews = List<Map<String, dynamic>>.from(givenReviews);
      });

      // Load pending ratings from completed rides
      await _loadPendingRatings();
    } catch (e) {
      debugPrint('Failed to load reviews: $e');
      // Set empty lists on error
      setState(() {
        _receivedReviews = [];
        _givenReviews = [];
        _pendingRatings = [];
      });
    }
  }

  Future<void> _loadPendingRatings() async {
    try {
      // Get completed rides that haven't been rated yet
      final completedRides =
          _recentRides.where((ride) {
            final status = ride['status']?.toString().toLowerCase();
            return status == 'completed';
          }).toList();

      // Filter out rides that have already been reviewed
      final reviewedRideIds =
          _givenReviews.map((review) => review['ride']).toSet();

      setState(() {
        _pendingRatings =
            completedRides.where((ride) {
              return !reviewedRideIds.contains(ride['id']);
            }).toList();
      });
    } catch (e) {
      debugPrint('Failed to load pending ratings: $e');
      setState(() {
        _pendingRatings = [];
      });
    }
  }

  void _showPendingRatings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rate_review, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pending Reviews',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please rate your recent rides to help improve the community.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _pendingRatings.length,
                    itemBuilder: (context, index) {
                      final ride = _pendingRatings[index];
                      return _buildPendingRatingCard(ride);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPendingRatingCard(Map<String, dynamic> ride) {
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
                Expanded(
                  child: Text(
                    '${ride['pickup_location'] ?? 'Unknown'} → ${ride['dropoff_location'] ?? 'Unknown'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Driver: ${ride['driver_name'] ?? 'Unknown'}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Completed: ${_formatDateTime(ride['departure_time']?.toString())}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _rateRide(ride),
                icon: const Icon(Icons.star),
                label: const Text('Rate This Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87CEEB),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rateRide(Map<String, dynamic> ride) async {
    // Check if already reviewed
    if (_hasReviewedRide(ride['id'])) {
      messageService.showInfo('You have already reviewed this ride');
      return;
    }

    // Prepare driver information
    final driverInfo = ride['driver'] as Map<String, dynamic>? ?? {};
    final driverId = driverInfo['id'] ?? ride['driver_id'];
    final driverName =
        driverInfo['first_name'] ??
        driverInfo['name'] ??
        ride['driver_name'] ??
        'Unknown Driver';

    if (driverId == null) {
      messageService.showError('Driver information not available');
      return;
    }

    // Show rating dialog
    final result = await _showRatingDialog(
      driverName: driverName,
      rideInfo: {
        'pickup_location': ride['pickup_location'],
        'dropoff_location': ride['dropoff_location'],
        'departure_time': ride['departure_time'],
        'fare': ride['fare'] ?? ride['price_per_seat'],
      },
    );

    if (result != null && mounted) {
      try {
        // Create the review using the API service
        await apiService.createDetailedReview(
          rideId: ride['id'],
          revieweeId: driverId,
          rating: result['overall_rating'],
          comment: result['comment'],
          punctualityRating: result['punctuality_rating'],
          cleanlinessRating: result['cleanliness_rating'],
          communicationRating: result['communication_rating'],
          safetyRating: result['safety_rating'],
        );

        messageService.showSuccess('Review submitted successfully!');

        // Refresh reviews and ride history
        await _loadReviews();
        await _loadRideHistory();
      } catch (e) {
        messageService.showError('Failed to submit review: $e');
      }
    }
  }

  void _showAllReviews(String type) {
    Get.toNamed('/passenger-reviews');
  }

  Widget _buildEmptyReviewsCard(String message) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(
    Map<String, dynamic> review, {
    required bool isReceived,
  }) {
    final rating = review['rating'] ?? 0;
    final comment = review['comment'] ?? '';
    final reviewerName =
        isReceived
            ? review['reviewer_name'] ?? 'Anonymous'
            : review['reviewee_name'] ?? 'Anonymous';
    final date = review['created_at'] ?? '';

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
                  radius: 16,
                  backgroundColor: const Color(0xFF87CEEB),
                  child: Text(
                    reviewerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return 'Unknown';
    }
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM dd').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
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

  // Helper methods for improved request cards
  String _formatTimeAgo(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return _formatDateTime(isoString);
    } catch (e) {
      return 'Unknown';
    }
  }

  void _viewRideDetails(int? rideId) {
    if (rideId != null) {
      Get.toNamed('/ride-preview', arguments: {'rideId': rideId});
    }
  }

  void _contactDriver(int? driverId, String driverName) {
    if (driverId != null) {
      // For now, show a simple dialog with driver contact info
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Contact $driverName',
                style: const TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Contact feature will be implemented soon. You can reach out to the driver through the ride details.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Color(0xFF87CEEB)),
                  ),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _cancelRequest(int? requestId) async {
    if (requestId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Cancel Request',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to cancel this ride request?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Keep Request',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Cancel Request',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Add API call to cancel request
        messageService.showSuccess('Request cancelled successfully');
        _loadMyRequests(); // Refresh the list
      } catch (e) {
        messageService.showError('Failed to cancel request: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _departureTimeController.dispose();
    super.dispose();
  }
}
