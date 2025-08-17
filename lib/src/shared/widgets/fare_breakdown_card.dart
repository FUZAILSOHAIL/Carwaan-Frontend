import 'package:flutter/material.dart';
import '../../core/models/ride_models.dart';
import '../../core/services/fare_service.dart';

class FareBreakdownCard extends StatelessWidget {
  final FareBreakdown fareBreakdown;
  final bool showDetailed;
  final bool showSavings;

  const FareBreakdownCard({
    super.key,
    required this.fareBreakdown,
    this.showDetailed = false,
    this.showSavings = true,
  });

  @override
  Widget build(BuildContext context) {
    final fareService = FareCalculationService.instance;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare Details', // Fare Details
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 16,
                      ),
                    ),
                    if (fareBreakdown.isPeakHours)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Text(
                          fareService.getPeakHoursText(DateTime.now()),
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Main Fare Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fareBreakdown.estimatedFarePerPerson != null 
                          ? 'Estimated fare per person' // Estimated fare per person
                          : 'Fare per person', // Fare per person
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (fareBreakdown.confirmedPassengers > 0)
                      Text(
                        '${fareBreakdown.confirmedPassengers + 1} passengers', // passengers
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                Text(
                  fareService.getFareDisplayText(
                    fareBreakdown.estimatedFarePerPerson ?? fareBreakdown.farePerPerson
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Detailed Breakdown
          if (showDetailed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: fareService.getFareExplanation(fareBreakdown)
                    .map((line) => _buildDetailRow(line))
                    .toList(),
              ),
            ),
          ],
          
          // Savings Information
          if (showSavings && fareBreakdown.confirmedPassengers > 0) ...[
            const SizedBox(height: 12),
            _buildSavingsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard() {
    final fareService = FareCalculationService.instance;
    final savings = fareService.calculateSavings(
      totalFare: fareBreakdown.totalFare,
      passengers: fareBreakdown.confirmedPassengers + 1,
    );

    if (savings['savings_amount'] <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.savings,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Savings', // Your Savings
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${fareService.getFareDisplayText(savings['savings_amount'])} '
                  '(${savings['savings_percentage'].toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: Colors.orange[600],
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
}

class QuickFareCalculator extends StatefulWidget {
  final Function(FareBreakdown)? onCalculated;

  const QuickFareCalculator({
    super.key,
    this.onCalculated,
  });

  @override
  State<QuickFareCalculator> createState() => _QuickFareCalculatorState();
}

class _QuickFareCalculatorState extends State<QuickFareCalculator> {
  final _distanceController = TextEditingController();
  final _passengersController = TextEditingController(text: '2');
  DateTime _selectedTime = DateTime.now();
  FareBreakdown? _calculatedFare;

  @override
  void dispose() {
    _distanceController.dispose();
    _passengersController.dispose();
    super.dispose();
  }

  void _calculateFare() {
    final distance = double.tryParse(_distanceController.text);
    final passengers = int.tryParse(_passengersController.text);

    if (distance != null && passengers != null && distance > 0 && passengers > 0) {
      final fareService = FareCalculationService.instance;
      final breakdown = fareService.calculateEstimatedFare(
        distanceKm: distance,
        departureTime: _selectedTime,
        estimatedPassengers: passengers - 1, // Exclude driver
      );

      setState(() {
        _calculatedFare = breakdown;
      });

      widget.onCalculated?.call(breakdown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fare Calculator', // Fare Calculator
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            
            // Distance Input
            TextField(
              controller: _distanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Distance (km)', // Distance (km)
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.straighten, color: Colors.green[700]),
              ),
              onChanged: (_) => _calculateFare(),
            ),
            
            const SizedBox(height: 12),
            
            // Passengers Input
            TextField(
              controller: _passengersController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total passengers (including driver)', // Total passengers (including driver)
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.people, color: Colors.green[700]),
              ),
              onChanged: (_) => _calculateFare(),
            ),
            
            const SizedBox(height: 12),
            
            // Time Selection
            ListTile(
              leading: Icon(Icons.access_time, color: Colors.green[700]),
              title: const Text('Time'), // Time
              subtitle: Text(
                '${_selectedTime.hour.toString().padLeft(2, '0')}:'
                '${_selectedTime.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedTime),
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = DateTime(
                      _selectedTime.year,
                      _selectedTime.month,
                      _selectedTime.day,
                      time.hour,
                      time.minute,
                    );
                  });
                  _calculateFare();
                }
              },
            ),
            
            if (_calculatedFare != null) ...[
              const SizedBox(height: 16),
              FareBreakdownCard(
                fareBreakdown: _calculatedFare!,
                showDetailed: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
