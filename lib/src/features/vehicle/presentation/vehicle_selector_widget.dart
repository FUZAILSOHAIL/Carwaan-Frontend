import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/vehicle_controller.dart';
import '../../../core/models/vehicle.dart';
import 'add_vehicle_screen.dart';

class VehicleSelectorWidget extends StatelessWidget {
  final Function(Vehicle?)? onVehicleSelected;
  final Vehicle? selectedVehicle;

  const VehicleSelectorWidget({
    super.key,
    this.onVehicleSelected,
    this.selectedVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final VehicleController vehicleController = Get.put(VehicleController());

    return Obx(() {
      if (vehicleController.isLoading && vehicleController.vehicles.isEmpty) {
        return const CircularProgressIndicator();
      }

      if (vehicleController.vehicles.isEmpty) {
        return _buildAddVehiclePrompt();
      }

      return _buildVehicleSelector(vehicleController);
    });
  }

  Widget _buildAddVehiclePrompt() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No vehicles added',
              style: Get.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your vehicle to offer rides',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const AddVehicleScreen());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(VehicleController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Vehicle *',
              style: Get.textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: () {
                Get.to(() => const AddVehicleScreen());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Selected vehicle display
        if (selectedVehicle != null)
          _buildSelectedVehicleCard(selectedVehicle!)
        else
          _buildVehicleSelector2(controller),
      ],
    );
  }

  Widget _buildSelectedVehicleCard(Vehicle vehicle) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              vehicle.type.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          vehicle.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${vehicle.color} • ${vehicle.seats} seats'),
            Text(vehicle.licensePlate),
          ],
        ),
        trailing: TextButton(
          onPressed: () {
            _showVehicleSelector();
          },
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector2(VehicleController controller) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: controller.activeVehicles.map((vehicle) {
          final isSelected = selectedVehicle?.id == vehicle.id;
          return Container(
            decoration: BoxDecoration(
              color: isSelected ? Get.theme.primaryColor.withValues(alpha: 0.1) : null,
              border: isSelected 
                ? Border.all(color: Get.theme.primaryColor)
                : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Text(
                vehicle.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                vehicle.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text('${vehicle.color} • ${vehicle.seats} seats • ${vehicle.licensePlate}'),
              trailing: isSelected 
                ? Icon(Icons.check_circle, color: Get.theme.primaryColor)
                : null,
              onTap: () {
                onVehicleSelected?.call(vehicle);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showVehicleSelector() {
    final VehicleController controller = Get.find<VehicleController>();
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Vehicle',
                  style: Get.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    Get.to(() => const AddVehicleScreen());
                  },
                  child: const Text('Add New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.activeVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = controller.activeVehicles[index];
                  final isSelected = selectedVehicle?.id == vehicle.id;
                  
                  return Card(
                    color: isSelected ? Get.theme.primaryColor.withValues(alpha: 0.1) : null,
                    child: ListTile(
                      leading: Text(
                        vehicle.type.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(vehicle.displayName),
                      subtitle: Text('${vehicle.color} • ${vehicle.seats} seats'),
                      trailing: isSelected 
                        ? Icon(Icons.check_circle, color: Get.theme.primaryColor)
                        : null,
                      onTap: () {
                        onVehicleSelected?.call(vehicle);
                        Get.back();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple vehicle display widget for ride details
class VehicleDisplayWidget extends StatelessWidget {
  final Vehicle vehicle;
  final bool showDetails;

  const VehicleDisplayWidget({
    super.key,
    required this.vehicle,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            vehicle.type.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.color} • ${vehicle.seats} seats • ${vehicle.licensePlate}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
