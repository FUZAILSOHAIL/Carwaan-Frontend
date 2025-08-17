import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../src/core/services/api_service.dart';
import '../src/core/controllers/auth_controller.dart';
import '../src/core/controllers/vehicle_controller.dart';

class VehicleDebugUtil {
  static void showVehicleDebugInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VehicleDebugDialog(),
    );
  }
}

class VehicleDebugDialog extends StatefulWidget {
  const VehicleDebugDialog({super.key});

  @override
  State<VehicleDebugDialog> createState() => _VehicleDebugDialogState();
}

class _VehicleDebugDialogState extends State<VehicleDebugDialog> {
  String _debugOutput = 'Ready to debug...';
  bool _isLoading = false;

  Future<void> _testVehicleAPI() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Testing vehicle API...\n';
    });

    try {
      // Test 1: Check authentication
      final authController = Get.find<AuthController>();
      _appendLog('✅ AuthController found');
      _appendLog('🔐 Is logged in: ${authController.isLoggedIn.value}');
      _appendLog('🔑 Has token: ${authController.token.value.isNotEmpty}');
      _appendLog('👤 Current user: ${authController.currentUser.value?.firstName ?? 'None'}');

      // Test 2: Check API service
      final apiService = Get.find<ApiService>();
      _appendLog('✅ ApiService found');

      // Test 3: Make direct API call
      _appendLog('\n🌐 Making direct API call to /vehicles/...');
      
      try {
        final vehiclesData = await apiService.getUserVehicles();
        _appendLog('✅ API call successful!');
        _appendLog('📊 Vehicles returned: ${vehiclesData.length}');
        
        for (int i = 0; i < vehiclesData.length; i++) {
          final vehicle = vehiclesData[i];
          _appendLog('  Vehicle $i: ${vehicle['make']} ${vehicle['model']} (${vehicle['license_plate']})');
        }
        
        if (vehiclesData.isEmpty) {
          _appendLog('⚠️ No vehicles found in API response');
        }
      } catch (apiError) {
        _appendLog('❌ API call failed: $apiError');
        
        // Check if it's an authentication error
        if (apiError.toString().contains('401')) {
          _appendLog('🔒 Authentication error - token may be invalid');
        }
      }

      // Test 4: Check vehicle controller
      _appendLog('\n🎮 Testing VehicleController...');
      try {
        final vehicleController = Get.find<VehicleController>();
        _appendLog('✅ VehicleController found');
        _appendLog('📱 Vehicles in controller: ${vehicleController.vehicles.length}');
        _appendLog('🔄 Is loading: ${vehicleController.isLoading}');
        
        // Trigger a reload
        _appendLog('\n🔄 Triggering vehicle reload...');
        await vehicleController.loadVehicles();
        _appendLog('✅ Reload completed');
        _appendLog('📱 Vehicles after reload: ${vehicleController.vehicles.length}');
        
      } catch (controllerError) {
        _appendLog('❌ VehicleController error: $controllerError');
      }

    } catch (e) {
      _appendLog('❌ Debug error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _appendLog(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vehicle Debug Info'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testVehicleAPI,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Vehicle API'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _debugOutput = 'Ready to debug...';
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
