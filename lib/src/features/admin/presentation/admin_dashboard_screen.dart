import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../user_profile/presentation/user_profile_screen.dart';
import '../../../screens/notification_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final MessageService messageService = Get.find<MessageService>();
  final AdminService adminService = Get.find<AdminService>();

  late TabController _tabController;
  
  // Data
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _allRides = [];
  List<Map<String, dynamic>> _activeRides = [];
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>> _recentActivity = [];
  
  bool _isLoading = true;
  String _selectedUserFilter = 'all'; // all, drivers, passengers, admins
  String _selectedRideFilter = 'all'; // all, active, completed, cancelled

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAdminData,
            tooltip: 'Refresh Data',
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
            Tab(text: 'Users'),
            Tab(text: 'Rides'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildRidesTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      color: const Color(0xFF87CEEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Grid
            const Text(
              'System Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Total Users',
                  '${_allUsers.length}',
                  Icons.people,
                  const Color(0xFF87CEEB),
                ),
                _buildStatCard(
                  'Active Rides',
                  '${_activeRides.length}',
                  Icons.directions_car,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Rides',
                  '${_allRides.length}',
                  Icons.route,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Drivers',
                  '${_allUsers.where((u) => u['is_driver'] == true).length}',
                  Icons.drive_eta,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _recentActivity.isNotEmpty
                    ? Column(
                        children: _buildRecentActivityItems(),
                      )
                    : const Column(
                        children: [
                          Text(
                            'No recent activity available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'View All Users',
                    Icons.people,
                    () => _tabController.animateTo(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Monitor Rides',
                    Icons.monitor,
                    () => _tabController.animateTo(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers = _getFilteredUsers();
    
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUserFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter Users',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'drivers', child: Text('Drivers')),
                    DropdownMenuItem(value: 'passengers', child: Text('Passengers')),
                    DropdownMenuItem(value: 'admins', child: Text('Admins')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUserFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filteredUsers.length} users',
                  style: const TextStyle(
                    color: Color(0xFF87CEEB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Users List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            color: const Color(0xFF87CEEB),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Added bottom padding
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return _buildUserCard(user);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRidesTab() {
    final filteredRides = _getFilteredRides();
    
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRideFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter Rides',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Rides')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRideFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filteredRides.length} rides',
                  style: const TextStyle(
                    color: Color(0xFF87CEEB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Rides List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRides,
            color: const Color(0xFF87CEEB),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Added bottom padding
              itemCount: filteredRides.length,
              itemBuilder: (context, index) {
                final ride = filteredRides[index];
                return _buildRideCard(ride);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: const Color(0xFF87CEEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics & Reports',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // User Growth Chart
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Growth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 48,
                              color: const Color(0xFF87CEEB),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'User Growth Chart',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Chart visualization coming soon',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ride Statistics
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ride Statistics',
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
                          child: _buildAnalyticsItem(
                            'Today',
                            '${_analyticsData?['today_rides'] ?? 0}',
                            Icons.today,
                          ),
                        ),
                        Expanded(
                          child: _buildAnalyticsItem(
                            'This Week',
                            '${_analyticsData?['week_rides'] ?? 0}',
                            Icons.date_range,
                          ),
                        ),
                        Expanded(
                          child: _buildAnalyticsItem(
                            'This Month',
                            '${_analyticsData?['month_rides'] ?? 0}',
                            Icons.calendar_month,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Performance Metrics
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Metrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMetricRow('Average Rating', '${_analyticsData?['avg_rating']?.toStringAsFixed(1) ?? '0.0'}', Icons.star),
                    _buildMetricRow('Completion Rate', '${_analyticsData?['completion_rate'] ?? 0}%', Icons.check_circle),
                    _buildMetricRow('Total Revenue', 'PKR ${_analyticsData?['total_revenue'] ?? 0}', Icons.monetization_on),
                    _buildMetricRow('Active Drivers', '${_analyticsData?['active_drivers'] ?? 0}', Icons.drive_eta),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivityItems() {
    List<Widget> items = [];
    
    for (int i = 0; i < _recentActivity.length; i++) {
      final activity = _recentActivity[i];
      final action = activity['action'] ?? '';
      final timestamp = activity['timestamp'];
      final type = activity['type'] ?? '';
      
      // Format timestamp to relative time
      String timeAgo = 'Unknown';
      if (timestamp != null) {
        try {
          final activityTime = DateTime.parse(timestamp.toString());
          final now = DateTime.now();
          final difference = now.difference(activityTime);
          
          if (difference.inMinutes < 1) {
            timeAgo = 'Just now';
          } else if (difference.inMinutes < 60) {
            timeAgo = '${difference.inMinutes} minutes ago';
          } else if (difference.inHours < 24) {
            timeAgo = '${difference.inHours} hours ago';
          } else {
            timeAgo = '${difference.inDays} days ago';
          }
        } catch (e) {
          timeAgo = 'Recently';
        }
      }
      
      // Determine icon and color based on type
      IconData icon = Icons.info;
      Color color = const Color(0xFF87CEEB);
      
      switch (type) {
        case 'user_registration':
          icon = Icons.person_add;
          color = Colors.green;
          break;
        case 'ride_created':
          icon = Icons.add_road;
          color = const Color(0xFF87CEEB);
          break;
        case 'ride_completed':
          icon = Icons.check_circle;
          color = Colors.blue;
          break;
        default:
          // Fallback to action-based detection
          if (action.toLowerCase().contains('user') && action.toLowerCase().contains('register')) {
            icon = Icons.person_add;
            color = Colors.green;
          } else if (action.toLowerCase().contains('ride') && action.toLowerCase().contains('completed')) {
            icon = Icons.check_circle;
            color = Colors.blue;
          } else if (action.toLowerCase().contains('ride') && action.toLowerCase().contains('created')) {
            icon = Icons.add_road;
            color = const Color(0xFF87CEEB);
          }
      }
      
      items.add(_buildActivityItem(
        action,
        timeAgo,
        icon,
        color,
      ));
      
      // Add divider except for the last item
      if (i < _recentActivity.length - 1) {
        items.add(const Divider(color: Colors.grey));
      }
    }
    
    return items;
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF87CEEB),
              child: Text(
                (user['first_name'] ?? 'U')[0].toUpperCase(),
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
                    '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user['email'] ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getUserRoleColor(user['role']).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (user['role'] ?? 'user').toUpperCase(),
                          style: TextStyle(
                            color: _getUserRoleColor(user['role']),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (user['is_driver'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'DRIVER',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (value) => _handleUserAction(user, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Text('View Details'),
                ),
                const PopupMenuItem(
                  value: 'suspend',
                  child: Text('Suspend User'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete User', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
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
                    '${ride['pickup_location']} → ${ride['dropoff_location']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRideStatusColor(ride['status']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (ride['status'] as String).toUpperCase(),
                    style: TextStyle(
                      color: _getRideStatusColor(ride['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (ride['status'] == 'in_progress' || ride['status'] == 'scheduled')
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: Colors.grey[800],
                    onSelected: (action) => _handleRideAction(ride, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('View Details', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Cancel Ride', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Driver: ${ride['driver_name'] ?? 'Unknown'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              'Passengers: ${ride['passenger_count'] ?? 0}/${ride['total_seats'] ?? 0}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              _formatDateTime(ride['departure_time']),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF87CEEB), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF87CEEB), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'driver':
        return Colors.blue;
      default:
        return const Color(0xFF87CEEB);
    }
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

  List<Map<String, dynamic>> _getFilteredUsers() {
    switch (_selectedUserFilter) {
      case 'drivers':
        return _allUsers.where((u) => u['is_driver'] == true).toList();
      case 'passengers':
        return _allUsers.where((u) => u['is_driver'] != true && u['role'] != 'admin').toList();
      case 'admins':
        return _allUsers.where((u) => u['role'] == 'admin').toList();
      default:
        return _allUsers;
    }
  }

  List<Map<String, dynamic>> _getFilteredRides() {
    switch (_selectedRideFilter) {
      case 'active':
        return _allRides.where((r) => r['status'] == 'in_progress' || r['status'] == 'scheduled').toList();
      case 'completed':
        return _allRides.where((r) => r['status'] == 'completed').toList();
      case 'cancelled':
        return _allRides.where((r) => r['status'] == 'cancelled').toList();
      default:
        return _allRides;
    }
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadUsers(),
        _loadRides(),
        _loadAnalytics(),
        _loadRecentActivity(),
      ]);
    } catch (e) {
      messageService.showError('Failed to load admin data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await adminService.getAllUsers();
      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(users);
      });
    } catch (e) {
      debugPrint('Failed to load users: $e');
      // Show user-friendly error
      if (e.toString().contains('403') || e.toString().contains('Permission denied')) {
        messageService.showError('Access denied. Admin privileges required.');
      } else {
        messageService.showError('Failed to load users data');
      }
    }
  }

  Future<void> _loadRides() async {
    try {
      final rides = await adminService.getAllRides();
      setState(() {
        _allRides = List<Map<String, dynamic>>.from(rides);
        _activeRides = _allRides.where((r) => 
          r['status'] == 'in_progress' || r['status'] == 'scheduled'
        ).toList();
      });
    } catch (e) {
      debugPrint('Failed to load rides: $e');
      if (e.toString().contains('403') || e.toString().contains('Permission denied')) {
        messageService.showError('Access denied. Admin privileges required.');
      } else {
        messageService.showError('Failed to load rides data');
      }
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analyticsData = await adminService.getAnalytics();
      setState(() {
        _analyticsData = Map<String, dynamic>.from(analyticsData);
      });
    } catch (e) {
      debugPrint('Failed to load analytics: $e');
      if (e.toString().contains('403') || e.toString().contains('Permission denied')) {
        messageService.showError('Access denied. Admin privileges required.');
      } else {
        messageService.showError('Failed to load analytics data');
      }
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final recentActivity = await adminService.getRecentActivity();
      setState(() {
        _recentActivity = List<Map<String, dynamic>>.from(recentActivity);
      });
    } catch (e) {
      debugPrint('Failed to load recent activity: $e');
      if (e.toString().contains('403') || e.toString().contains('Permission denied')) {
        messageService.showError('Access denied. Admin privileges required.');
      } else {
        messageService.showError('Failed to load recent activity data');
      }
    }
  }

  void _handleUserAction(Map<String, dynamic> user, String action) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'suspend':
        _suspendUser(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  void _handleRideAction(Map<String, dynamic> ride, String action) {
    switch (action) {
      case 'view':
        _showRideDetails(ride);
        break;
      case 'cancel':
        _cancelRide(ride);
        break;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'User Details',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user['first_name']} ${user['last_name']}', style: const TextStyle(color: Colors.white70)),
            Text('Email: ${user['email']}', style: const TextStyle(color: Colors.white70)),
            Text('Role: ${user['role']}', style: const TextStyle(color: Colors.white70)),
            Text('Driver: ${user['is_driver'] ? 'Yes' : 'No'}', style: const TextStyle(color: Colors.white70)),
            Text('Joined: ${_formatDateTime(user['date_joined'])}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF87CEEB))),
          ),
        ],
      ),
    );
  }

  void _suspendUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Suspend User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to suspend ${user['first_name']} ${user['last_name']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Suspend', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await adminService.suspendUser(user['id']);
        messageService.showSuccess('User suspended successfully');
        _loadUsers(); // Refresh the user list
      } catch (e) {
        debugPrint('Failed to suspend user: $e');
        if (e.toString().contains('403') || e.toString().contains('Permission denied')) {
          messageService.showError('Access denied. Admin privileges required.');
        } else {
          messageService.showError('Failed to suspend user');
        }
      }
    }
  }

  void _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete User', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete ${user['first_name']} ${user['last_name']}?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await adminService.deleteUser(user['id']);
        messageService.showSuccess('User deleted successfully');
        _loadUsers(); // Refresh the user list
      } catch (e) {
        debugPrint('Failed to delete user: $e');
        if (e.toString().contains('403') || e.toString().contains('Permission denied')) {
          messageService.showError('Access denied. Admin privileges required.');
        } else {
          messageService.showError('Failed to delete user');
        }
      }
    }
  }

  void _showRideDetails(Map<String, dynamic> ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Ride Details',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', '${ride['id']}'),
              _buildDetailRow('From', '${ride['pickup_location']}'),
              _buildDetailRow('To', '${ride['dropoff_location']}'),
              _buildDetailRow('Driver', '${ride['driver_name'] ?? 'Unknown'}'),
              _buildDetailRow('Status', '${ride['status']}'),
              _buildDetailRow('Passengers', '${ride['passenger_count'] ?? 0}/${ride['total_seats'] ?? 0}'),
              _buildDetailRow('Departure', _formatDateTime(ride['departure_time'])),
              if (ride['price'] != null) _buildDetailRow('Price', '\$${ride['price']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF87CEEB))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelRide(Map<String, dynamic> ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Cancel Ride', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to cancel this ride from ${ride['pickup_location']} to ${ride['dropoff_location']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Ride', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await adminService.cancelRide(ride['id'], 'Cancelled by admin');
        messageService.showSuccess('Ride cancelled successfully');
        _loadRides(); // Refresh the rides list
      } catch (e) {
        debugPrint('Failed to cancel ride: $e');
        if (e.toString().contains('403') || e.toString().contains('Permission denied')) {
          messageService.showError('Access denied. Admin privileges required.');
        } else {
          messageService.showError('Failed to cancel ride');
        }
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
