import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/ride_model.dart';
import '../../../domain/models/user_model.dart';

class RideDetailsScreen extends StatefulWidget {
  final Ride ride;
  final User? currentUser;
  final Function()? onRideJoined;
  final Function()? onRideLeft;

  const RideDetailsScreen({
    super.key,
    required this.ride,
    this.currentUser,
    this.onRideJoined,
    this.onRideLeft,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final MapController _mapController = MapController();
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final isUserDriver = widget.currentUser != null && 
                        widget.currentUser!.id == widget.ride.driver.id;
    final isUserPassenger = widget.currentUser != null && 
                          widget.ride.passengers.any((p) => p.passenger == widget.currentUser!.id);
    final canJoinRide = widget.currentUser != null && 
                      !isUserDriver && 
                      !isUserPassenger && 
                      !widget.ride.isFull &&
                      widget.ride.isUserEligible(widget.currentUser!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map showing route
            _buildRouteMap(),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ride information card
                  _buildRideInfoCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Driver information
                  _buildDriverCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Passenger information with gender tracking
                  _buildPassengersCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Route details with stops
                  if (widget.ride.hasStops)
                    _buildRouteStopsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Join ride button
                  if (canJoinRide)
                    _buildJoinRideButton(),
                  
                  // Leave ride button
                  if (isUserPassenger && !isUserDriver)
                    _buildLeaveRideButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteMap() {
    // Check if we have valid coordinates to display
    // ignore: unnecessary_null_comparison
    final hasCoordinates = widget.ride.pickupLongitude != null;
                         
    if (!hasCoordinates) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Text('No route coordinates available'),
        ),
      );
    }
    
    // Create markers for pickup and dropoff
    final pickupPoint = LatLng(
      widget.ride.pickupLatitude,
      widget.ride.pickupLongitude
    );
    
    final dropoffPoint = LatLng(
      widget.ride.dropoffLatitude,
      widget.ride.dropoffLongitude
    );
    
    // Collect all points for route
    final List<LatLng> routePoints = [pickupPoint];
    
    // Add intermediate points if available
    if (widget.ride.routePoints.isNotEmpty) {
      // Sort route points by sequence
      final sortedPoints = [...widget.ride.routePoints];
      sortedPoints.sort((a, b) => a.sequence.compareTo(b.sequence));
      
      for (final point in sortedPoints) {
        routePoints.add(LatLng(point.latitude, point.longitude));
      }
    }
    
    routePoints.add(dropoffPoint);
    
    // Create markers for stops
    final stopMarkers = <Marker>[];
    if (widget.ride.hasStops) {
      for (final stop in widget.ride.stops) {
        stopMarkers.add(
          Marker(
            width: 40,
            height: 40,
            point: LatLng(stop.latitude, stop.longitude),
            child: const Icon(
              Icons.location_on,
              color: Colors.amber,
              size: 40,
            ),
          ),
        );
      }
    }
    
    return SizedBox(
      height: 300,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            (widget.ride.pickupLatitude + widget.ride.dropoffLatitude) / 2,
            (widget.ride.pickupLongitude + widget.ride.dropoffLongitude) / 2,
          ),
          initialZoom: 11,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.carwaan.app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              // Pickup marker
              Marker(
                width: 40,
                height: 40,
                point: pickupPoint,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              // Dropoff marker
              Marker(
                width: 40,
                height: 40,
                point: dropoffPoint,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              // Add stop markers
              ...stopMarkers,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride #${widget.ride.id}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Date', 
              DateFormat('EEE, MMM d, yyyy').format(widget.ride.departureTime)),
            _buildInfoRow(Icons.access_time, 'Time', 
              DateFormat('h:mm a').format(widget.ride.departureTime)),
            _buildInfoRow(Icons.location_on, 'Pickup', widget.ride.pickupLocation),
            _buildInfoRow(Icons.location_off, 'Dropoff', widget.ride.dropoffLocation),
            _buildInfoRow(Icons.attach_money, 'Price', 
              'PKR ${widget.ride.pricePerSeat.toStringAsFixed(0)} per seat'),
            _buildInfoRow(Icons.airline_seat_recline_normal, 'Seats', 
              '${widget.ride.availableSeats} / ${widget.ride.totalSeats} available'),
            _buildInfoRow(Icons.people, 'Gender Info', widget.ride.getPassengerGenderInfo()),
            _buildInfoRow(Icons.accessibility, 'Gender Preference', 
              widget.ride.getGenderPreferenceDisplay()),
            if (widget.ride.estimatedDistanceKm > 0)
              _buildInfoRow(Icons.straighten, 'Distance', 
                '${widget.ride.estimatedDistanceKm.toStringAsFixed(1)} km'),
            if (widget.ride.estimatedDurationMinutes > 0)
              _buildInfoRow(Icons.timer, 'Duration', 
                '${widget.ride.estimatedDurationMinutes} minutes'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDriverCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.ride.driver.profilePicture != null
                      ? NetworkImage(widget.ride.driver.profilePicture!)
                      : null,
                  child: widget.ride.driver.profilePicture == null
                      ? Text(
                          widget.ride.driver.firstName[0] + 
                          widget.ride.driver.lastName[0],
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ride.driver.fullName ?? 'Unknown Driver',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.ride.driver.averageRating.toStringAsFixed(1)}/5.0',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.ride.driver.getGenderDisplay(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (widget.ride.driver.hasCar && widget.ride.driver.carModel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.ride.driver.carColor} ${widget.ride.driver.carModel}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPassengersCard() {
    final confirmedPassengers = widget.ride.passengers
        .where((passenger) => passenger.status == 'confirmed')
        .toList();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Passengers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${confirmedPassengers.length} / ${widget.ride.totalSeats}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Gender statistics row
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGenderStat(
                    Icons.man, 
                    'Men', 
                    widget.ride.currentMalePassengers, 
                    Colors.blue[700]!
                  ),
                  _buildGenderStat(
                    Icons.woman, 
                    'Women', 
                    widget.ride.currentFemalePassengers, 
                    Colors.pink[400]!
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (confirmedPassengers.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: confirmedPassengers.length,
                itemBuilder: (context, index) {
                  final passenger = confirmedPassengers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: passenger.passengerPicture != null
                          ? NetworkImage(passenger.passengerPicture!)
                          : null,
                      child: passenger.passengerPicture == null
                          ? Text(
                              passenger.passengerName[0],
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                    title: Text(passenger.passengerName),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('${passenger.passengerRating.toStringAsFixed(1)}/5.0'),
                        const SizedBox(width: 16),
                        Icon(
                          passenger.passengerGender == 'male' 
                              ? Icons.man 
                              : passenger.passengerGender == 'female'
                                  ? Icons.woman
                                  : Icons.person,
                          size: 14,
                          color: passenger.passengerGender == 'male'
                              ? Colors.blue[700]
                              : passenger.passengerGender == 'female'
                                  ? Colors.pink[400]
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(_getGenderDisplayText(passenger.passengerGender)),
                      ],
                    ),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('No confirmed passengers yet'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteStopsCard() {
    final sortedStops = [...widget.ride.stops];
    sortedStops.sort((a, b) => a.sequence.compareTo(b.sequence));
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route & Stops',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedStops.length,
              itemBuilder: (context, index) {
                final stop = sortedStops[index];
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(stop.locationName),
                      subtitle: Text(stop.address),
                      trailing: stop.scheduledTime != null
                          ? Text(DateFormat('h:mm a').format(stop.scheduledTime!))
                          : null,
                    ),
                    if (index < sortedStops.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: Container(
                          height: 24,
                          width: 2,
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJoinRideButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Added bottom padding
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isJoining ? null : () {
            setState(() => _isJoining = true);
            
            // TODO: Implement API call to join ride
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() => _isJoining = false);
                if (widget.onRideJoined != null) {
                  widget.onRideJoined!();
                }
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully requested to join ride')),
                );
              }
            });
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: _isJoining
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('REQUEST TO JOIN RIDE'),
        ),
      ),
    );
  }
  
  Widget _buildLeaveRideButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Added bottom padding
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Leave Ride'),
                content: const Text('Are you sure you want to leave this ride?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // TODO: Implement API call to leave ride
                      if (widget.onRideLeft != null) {
                        widget.onRideLeft!();
                      }
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You have left the ride')),
                      );
                    },
                    child: const Text('LEAVE', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('LEAVE RIDE', style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenderStat(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  String _getGenderDisplayText(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
        return 'Not specified';
      default:
        return 'Not specified';
    }
  }
}