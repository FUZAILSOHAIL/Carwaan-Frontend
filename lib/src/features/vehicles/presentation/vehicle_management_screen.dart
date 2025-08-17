import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/services/message_service.dart';
import '../../../domain/models/vehicle_model.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  late final AuthController _authController;
  late final MessageService _messageService;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _messageService = MessageService();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('🔄 Loading vehicles...');
      
      await _authController.getUserVehicles();
      
      debugPrint('✅ Loaded ${_authController.userVehicles.length} vehicles');
    } catch (e) {
      debugPrint('❌ Failed to load vehicles: $e');
      _messageService.showError('Failed to load vehicles: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        
        bool success = await _authController.deleteVehicle(vehicle.id);
        
        if (success) {
          _messageService.showSuccess('Vehicle deleted successfully!');
          // No need to manually reload - AuthController already updates userVehicles
        } else {
          _messageService.showError('Failed to delete vehicle');
        }
      } catch (e) {
        debugPrint('❌ Error deleting vehicle: $e');
        _messageService.showError('Failed to delete vehicle: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleVehicleActive(Vehicle vehicle) async {
    try {
      setState(() => _isLoading = true);
      
      bool success = await _authController.updateVehicle(
        vehicle.id,
        {'is_active': !vehicle.isActive},
      );
      
      if (success) {
        _messageService.showSuccess(
          vehicle.isActive ? 'Vehicle deactivated' : 'Vehicle activated'
        );
        // No need to manually reload - AuthController already updates userVehicles
      } else {
        _messageService.showError('Failed to update vehicle');
      }
    } catch (e) {
      debugPrint('❌ Error updating vehicle: $e');
      _messageService.showError('Failed to update vehicle: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToAddVehicle() {
    _showAddVehicleDialog();
  }

  void _navigateToEditVehicle(Vehicle vehicle) {
    _showEditVehicleDialog(vehicle);
  }

  Future<void> _showAddVehicleDialog() async {
    final formKey = GlobalKey<FormState>();
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final colorController = TextEditingController();
    final licensePlateController = TextEditingController();
    final capacityController = TextEditingController(text: '4');
    String selectedVehicleType = 'sedan';
    String selectedFuelType = 'petrol';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: makeController,
                  decoration: const InputDecoration(
                    labelText: 'Make*',
                    hintText: 'e.g., Toyota, Honda',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Make is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model*',
                    hintText: 'e.g., Corolla, Civic',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Model is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: yearController,
                  decoration: const InputDecoration(
                    labelText: 'Year*',
                    hintText: 'e.g., 2020',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Year is required';
                    final year = int.tryParse(value!);
                    if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                      return 'Please enter a valid year (1990-${DateTime.now().year + 1})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color*',
                    hintText: 'e.g., White, Black',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Color is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'License Plate*',
                    hintText: 'e.g., ABC-123',
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'License plate is required';
                    // Basic format validation
                    if (!RegExp(r'^[A-Za-z]{2,3}-\d{3,4}$').hasMatch(value!)) {
                      return 'Format: ABC-123 or AB-1234';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedVehicleType,
                  decoration: const InputDecoration(labelText: 'Vehicle Type'),
                  items: const [
                    DropdownMenuItem(value: 'sedan', child: Text('Sedan')),
                    DropdownMenuItem(value: 'hatchback', child: Text('Hatchback')),
                    DropdownMenuItem(value: 'suv', child: Text('SUV')),
                    DropdownMenuItem(value: 'crossover', child: Text('Crossover')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => selectedVehicleType = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFuelType,
                  decoration: const InputDecoration(labelText: 'Fuel Type'),
                  items: const [
                    DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
                    DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
                    DropdownMenuItem(value: 'cng', child: Text('CNG')),
                    DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                  ],
                  onChanged: (value) => selectedFuelType = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Total Seats*',
                    hintText: 'Number of seats (including driver)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Total seats is required';
                    final capacity = int.tryParse(value!);
                    if (capacity == null || capacity < 2 || capacity > 8) {
                      return 'Total seats must be between 2 and 8';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _addVehicle({
                  'make': makeController.text.trim(),
                  'model': modelController.text.trim(),
                  'year': int.parse(yearController.text.trim()),
                  'color': colorController.text.trim(),
                  'license_plate': licensePlateController.text.trim().toUpperCase(),
                  'vehicle_type': selectedVehicleType,
                  'fuel_type': selectedFuelType,
                  'total_seats': int.parse(capacityController.text.trim()),
                  'available_seats_for_ride': int.parse(capacityController.text.trim()) - 1, // Exclude driver
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditVehicleDialog(Vehicle vehicle) async {
    final formKey = GlobalKey<FormState>();
    final makeController = TextEditingController(text: vehicle.make);
    final modelController = TextEditingController(text: vehicle.model);
    final yearController = TextEditingController(text: vehicle.year.toString());
    final colorController = TextEditingController(text: vehicle.color);
    final licensePlateController = TextEditingController(text: vehicle.licensePlate);
    final capacityController = TextEditingController(text: vehicle.totalSeats.toString());
    String selectedVehicleType = vehicle.vehicleType;
    String selectedFuelType = vehicle.fuelType;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: makeController,
                  decoration: const InputDecoration(
                    labelText: 'Make*',
                    hintText: 'e.g., Toyota, Honda',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Make is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model*',
                    hintText: 'e.g., Corolla, Civic',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Model is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: yearController,
                  decoration: const InputDecoration(
                    labelText: 'Year*',
                    hintText: 'e.g., 2020',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Year is required';
                    final year = int.tryParse(value!);
                    if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                      return 'Please enter a valid year (1990-${DateTime.now().year + 1})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color*',
                    hintText: 'e.g., White, Black',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Color is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'License Plate*',
                    hintText: 'e.g., ABC-123',
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'License plate is required';
                    // Basic format validation
                    if (!RegExp(r'^[A-Za-z]{2,3}-\d{3,4}$').hasMatch(value!)) {
                      return 'Format: ABC-123 or AB-1234';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedVehicleType,
                  decoration: const InputDecoration(labelText: 'Vehicle Type'),
                  items: const [
                    DropdownMenuItem(value: 'sedan', child: Text('Sedan')),
                    DropdownMenuItem(value: 'hatchback', child: Text('Hatchback')),
                    DropdownMenuItem(value: 'suv', child: Text('SUV')),
                    DropdownMenuItem(value: 'crossover', child: Text('Crossover')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => selectedVehicleType = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFuelType,
                  decoration: const InputDecoration(labelText: 'Fuel Type'),
                  items: const [
                    DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
                    DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
                    DropdownMenuItem(value: 'cng', child: Text('CNG')),
                    DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                  ],
                  onChanged: (value) => selectedFuelType = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Total Seats*',
                    hintText: 'Number of seats (including driver)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Total seats is required';
                    final capacity = int.tryParse(value!);
                    if (capacity == null || capacity < 2 || capacity > 8) {
                      return 'Total seats must be between 2 and 8';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _updateVehicle(vehicle.id, {
                  'make': makeController.text.trim(),
                  'model': modelController.text.trim(),
                  'year': int.parse(yearController.text.trim()),
                  'color': colorController.text.trim(),
                  'license_plate': licensePlateController.text.trim().toUpperCase(),
                  'vehicle_type': selectedVehicleType,
                  'fuel_type': selectedFuelType,
                  'total_seats': int.parse(capacityController.text.trim()),
                  'available_seats_for_ride': int.parse(capacityController.text.trim()) - 1, // Exclude driver
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      setState(() => _isLoading = true);
      debugPrint('🚗 Adding new vehicle...');
      
      bool success = await _authController.createVehicle(vehicleData);
      
      if (success) {
        _messageService.showSuccess('Vehicle added successfully!');
        // No need to manually reload - AuthController already updates userVehicles
      } else {
        _messageService.showError('Failed to add vehicle');
      }
    } catch (e) {
      debugPrint('❌ Error adding vehicle: $e');
      _messageService.showError('Failed to add vehicle: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVehicle(int vehicleId, Map<String, dynamic> vehicleData) async {
    try {
      setState(() => _isLoading = true);
      debugPrint('🚗 Updating vehicle...');
      
      bool success = await _authController.updateVehicle(vehicleId, vehicleData);
      
      if (success) {
        _messageService.showSuccess('Vehicle updated successfully!');
        // No need to manually reload - AuthController already updates userVehicles
      } else {
        _messageService.showError('Failed to update vehicle');
      }
    } catch (e) {
      debugPrint('❌ Error updating vehicle: $e');
      _messageService.showError('Failed to update vehicle: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Vehicles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddVehicle,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Obx(() {
              final vehicles = _authController.userVehicles
                  .map((data) => Vehicle.fromJson(data))
                  .toList();
              
              return vehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                        'No vehicles added yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first vehicle to start offering rides',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddVehicle,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Vehicle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return _buildVehicleCard(vehicle);
                  },
                );
            }),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddVehicle,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'License: ${vehicle.licensePlate}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vehicle.isActive 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: vehicle.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Vehicle details
            _buildVehicleDetail('Color', vehicle.color),
            _buildVehicleDetail('Seats', '${vehicle.totalSeats}'),
            _buildVehicleDetail('Fuel Type', vehicle.fuelType),
            if (vehicle.hasAc) _buildVehicleDetail('AC', vehicle.acType),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEditVehicle(vehicle),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleVehicleActive(vehicle),
                    icon: Icon(
                      vehicle.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(vehicle.isActive ? 'Deactivate' : 'Activate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: vehicle.isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _deleteVehicle(vehicle),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
