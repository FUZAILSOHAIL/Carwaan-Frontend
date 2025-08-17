import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/vehicle_controller.dart';
import '../../../core/models/vehicle.dart';
import 'add_vehicle_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  late final VehicleController vehicleController;

  @override
  void initState() {
    super.initState();
    vehicleController = Get.find<VehicleController>();
    
    // Ensure vehicles are loaded when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚗 VehicleManagementScreen: Loading vehicles...');
      vehicleController.loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Get.to(() => const AddVehicleScreen());
              // Refresh the vehicle list if a vehicle was added
              if (result == true) {
                vehicleController.loadVehicles();
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (vehicleController.isLoading && vehicleController.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vehicleController.vehicles.isEmpty) {
          return _buildEmptyState(vehicleController);
        }

        return RefreshIndicator(
          onRefresh: vehicleController.loadVehicles,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicleController.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleController.vehicles[index];
              return _buildVehicleCard(vehicle, vehicleController);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const AddVehicleScreen());
          // Refresh the vehicle list if a vehicle was added
          if (result == true) {
            vehicleController.loadVehicles();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(VehicleController vehicleController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No vehicles added yet',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add your vehicle to start offering rides',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Get.to(() => const AddVehicleScreen());
              // Refresh the vehicle list if a vehicle was added
              if (result == true) {
                vehicleController.loadVehicles();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, VehicleController controller) {
    final isSelected = controller.selectedVehicle?.id == vehicle.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Get.theme.primaryColor,
                  width: 2,
                ),
              )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Get.theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                vehicle.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  vehicle.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Get.theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.palette, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(vehicle.color),
                  const SizedBox(width: 16),
                  Icon(Icons.event_seat, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${vehicle.seats} seats'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.confirmation_number, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(vehicle.licensePlate),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'select':
                  controller.selectVehicle(vehicle);
                  Get.snackbar(
                    'Vehicle Selected',
                    '${vehicle.displayName} selected for rides',
                    duration: const Duration(seconds: 2),
                  );
                  break;
                case 'edit':
                  Get.to(() => AddVehicleScreen(vehicle: vehicle));
                  break;
                case 'delete':
                  _showDeleteConfirmation(vehicle, controller);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (!isSelected)
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Select for rides'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            controller.selectVehicle(vehicle);
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Vehicle vehicle, VehicleController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete ${vehicle.displayName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteVehicle(vehicle.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
