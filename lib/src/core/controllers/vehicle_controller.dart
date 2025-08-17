import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/message_service.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class VehicleController extends GetxController {
  final MessageService _messageService = Get.find<MessageService>();
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<Vehicle> _vehicles = <Vehicle>[].obs;
  final RxBool _isLoading = false.obs;
  final Rx<Vehicle?> _selectedVehicle = Rx<Vehicle?>(null);

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading.value;
  Vehicle? get selectedVehicle => _selectedVehicle.value;

  @override
  void onInit() {
    super.onInit();
    // Don't automatically load data - wait for authentication
    debugPrint('🚗 VehicleController initialized - data loading deferred until authentication');
  }

  /// Initialize vehicle data after user authentication
  Future<void> initializeAfterAuth() async {
    debugPrint('🔐 Initializing vehicle data after authentication...');
    await loadVehicles();
  }

  /// Load user's vehicles
  Future<void> loadVehicles() async {
    try {
      _isLoading.value = true;
      debugPrint('🚗 Starting to load vehicles...');
      
      // Get vehicles from API
      final vehiclesData = await _apiService.getUserVehicles();
      debugPrint('📡 API Response: $vehiclesData');
      debugPrint('📊 Response type: ${vehiclesData.runtimeType}');
      debugPrint('📊 Response length: ${vehiclesData.length}');
      
      final vehicleList = vehiclesData.map((json) {
        debugPrint('🔍 Processing vehicle JSON: $json');
        return Vehicle.fromJson(json);
      }).toList();
      
      debugPrint('✅ Parsed ${vehicleList.length} vehicles');
      _vehicles.assignAll(vehicleList);
      
      // Set first vehicle as selected if none is selected
      if (_vehicles.isNotEmpty && _selectedVehicle.value == null) {
        _selectedVehicle.value = _vehicles.first;
      }
      
      debugPrint('✅ Loaded ${vehicleList.length} vehicles successfully');
      debugPrint('🚗 Current vehicles list: ${_vehicles.map((v) => "${v.make} ${v.model}").toList()}');
      
    } catch (e) {
      debugPrint('❌ Failed to load vehicles: $e');
      debugPrint('❌ Stack trace: ${e.toString()}');
      
      // Check if it's an authentication error
      if (e.toString().contains('401') || 
          e.toString().contains('Authentication credentials') ||
          e.toString().contains('Unauthorized')) {
        debugPrint('🔒 Authentication error loading vehicles - may need to refresh token');
        
        // Try to get the auth controller and trigger a refresh
        try {
          final authController = Get.find<AuthController>();
          if (authController.isLoggedIn.value) {
            debugPrint('🔄 User is logged in, this might be a token refresh issue');
            // Don't show error to user, let the auth controller handle it
            return;
          }
        } catch (authError) {
          debugPrint('⚠️ Could not access auth controller: $authError');
        }
        
        _messageService.showError('Authentication error. Please try logging in again.');
      } else {
        _messageService.showError('Failed to load vehicles: ${e.toString()}');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add a new vehicle
  Future<bool> addVehicle(Vehicle vehicle) async {
    try {
      _isLoading.value = true;
      
      // Convert Vehicle to API format
      final vehicleData = {
        'make': vehicle.make,
        'model': vehicle.model,
        'year': int.tryParse(vehicle.year) ?? 2020,
        'color': vehicle.color,
        'license_plate': vehicle.licensePlate,
        'total_seats': vehicle.totalSeats,
        'available_seats_for_ride': vehicle.availableSeats,
        'fuel_average': vehicle.fuelAverage,
        'vehicle_type': vehicle.type.name,
        'fuel_type': vehicle.fuelType,
        'engine_capacity': vehicle.engineCapacity,
        'has_ac': vehicle.hasAc,
        'ac_type': vehicle.acType,
        'has_music_system': vehicle.hasMusicSystem,
        'has_phone_charger': vehicle.hasPhoneCharger,
        'smoking_allowed': vehicle.smokingAllowed,
        'insurance_valid': vehicle.insuranceValid,
        'fitness_certificate_valid': vehicle.fitnessCertificateValid,
        'is_active': vehicle.isActive,
        'is_primary': vehicle.isPrimary,
        'notes': vehicle.notes,
      };
      
      final response = await _apiService.createVehicle(vehicleData);
      final newVehicle = Vehicle.fromJson(response);
      
      _vehicles.add(newVehicle);
      
      // Set as selected if it's the first vehicle
      if (_vehicles.length == 1) {
        _selectedVehicle.value = newVehicle;
      }
      
      _messageService.showSuccess('Vehicle added successfully!');
      return true;
      
    } catch (e) {
      String errorMessage = e.toString();
      
      // Check for specific error types
      if (errorMessage.contains('already registered') || 
          errorMessage.contains('license plate') || 
          errorMessage.contains('another owner')) {
        _messageService.showError('This car is already registered with another owner. Please check the license plate.');
      } else if (errorMessage.contains('duplicate')) {
        _messageService.showError('A vehicle with this license plate already exists.');
      } else {
        _messageService.showError('Failed to add vehicle: $errorMessage');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update an existing vehicle
  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      _isLoading.value = true;
      
      // Convert Vehicle to API format
      final vehicleData = {
        'make': vehicle.make,
        'model': vehicle.model,
        'year': int.tryParse(vehicle.year) ?? 2020,
        'color': vehicle.color,
        'license_plate': vehicle.licensePlate,
        'total_seats': vehicle.totalSeats,
        'available_seats_for_ride': vehicle.availableSeats,
        'fuel_average': vehicle.fuelAverage,
        'vehicle_type': vehicle.type.name,
        'fuel_type': vehicle.fuelType,
        'engine_capacity': vehicle.engineCapacity,
        'has_ac': vehicle.hasAc,
        'ac_type': vehicle.acType,
        'has_music_system': vehicle.hasMusicSystem,
        'has_phone_charger': vehicle.hasPhoneCharger,
        'smoking_allowed': vehicle.smokingAllowed,
        'insurance_valid': vehicle.insuranceValid,
        'fitness_certificate_valid': vehicle.fitnessCertificateValid,
        'is_active': vehicle.isActive,
        'is_primary': vehicle.isPrimary,
        'notes': vehicle.notes,
      };
      
      final response = await _apiService.updateVehicle(int.parse(vehicle.id), vehicleData);
      final updatedVehicle = Vehicle.fromJson(response);
      
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
        
        // Update selected vehicle if it's the one being updated
        if (_selectedVehicle.value?.id == vehicle.id) {
          _selectedVehicle.value = updatedVehicle;
        }
        
        _messageService.showSuccess('Vehicle updated successfully!');
        return true;
      } else {
        _messageService.showError('Vehicle not found');
        return false;
      }
      
    } catch (e) {
      _messageService.showError('Failed to update vehicle: ${e.toString()}');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete a vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      _isLoading.value = true;
      
      await _apiService.deleteVehicle(int.parse(vehicleId));
      
      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        _vehicles.removeAt(index);
        
        // Clear selected vehicle if it was deleted
        if (_selectedVehicle.value?.id == vehicleId) {
          _selectedVehicle.value = _vehicles.isNotEmpty ? _vehicles.first : null;
        }
        
        _messageService.showSuccess('Vehicle deleted successfully!');
        return true;
      } else {
        _messageService.showError('Vehicle not found');
        return false;
      }
      
    } catch (e) {
      _messageService.showError('Failed to delete vehicle: ${e.toString()}');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Select a vehicle for offering rides
  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle.value = vehicle;
  }

  /// Get vehicles by type
  List<Vehicle> getVehiclesByType(VehicleType type) {
    return _vehicles.where((vehicle) => vehicle.type == type).toList();
  }

  /// Get active vehicles only
  List<Vehicle> get activeVehicles {
    return _vehicles.where((vehicle) => vehicle.isActive).toList();
  }

  /// Get popular car makes for Pakistan
  static List<String> get popularMakes => [
    'Toyota',
    'Honda',
    'Suzuki',
    'Hyundai',
    'Kia',
    'Nissan',
    'Mitsubishi',
    'Daihatsu',
    'Mercedes-Benz',
    'BMW',
    'Audi',
    'Other',
  ];

  /// Get popular car models by make
  static List<String> getModelsByMake(String make) {
    switch (make.toLowerCase()) {
      case 'toyota':
        return ['Corolla', 'Camry', 'Prius', 'Vitz', 'Aqua', 'Land Cruiser', 'Prado', 'Hilux'];
      case 'honda':
        return ['City', 'Civic', 'Accord', 'BR-V', 'CR-V', 'Vezel'];
      case 'suzuki':
        return ['Alto', 'Cultus', 'Swift', 'Wagon R', 'Vitara', 'Jimny'];
      case 'hyundai':
        return ['Elantra', 'Sonata', 'Tucson', 'Santa Fe', 'i10', 'i20'];
      case 'kia':
        return ['Picanto', 'Cerato', 'Sportage', 'Sorento', 'Stonic'];
      case 'nissan':
        return ['Sunny', 'Altima', 'X-Trail', 'Patrol', 'Note'];
      case 'mitsubishi':
        return ['Lancer', 'Pajero', 'Outlander', 'Mirage'];
      case 'daihatsu':
        return ['Mira', 'Move', 'Cast', 'Rocky'];
      default:
        return ['Model 1', 'Model 2', 'Model 3'];
    }
  }

  /// Get common car colors
  static List<String> get popularColors => [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Red',
    'Blue',
    'Green',
    'Brown',
    'Yellow',
    'Other',
  ];

  /// Get years from current year to 20 years back
  static List<String> get availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(25, (index) => (currentYear - index).toString());
  }
}
