import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../core/services/api_service.dart';
import '../../../core/services/fare_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/services/rides_data_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/vehicle_controller.dart';
import '../../../core/models/ride_models.dart';
import '../../../core/models/vehicle.dart';
import '../../../services/route_calculation_service.dart';
import '../../common/presentation/improved_route_location_picker.dart';

final ApiService apiService = Get.find<ApiService>();

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();
  final VehicleController vehicleController = Get.find<VehicleController>();
  final MessageService messageService = Get.find<MessageService>();
  final ApiService apiService = Get.find<ApiService>();
  final FareCalculationService fareService = FareCalculationService.instance;
  final RouteCalculationService _routeService = RouteCalculationService();
  
  // Periodic refresh timer for verification status
  Timer? _refreshTimer;
  
  // Form controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Location coordinates (would be set by location picker)
  double? _pickupLat, _pickupLng, _dropoffLat, _dropoffLng;
  double? _routeDistanceKm;
  String _routePreference = 'fastest'; // Default route preference, can be updated by location picker
  
  bool _femaleOnly = false;
  bool _isLoading = false;
  bool _isInitializingVehicles = true;
  bool _isRefreshingStatus = false;
  DateTime? _selectedDateTime;
  FareBreakdown? _fareBreakdown;
  Vehicle? _selectedVehicle;
  
  // Driver verification status from API
  Map<String, dynamic>? _verificationData;

  // Calculate available seats based on selected vehicle
  int get _availableSeats {
    if (_selectedVehicle == null) return 0;
    // Total seats minus driver seat = available passenger seats
    return _selectedVehicle!.totalSeats - 1;
  }

  // Helper method to check if current user is female
  bool _isCurrentUserFemale() {
    final user = authController.currentUser.value;
    if (user == null) {
      debugPrint('🔍 CreateRideScreen: No user found');
      return false;
    }
    
    // Check the gender field - handle potential null/empty values
    final gender = user.gender.trim().toLowerCase();
    debugPrint('🔍 CreateRideScreen: User gender = "$gender"');
    final isFemale = gender == 'female' || gender == 'f' || gender == 'woman';
    debugPrint('🔍 CreateRideScreen: Is female = $isFemale');
    return isFemale;
  }

  @override
  void initState() {
    super.initState();
    
    debugPrint('🔍 CreateRideScreen: Initializing...');
    
    // Check authentication before making API calls
    _checkAuthAndInitialize();
    
    // Ensure female-only option is only available for female drivers
    if (!_isCurrentUserFemale()) {
      _femaleOnly = false;
    }
    
    debugPrint('🔍 CreateRideScreen: Initial female-only state = $_femaleOnly');
    
    // Set up periodic refresh for verification status (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAuthAndRefresh();
    });
  }

  Future<void> _checkAuthAndInitialize() async {
    // Check if user is authenticated before making any API calls
    if (!authController.isLoggedIn.value) {
      debugPrint('🔒 CreateRideScreen: User not authenticated, redirecting to login');
      Get.offAllNamed('/login');
      return;
    }
    
    // Refresh user data and load verification status to get latest verification status
    _refreshUserData();
    
    // Load vehicles if not already loaded
    _initializeVehicles();
  }

  Future<void> _checkAuthAndRefresh() async {
    // Check authentication before periodic refresh
    if (!authController.isLoggedIn.value) {
      debugPrint('🔒 CreateRideScreen: User not authenticated, stopping periodic refresh');
      _refreshTimer?.cancel();
      return;
    }
    
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    if (_isRefreshingStatus) return; // Prevent multiple simultaneous refreshes
    
    setState(() {
      _isRefreshingStatus = true;
    });
    
    try {
      debugPrint('🔄 CreateRideScreen: Refreshing user data for latest verification status...');
      
      // Refresh both user data and verification status from API
      await Future.wait([
        authController.refreshUserData(),
        _loadVerificationStatus(),
      ]);
      
      debugPrint('✅ CreateRideScreen: User data and verification status refreshed successfully');
      
      // Force a rebuild of the widget to show updated verification status
      if (mounted) {
        setState(() {
          // This will trigger a rebuild to show the updated verification status
        });
      }
    } catch (e) {
      debugPrint('❌ CreateRideScreen: Failed to refresh user data: $e');
      if (mounted) {
        messageService.showError('Failed to refresh verification status');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingStatus = false;
        });
      }
    }
  }

  Future<void> _loadVerificationStatus() async {
    try {
      debugPrint('🔍 CreateRideScreen: Loading driver verification status from API...');
      final verificationData = await apiService.getDriverVerificationStatus();
      
      if (verificationData != null) {
        setState(() {
          _verificationData = verificationData;
        });
        debugPrint('✅ CreateRideScreen: Verification status loaded: ${verificationData['verification_status']}');
      } else {
        debugPrint('⚠️ CreateRideScreen: No verification data received from API');
      }
    } catch (e) {
      debugPrint('❌ CreateRideScreen: Failed to load verification status: $e');
      // Don't show error message as this is a background operation
    }
  }

  Future<void> _initializeVehicles() async {
    setState(() {
      _isInitializingVehicles = true;
    });
    
    try {
      debugPrint('🚗 CreateRideScreen: Initializing vehicles...');
      
      // Force reload vehicles to ensure fresh data
      await vehicleController.loadVehicles();
      
      debugPrint('🚗 CreateRideScreen: Vehicles loaded, count: ${vehicleController.vehicles.length}');
      
      // Auto-select the first vehicle if available when vehicles are loaded
      if (vehicleController.vehicles.isNotEmpty && _selectedVehicle == null) {
        setState(() {
          _selectedVehicle = vehicleController.vehicles.first;
        });
        debugPrint('🚗 CreateRideScreen: Auto-selected first vehicle: ${_selectedVehicle!.make} ${_selectedVehicle!.model}');
      } else {
        debugPrint('🚗 CreateRideScreen: No vehicles available to auto-select');
      }
    } catch (e) {
      debugPrint('❌ CreateRideScreen: Failed to initialize vehicles: $e');
    } finally {
      setState(() {
        _isInitializingVehicles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background like login page
      appBar: AppBar(
        title: const Text('Create Ride', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _isRefreshingStatus ? null : _refreshUserData,
            icon: _isRefreshingStatus 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshUserData();
          await _initializeVehicles();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildVerificationStatus(),
                const SizedBox(height: 16),
                _buildLocationSection(),
                const SizedBox(height: 24),
                _buildRideDetailsSection(),
                const SizedBox(height: 24),
                _buildVehicleSelectionSection(),
                const SizedBox(height: 24),
                Obx(() => _buildOptionsSection()),
                const SizedBox(height: 24),
                if (_fareBreakdown != null) _buildFareSection(),
                const SizedBox(height: 32),
                _buildCreateButton(),
                const SizedBox(height: 32), // Bottom padding for create button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_road,
              size: 48,
              color: Color(0xFF0EA5E9),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create New Ride',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: const Text(
              'Offer rides to passengers and share travel costs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Obx(() {
      final user = authController.currentUser.value;
      
      // Use API data if available, otherwise fall back to user model
      String verificationStatus;
      if (_verificationData != null) {
        verificationStatus = _verificationData!['verification_status']?.toString() ?? 'pending';
      } else {
        verificationStatus = user?.driverVerificationStatus ?? 'pending';
      }
      
      // Debug logging to help troubleshoot
      debugPrint('🔍 CreateRideScreen: Current verification status: $verificationStatus');
      debugPrint('🔍 CreateRideScreen: API data available: ${_verificationData != null}');
      debugPrint('🔍 CreateRideScreen: User model status: ${user?.driverVerificationStatus}');
      
      // Determine colors and text based on verification status
      Color backgroundColor, borderColor, textColor;
      IconData statusIcon;
      String statusTitle, statusDescription;
      bool showVerifyButton = false;

      switch (verificationStatus) {
        case 'verified':
          backgroundColor = Colors.green.shade50;
          borderColor = Colors.green.shade300;
          textColor = Colors.green.shade700;
          statusIcon = Icons.verified;
          statusTitle = 'Driver Verified ✓';
          statusDescription = 'You can create rides and accept passengers';
          break;
        case 'under_review':
          backgroundColor = Colors.orange.shade50;
          borderColor = Colors.orange.shade300;
          textColor = Colors.orange.shade700;
          statusIcon = Icons.rate_review;
          statusTitle = 'Verification Under Review';
          statusDescription = 'Your documents are being reviewed. You\'ll be notified once approved.';
          showVerifyButton = true;
          break;
        case 'rejected':
          backgroundColor = Colors.red.shade50;
          borderColor = Colors.red.shade300;
          textColor = Colors.red.shade700;
          statusIcon = Icons.cancel;
          statusTitle = 'Verification Rejected';
          statusDescription = 'Please resubmit your verification documents';
          showVerifyButton = true;
          break;
        default: // pending or any other status
          backgroundColor = Colors.grey.shade50;
          borderColor = Colors.grey.shade300;
          textColor = Colors.grey.shade700;
          statusIcon = Icons.hourglass_empty;
          statusTitle = 'Driver Verification Required';
          statusDescription = 'Complete verification to start offering rides';
          showVerifyButton = true;
      }
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: textColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              statusTitle,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_isRefreshingStatus)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(textColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showVerifyButton)
                  TextButton(
                    onPressed: () => Get.toNamed('/driver-verification'),
                    style: TextButton.styleFrom(
                      backgroundColor: textColor.withValues(alpha: 0.1),
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      verificationStatus == 'under_review' ? 'View Status' : 'Verify Now',
                    ),
                  ),
              ],
            ),
            
            // Additional details for non-verified status
            if (verificationStatus != 'verified' && _verificationData != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: textColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_verificationData!['verification_submitted_at'] != null) 
                      Text(
                        'Submitted: ${_formatDateTime(_verificationData!['verification_submitted_at'])}',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    if (_verificationData!['verification_rejection_reason'] != null &&
                        _verificationData!['verification_rejection_reason'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Reason: ${_verificationData!['verification_rejection_reason']}',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '';
    
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString; // Return original string if parsing fails
    }
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map,
                  color: Color(0xFF0EA5E9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Route Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Set your pickup and destination locations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _pickupController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Pickup Location',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Tap to select pickup location on map',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.location_on, color: Colors.green),
              suffixIcon: const Icon(Icons.map, color: Color(0xFF0EA5E9)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please select pickup location';
              }
              return null;
            },
            onTap: () => _selectLocation(true),
            readOnly: true,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _dropoffController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Drop-off Location',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Tap to select destination on map',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.flag, color: Colors.red),
              suffixIcon: const Icon(Icons.map, color: Color(0xFF0EA5E9)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please select drop-off location';
              }
              return null;
            },
            onTap: () => _selectLocation(false),
            readOnly: true,
          ),
          
          // Route summary with enhanced information
          if (_pickupLat != null && _dropoffLat != null)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.route,
                        color: Color(0xFF0EA5E9),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Route Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _routeDistanceKm != null 
                                  ? 'Distance: ${_routeDistanceKm!.toStringAsFixed(1)} km'
                                  : 'Calculating distance...',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Preference: $_routePreference route',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'View Route',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRideDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF0EA5E9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ride Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Set your departure time and ride preferences',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _departureTimeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Departure Time',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Select departure date and time',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.schedule, color: Color(0xFF0EA5E9)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please select departure time';
              }
              return null;
            },
            onTap: _selectDateTime,
            readOnly: true,
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
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 28, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Seats',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_availableSeats passenger seats',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_availableSeats',
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
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Add any additional details about the ride',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.description, color: Color(0xFF0EA5E9)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Color(0xFF0EA5E9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Select Vehicle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  // Refresh vehicles
                  await vehicleController.loadVehicles();
                  // Auto-select first vehicle if none selected
                  if (vehicleController.vehicles.isNotEmpty && _selectedVehicle == null) {
                    setState(() {
                      _selectedVehicle = vehicleController.vehicles.first;
                    });
                  }
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF0EA5E9)),
                tooltip: 'Refresh Vehicles',
              ),
              IconButton(
                onPressed: () async {
                  await Get.toNamed('/vehicle-management');
                  // Refresh vehicles when coming back and auto-select if needed
                  await vehicleController.loadVehicles();
                  if (vehicleController.vehicles.isNotEmpty && _selectedVehicle == null) {
                    setState(() {
                      _selectedVehicle = vehicleController.vehicles.first;
                    });
                  }
                },
                icon: const Icon(Icons.settings, color: Color(0xFF0EA5E9)),
                tooltip: 'Manage Vehicles',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose which vehicle you\'ll use for this ride',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            // Show initialization loading state
            if (_isInitializingVehicles || vehicleController.isLoading) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading vehicles...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (vehicleController.vehicles.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No vehicles found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a vehicle to create rides',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await vehicleController.loadVehicles();
                          },
                          icon: const Icon(Icons.refresh, color: Color(0xFF0EA5E9)),
                          label: const Text(
                            'Retry',
                            style: TextStyle(color: Color(0xFF0EA5E9)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0EA5E9)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Get.toNamed('/vehicle-management');
                            await vehicleController.loadVehicles();
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add Vehicle',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            // Auto-select first vehicle if none selected and vehicles are available
            if (vehicleController.vehicles.isNotEmpty && _selectedVehicle == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedVehicle = vehicleController.vehicles.first;
                });
              });
            }

            return Column(
              children: [
                if (_selectedVehicle != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0EA5E9),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedVehicle!.make} ${_selectedVehicle!.model}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_selectedVehicle!.year} • ${_selectedVehicle!.color}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _selectedVehicle!.licensePlate,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Total Seats',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedVehicle!.totalSeats}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Available',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_availableSeats',
                                      style: const TextStyle(
                                        color: Color(0xFF0EA5E9),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showVehicleSelectionDialog,
                            icon: const Icon(Icons.swap_horiz, color: Colors.white),
                            label: const Text(
                              'Change Vehicle',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select a vehicle for this ride',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showVehicleSelectionDialog,
                          icon: const Icon(Icons.directions_car, color: Colors.white),
                          label: const Text(
                            'Select Vehicle',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    final isFemale = _isCurrentUserFemale();
    debugPrint('🔍 CreateRideScreen: Building options section, is female = $isFemale');
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF0EA5E9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ride Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure who can join your ride',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          // Only show female-only option for female drivers
          if (isFemale)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _femaleOnly ? Colors.pink.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _femaleOnly ? Icons.woman : Icons.people,
                      color: _femaleOnly ? Colors.pink : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Female Only Ride',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Only female passengers can join this ride',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _femaleOnly,
                    onChanged: (value) {
                      setState(() {
                        _femaleOnly = value;
                      });
                    },
                    activeColor: Colors.pink,
                    activeTrackColor: Colors.pink.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Female-only rides can only be created by female drivers',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
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

  Widget _buildFareSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fare Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildFareItem('Distance', fareService.getDistanceDisplayText(_fareBreakdown!.distanceKm)),
            _buildFareItem('Base Rate', 'Rs. ${_fareBreakdown!.baseFareRate.toInt()}/km'),
            _buildFareItem('Base Fare', fareService.getFareDisplayText(_fareBreakdown!.baseFare)),
            if (_fareBreakdown!.isPeakHours)
              _buildFareItem('Peak Hours', 'x${_fareBreakdown!.peakMultiplier}'),
            _buildFareItem('Total Fare', fareService.getFareDisplayText(_fareBreakdown!.totalFare), isTotal: true),
            _buildFareItem('Per Passenger', fareService.getFareDisplayText(_fareBreakdown!.farePerPerson), isHighlighted: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFareItem(String label, String value, {bool isTotal = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal || isHighlighted ? 16 : 14,
              fontWeight: isTotal || isHighlighted ? FontWeight.w600 : FontWeight.normal,
              color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal || isHighlighted ? 16 : 14,
              fontWeight: isTotal || isHighlighted ? FontWeight.w600 : FontWeight.normal,
              color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    // Get verification status
    String verificationStatus;
    if (_verificationData != null) {
      verificationStatus = _verificationData!['verification_status']?.toString() ?? 'pending';
    } else {
      verificationStatus = authController.currentUser.value?.driverVerificationStatus ?? 'pending';
    }
    
    final bool isVerified = verificationStatus == 'verified';
    final bool canCreateRide = isVerified && !_isLoading && _fareBreakdown != null;
    
    return Column(
      children: [
        // Show verification warning if not verified
        if (!isVerified)
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade400, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver Verification Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete your driver verification to create rides',
                        style: TextStyle(
                          color: Colors.orange.shade200,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: canCreateRide
                ? const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canCreateRide ? null : Colors.grey.shade600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: canCreateRide
                ? [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: canCreateRide ? _createRide : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVerified ? Icons.add_road : Icons.verified_user,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getButtonText(isVerified),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String _getButtonText(bool isVerified) {
    if (!isVerified) {
      return 'Verification Required';
    }
    
    if (_pickupLat == null || _dropoffLat == null || _selectedDateTime == null) {
      return 'Complete Details';
    }
    
    if (_fareBreakdown == null) {
      return 'Calculating Fare...';
    }
    
    return 'Create Ride';
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF0EA5E9),
              onPrimary: Colors.white,
              surface: Colors.grey[800]!,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.grey[900],
            ),
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
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF0EA5E9),
                onPrimary: Colors.white,
                surface: Colors.grey[800]!,
                onSurface: Colors.white,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.grey[900],
              ),
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
        final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        
        // Only validate that the selected datetime is not in the past
        final currentTime = DateTime.now();
        if (dateTime.isBefore(currentTime)) {
          messageService.showError('Departure time cannot be in the past');
          return;
        }
        
        setState(() {
          _selectedDateTime = dateTime;
          _departureTimeController.text = DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
        });
        _updateFareCalculation();
      }
    }
  }

  void _setCurrentDateTime() {
    final now = DateTime.now().add(const Duration(minutes: 2));
    
    setState(() {
      _selectedDateTime = now;
      _departureTimeController.text = DateFormat('MMM dd, yyyy - hh:mm a').format(now);
    });
    
    _updateFareCalculation();
    
    // Show a brief confirmation message
    messageService.showSuccess('Departure time set to 2 minutes from now');
  }

  Future<void> _showVehicleSelectionDialog() async {
    final selected = await showDialog<Vehicle>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Vehicle'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vehicleController.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleController.vehicles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.directions_car,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text('${vehicle.make} ${vehicle.model}'),
                  subtitle: Text('${vehicle.year} • ${vehicle.color} • ${vehicle.licensePlate}'),
                  trailing: _selectedVehicle?.id == vehicle.id 
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(vehicle),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedVehicle = selected;
      });
      
      // Recalculate fare with new vehicle's available seats
      _updateFareCalculation();
    }
  }

  Future<void> _selectLocation(bool isPickup) async {
    final result = await Get.to(
      () => ImprovedRouteLocationPicker(
        title: isPickup ? 'Select Pickup Location' : 'Select Drop-off Location',
        pickupLocation: _pickupLat != null && _pickupLng != null ? latlong.LatLng(_pickupLat!, _pickupLng!) : null,
        dropoffLocation: _dropoffLat != null && _dropoffLng != null ? latlong.LatLng(_dropoffLat!, _dropoffLng!) : null,
        pickupAddress: _pickupController.text.isEmpty ? null : _pickupController.text,
        dropoffAddress: _dropoffController.text.isEmpty ? null : _dropoffController.text,
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        final pickupLocation = result['pickup_location'] as latlong.LatLng?;
        final dropoffLocation = result['dropoff_location'] as latlong.LatLng?;
        
        if (pickupLocation != null) {
          _pickupLat = pickupLocation.latitude;
          _pickupLng = pickupLocation.longitude;
          _pickupController.text = result['pickup_address'] ?? '';
        }
        
        if (dropoffLocation != null) {
          _dropoffLat = dropoffLocation.latitude;
          _dropoffLng = dropoffLocation.longitude;
          _dropoffController.text = result['dropoff_address'] ?? '';
        }

        // Capture route distance and duration from the improved picker
        if (result['route_distance'] != null) {
          _routeDistanceKm = result['route_distance'] as double;
        }
        
        // Capture route preference if provided by location picker
        if (result['route_preference'] != null) {
          _routePreference = result['route_preference'] as String;
        }
      });
      
      // Calculate fare with the new route information
      if (_pickupLat != null && _dropoffLat != null) {
        _updateFareCalculation();
      }
    }
  }

  Future<void> _updateFareCalculation() async {
    if (_pickupLat != null && _dropoffLat != null && _selectedDateTime != null) {
      // Check if pickup and dropoff are the same location
      if (_pickupLat == _dropoffLat && _pickupLng == _dropoffLng) {
        setState(() {
          _fareBreakdown = null; // Clear fare for same location
        });
        return;
      }
      
      double distance;
      
      // Use our new route calculation service with built-in fallback
      try {
        final routePreference = RoutePreference.values.firstWhere(
          (pref) => _getPreferenceString(pref) == _routePreference,
          orElse: () => RoutePreference.fastest,
        );
        
        final routeResult = await _routeService.calculateRoute(
          start: latlong.LatLng(_pickupLat!, _pickupLng!),
          end: latlong.LatLng(_dropoffLat!, _dropoffLng!),
          preference: routePreference,
        );
        
        distance = routeResult.distanceKm;
        
        // Update route distance for display
        setState(() {
          _routeDistanceKm = distance;
        });
        
        // Log the result with provider information
        final provider = routeResult.metadata['provider'] ?? 'unknown';
        final duration = routeResult.durationMinutes;
        debugPrint('Route Service: Distance = ${distance}km, Duration = ${duration}min, Provider = $provider');
        
        // Show user-friendly message if fallback was used
        final fallbackUsed = routeResult.metadata['fallbackUsed'] == true;
        if (fallbackUsed) {
          debugPrint('Route calculated using fallback method (direct line estimation)');
        }
        
      } catch (e) {
        debugPrint('Route calculation service failed, using fallback distance calculation: $e');
        
        // Final fallback to straight-line distance calculation
        distance = _routeDistanceKm ?? _calculateStraightLineDistance(_pickupLat!, _pickupLng!, _dropoffLat!, _dropoffLng!);
        debugPrint('Using manual fallback distance calculation: ${distance}km');
      }
      
      // Skip calculation if distance is 0
      if (distance <= 0) {
        setState(() {
          _fareBreakdown = null;
        });
        return;
      }
      
      final fare = fareService.calculateFare(
        distanceKm: distance,
        departureTime: _selectedDateTime!,
        confirmedPassengers: _availableSeats,
      );
      
      setState(() {
        _fareBreakdown = fare;
      });
    }
  }

  /// Convert RoutePreference enum to string
  String _getPreferenceString(RoutePreference preference) {
    switch (preference) {
      case RoutePreference.fastest:
        return 'fastest';
      case RoutePreference.shortest:
        return 'shortest';
      case RoutePreference.balanced:
        return 'balanced';
    }
  }

  double _calculateStraightLineDistance(double lat1, double lng1, double lat2, double lng2) {
    // Haversine formula for accurate straight-line distance
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLatRad = (lat2 - lat1) * (pi / 180);
    final double deltaLngRad = (lng2 - lng1) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pickupLat == null || _dropoffLat == null) {
      messageService.showError('Please select pickup and drop-off locations');
      return;
    }

    // Check if pickup and dropoff are the same location
    if (_pickupLat == _dropoffLat && _pickupLng == _dropoffLng) {
      messageService.showError('Pickup and drop-off locations cannot be the same');
      return;
    }

    // Also check if location names are the same
    if (_pickupController.text.trim().toLowerCase() == _dropoffController.text.trim().toLowerCase()) {
      messageService.showError('Pickup and drop-off locations must be different');
      return;
    }

    if (_selectedVehicle == null) {
      messageService.showError('Please select a vehicle for this ride');
      return;
    }
    
    // Validate departure time is not in the past
    if (_selectedDateTime == null) {
      messageService.showError('Please select a departure time');
      return;
    }
    
    final now = DateTime.now();
    if (_selectedDateTime!.isBefore(now)) {
      messageService.showError('Departure time cannot be in the past');
      return;
    }

    // Ensure only female drivers can create female-only rides
    if (_femaleOnly && !_isCurrentUserFemale()) {
      messageService.showError('Only female drivers can create female-only rides');
      return;
    }

    // Validate that fare has been calculated
    if (_fareBreakdown == null) {
      messageService.showError('Please wait for fare calculation to complete');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final rideData = {
        'pickup_location': _pickupController.text.trim(),
        'pickup_latitude': _pickupLat != null ? double.parse(_pickupLat!.toStringAsFixed(2)) : null,
        'pickup_longitude': _pickupLng != null ? double.parse(_pickupLng!.toStringAsFixed(2)) : null,
        'dropoff_location': _dropoffController.text.trim(),
        'dropoff_latitude': _dropoffLat != null ? double.parse(_dropoffLat!.toStringAsFixed(2)) : null,
        'dropoff_longitude': _dropoffLng != null ? double.parse(_dropoffLng!.toStringAsFixed(2)) : null,
        'departure_time': _selectedDateTime!.toIso8601String(),
        'available_seats': _availableSeats,
        'female_only_ride': _femaleOnly,
        'description': _descriptionController.text.trim(),
        'vehicle_id': _selectedVehicle!.id,
        'route_preference': _routePreference,
        'estimated_distance_km': _routeDistanceKm != null ? double.parse(_routeDistanceKm!.toStringAsFixed(2)) : null,
        // Include fare information if calculated
        if (_fareBreakdown != null) 'price_per_seat': double.parse(_fareBreakdown!.farePerPerson.clamp(0.0, 999999.99).toStringAsFixed(2)),
        if (_fareBreakdown != null) 'total_seats': _availableSeats, // Only passenger seats, not including driver
      };

      await apiService.createRide(rideData);

      // Also add to local data service for immediate UI update
      final ridesService = RidesDataService();
      ridesService.addRide(rideData);

      messageService.showSuccess('Ride created successfully!');
      
      // Navigate to Driver Dashboard with My Rides tab selected
      Get.offAllNamed('/driver-dashboard', arguments: {
        'initialTabIndex': 1, // My Rides tab
      });
    } catch (e) {
      messageService.showError('Failed to create ride: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _departureTimeController.dispose();
    _descriptionController.dispose();
    _routeService.dispose(); // Dispose route service
    super.dispose();
  }
}
