import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/ride_model.dart';
import '../../../domain/models/user_model.dart';
import 'ride_details_screen.dart';

class RideSearchScreen extends StatefulWidget {
  final User currentUser;
  
  const RideSearchScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<RideSearchScreen> createState() => _RideSearchScreenState();
}

class _RideSearchScreenState extends State<RideSearchScreen> {
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  // Filter options
  String _selectedGenderFilter = 'any';
  double _maxPrice = 1000;
  int _minSeats = 1;
  bool _isLoading = false;
  
  // Search results
  List<Ride> _searchResults = [];
  
  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Ride'),
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildSearchForm(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                  ? _buildEmptyState()
                  : _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _startLocationController,
            decoration: InputDecoration(
              labelText: 'Pickup Location',
              prefixIcon: const Icon(Icons.location_on, color: Colors.green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _endLocationController,
            decoration: InputDecoration(
              labelText: 'Destination',
              prefixIcon: const Icon(Icons.location_on, color: Colors.red),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEE, MMM d').format(_selectedDate)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 8),
                        Text(_selectedTime.format(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('SEARCH'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterButton() {
    return OutlinedButton.icon(
      onPressed: _showFilterDialog,
      icon: const Icon(Icons.filter_list),
      label: const Text('FILTERS'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Rides'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gender Preference Filter
                  const Text(
                    'Gender Preference',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'any', label: Text('Any')),
                      ButtonSegment(value: 'same_gender', label: Text('Same Gender')),
                      ButtonSegment(value: 'women_only', label: Text('Women Only')),
                    ],
                    selected: <String>{_selectedGenderFilter},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _selectedGenderFilter = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Range Filter
                  const Text(
                    'Maximum Price (PKR)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'PKR ${_maxPrice.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Slider(
                          value: _maxPrice,
                          min: 0,
                          max: 2000,
                          divisions: 20,
                          onChanged: (value) {
                            setState(() {
                              _maxPrice = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Minimum Seats Filter
                  const Text(
                    'Minimum Available Seats',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _minSeats.toDouble(),
                          min: 1,
                          max: 7,
                          divisions: 6,
                          onChanged: (value) {
                            setState(() {
                              _minSeats = value.toInt();
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 30,
                        alignment: Alignment.center,
                        child: Text(
                          '$_minSeats',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  // Apply filters and close dialog
                  Navigator.of(context).pop();
                },
                child: const Text('APPLY'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _performSearch() {
    if (_startLocationController.text.isEmpty || _endLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both pickup and destination locations')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulating API call delay
    Future.delayed(const Duration(seconds: 2), () {
      // TODO: In a real app, this would be an API call to search for rides
      setState(() {
        _isLoading = false;
        _searchResults = _getMockRides();
      });
    });
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No rides found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final ride = _searchResults[index];
        return _buildRideCard(ride);
      },
    );
  }
  
  Widget _buildRideCard(Ride ride) {
    final isEligible = ride.isUserEligible(widget.currentUser);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsScreen(
                ride: ride,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: ride.driver.profilePicture != null
                    ? NetworkImage(ride.driver.profilePicture!)
                    : null,
                child: ride.driver.profilePicture == null
                    ? Text(
                        ride.driver.firstName[0] + ride.driver.lastName[0],
                        style: const TextStyle(fontSize: 20),
                      )
                    : null,
              ),
              title: Text(
                '${ride.pickupLocation} → ${ride.dropoffLocation}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'by ${ride.driver.fullName} • ${ride.driver.getGenderDisplay()}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PKR ${ride.pricePerSeat.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'per seat',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('E, MMM d • h:mm a').format(ride.departureTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.availableSeats} seats left',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: const Border(
                  top: BorderSide(color: Colors.black12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Distance and duration info
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 16),
                      const SizedBox(width: 4),
                      Text('${ride.estimatedDistanceKm.toStringAsFixed(1)} km'),
                      const SizedBox(width: 16),
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      Text('${ride.estimatedDurationMinutes} min'),
                    ],
                  ),
                  
                  // Gender preference and safety info
                  Row(
                    children: [
                      Icon(
                        ride.genderPreference == 'female_only'
                            ? Icons.woman
                            : ride.genderPreference == 'male_only'
                                ? Icons.man
                                : ride.genderPreference == 'family_only'
                                    ? Icons.family_restroom
                                    : Icons.people,
                        size: 18,
                        color: isEligible ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isEligible ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ride.getGenderPreferenceDisplay(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isEligible ? Colors.green[800] : Colors.red[800],
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
      ),
    );
  }
  
  // Temporary mock data for demonstration
  List<Ride> _getMockRides() {
    final now = DateTime.now();
    
    // Mock driver
    final driver1 = User(
      id: 101,
      firstName: 'Ahmed',
      lastName: 'Khan',
      email: 'ahmed@example.com',
      fullName: 'Ahmed Khan',
      phone: '0300-1234567',
      isVerified: true,
      role: 'user',
      averageRating: 4.7,
      hasCar: true,
      carModel: 'Honda Civic',
      carColor: 'Black',
      licensePlate: 'ABC-123',
      gender: 'male',
    );
    
    final driver2 = User(
      id: 102,
      firstName: 'Fatima',
      lastName: 'Ali',
      email: 'fatima@example.com',
      fullName: 'Fatima Ali',
      phone: '0300-7654321',
      isVerified: true,
      role: 'user',
      averageRating: 4.9,
      hasCar: true,
      carModel: 'Toyota Corolla',
      carColor: 'White',
      licensePlate: 'XYZ-789',
      gender: 'female',
    );
    
    // Mock passengers
    final passenger1 = RidePassenger(
      id: 201,
      ride: 1,
      passenger: 201,
      passengerName: 'Imran Malik',
      passengerRating: 4.5,
      passengerGender: 'male',
      createdAt: now.subtract(const Duration(days: 1)),
      status: 'confirmed',
    );
    
    final passenger2 = RidePassenger(
      id: 202,
      ride: 1,
      passenger: 202,
      passengerName: 'Saima Khan',
      passengerRating: 4.8,
      passengerGender: 'female',
      createdAt: now.subtract(const Duration(hours: 5)),
      status: 'confirmed',
    );
    
    // Mock route points
    final routePoints1 = [
      RoutePoint(latitude: 33.6844, longitude: 73.0479, sequence: 0),
      RoutePoint(latitude: 33.7294, longitude: 73.0931, sequence: 1),
    ];
    
    final routePoints2 = [
      RoutePoint(latitude: 31.5204, longitude: 74.3587, sequence: 0),
      RoutePoint(latitude: 31.4700, longitude: 74.4126, sequence: 1),
    ];
    
    // Mock stops
    final stop1 = RideStop(
      id: 1,
      locationName: 'F-10 Markaz',
      address: 'F-10 Markaz, Islamabad',
      latitude: 33.6951,
      longitude: 73.0118,
      sequence: 0,
    );
    
    final stop2 = RideStop(
      id: 2,
      locationName: 'Gaddafi Stadium',
      address: 'Main Boulevard Gulberg, Lahore',
      latitude: 31.5074,
      longitude: 74.3339,
      sequence: 0,
    );
    
    // Create mock rides
    return [
      Ride(
        id: 1,
        driver: driver1,
        driverRating: 4.7,
        departureTime: now.add(const Duration(hours: 2)),
        pickupLocation: 'F-8 Markaz, Islamabad',
        dropoffLocation: 'Bahria Town, Rawalpindi',
        totalSeats: 4,
        availableSeats: 2,
        availableSeatsDisplay: '2 seats available',
        status: 'scheduled',
        recurring: false,
        notes: 'Going to Bahria Town for work',
        pricePerSeat: 350,
        passengers: [passenger1, passenger2],
        isFull: false,
        pickupLatitude: 33.7111,
        pickupLongitude: 73.0379,
        dropoffLatitude: 33.5651,
        dropoffLongitude: 73.1244,
        timeFlexibilityMinutes: 15,
        isWorkplaceRide: true,
        comfortFeatures: {'ac': true, 'music': true},
        averageRating: 4.7,
        genderPreference: 'any',
        currentMalePassengers: 1,
        currentFemalePassengers: 1,
        estimatedDistanceKm: 18.5,
        estimatedDurationMinutes: 35,
        routePoints: routePoints1,
        hasStops: true,
        stops: [stop1],
      ),
      Ride(
        id: 2,
        driver: driver2,
        driverRating: 4.9,
        departureTime: now.add(const Duration(hours: 3)),
        pickupLocation: 'Johar Town, Lahore',
        dropoffLocation: 'DHA Phase 5, Lahore',
        totalSeats: 3,
        availableSeats: 3,
        availableSeatsDisplay: '3 seats available',
        status: 'scheduled',
        recurring: true,
        notes: 'Female passengers only please',
        pricePerSeat: 200,
        passengers: [],
        isFull: false,
        pickupLatitude: 31.4697,
        pickupLongitude: 74.2728,
        dropoffLatitude: 31.4952,
        dropoffLongitude: 74.4023,
        timeFlexibilityMinutes: 10,
        isWorkplaceRide: false,
        recurringDays: ['1', '3', '5'],
        comfortFeatures: {'ac': true, 'music': false},
        averageRating: 4.9,
        genderPreference: 'female_only',
        currentMalePassengers: 0,
        currentFemalePassengers: 0,
        estimatedDistanceKm: 12.3,
        estimatedDurationMinutes: 25,
        routePoints: routePoints2,
        hasStops: true,
        stops: [stop2],
      ),
      Ride(
        id: 3,
        driver: driver1,
        driverRating: 4.7,
        departureTime: now.add(const Duration(hours: 4)),
        pickupLocation: 'G-9 Markaz, Islamabad',
        dropoffLocation: 'Blue Area, Islamabad',
        totalSeats: 4,
        availableSeats: 4,
        availableSeatsDisplay: '4 seats available',
        status: 'scheduled',
        recurring: true,
        notes: 'Daily office commute',
        pricePerSeat: 150,
        passengers: [],
        isFull: false,
        pickupLatitude: 33.6920,
        pickupLongitude: 73.0378,
        dropoffLatitude: 33.7293,
        dropoffLongitude: 73.0724,
        timeFlexibilityMinutes: 10,
        isWorkplaceRide: true,
        recurringDays: ['0', '1', '2', '3', '4'],
        comfortFeatures: {'ac': true, 'music': true},
        averageRating: 4.7,
        genderPreference: 'male_only',
        currentMalePassengers: 0,
        currentFemalePassengers: 0,
        estimatedDistanceKm: 7.8,
        estimatedDurationMinutes: 20,
        routePoints: [],
        hasStops: false,
        stops: [],
      ),
    ];
  }
}