import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/controllers/vehicle_controller.dart';
import '../../../core/models/vehicle.dart';
import 'dart:io';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle; // For editing existing vehicle

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleController _vehicleController = Get.find<VehicleController>();

  // Form controllers
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _licensePlateController;
  late TextEditingController _customMakeController;
  late TextEditingController _customModelController;
  late TextEditingController _customColorController;
  late TextEditingController _engineCapacityController;
  late TextEditingController _notesController;

  // Selected values
  String? _selectedMake;
  String? _selectedModel;
  String? _selectedYear;
  String? _selectedColor;
  VehicleType _selectedType = VehicleType.sedan;
  String? _selectedFuelType = 'petrol';
  String? _selectedAcType = 'standard';
  int _selectedSeats = 4;
  double _fuelAverage = 10.0;
  bool _hasAc = true;
  bool _hasMusicSystem = true;
  bool _hasPhoneCharger = false;
  bool _smokingAllowed = false;
  bool _insuranceValid = true;
  bool _fitnessCertificateValid = true;
  bool _isPrimary = false;
  File? _selectedImage;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    _makeController = TextEditingController();
    _modelController = TextEditingController();
    _licensePlateController = TextEditingController();
    _customMakeController = TextEditingController();
    _customModelController = TextEditingController();
    _customColorController = TextEditingController();
    _engineCapacityController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _loadExistingData() {
    if (_isEditing && widget.vehicle != null) {
      final vehicle = widget.vehicle!;
      _selectedMake = vehicle.make;
      _selectedModel = vehicle.model;
      _selectedYear = vehicle.year;
      _selectedColor = vehicle.color;
      _selectedType = vehicle.type;
      _selectedSeats = vehicle.totalSeats;
      _fuelAverage = vehicle.fuelAverage;
      _licensePlateController.text = vehicle.licensePlate;
      
      // Load additional fields
      _selectedFuelType = vehicle.fuelType;
      _selectedAcType = vehicle.acType;
      _hasAc = vehicle.hasAc;
      _hasMusicSystem = vehicle.hasMusicSystem;
      _hasPhoneCharger = vehicle.hasPhoneCharger;
      _smokingAllowed = vehicle.smokingAllowed;
      _insuranceValid = vehicle.insuranceValid;
      _fitnessCertificateValid = vehicle.fitnessCertificateValid;
      _isPrimary = vehicle.isPrimary;
      _engineCapacityController.text = vehicle.engineCapacity ?? '';
      _notesController.text = vehicle.notes ?? '';

      // Set custom fields if not in predefined lists
      if (!VehicleController.popularMakes.contains(vehicle.make)) {
        _customMakeController.text = vehicle.make;
        _selectedMake = 'Other';
      }
      if (_selectedMake != null && 
          !VehicleController.getModelsByMake(_selectedMake!).contains(vehicle.model)) {
        _customModelController.text = vehicle.model;
        _selectedModel = 'Other';
      }
      if (!VehicleController.popularColors.contains(vehicle.color)) {
        _customColorController.text = vehicle.color;
        _selectedColor = 'Other';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        actions: [
          TextButton(
            onPressed: _saveVehicle,
            child: Text(
              _isEditing ? 'Update' : 'Save',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Photo Section
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // Vehicle Type
              _buildVehicleTypeSection(),
              const SizedBox(height: 24),

              // Make Selection
              _buildMakeSection(),
              const SizedBox(height: 16),

              // Model Selection
              _buildModelSection(),
              const SizedBox(height: 16),

              // Year Selection
              _buildYearSection(),
              const SizedBox(height: 16),

              // Color Selection
              _buildColorSection(),
              const SizedBox(height: 16),

              // License Plate
              _buildLicensePlateField(),
              const SizedBox(height: 16),

              // Seats Selection
              _buildSeatsSection(),
              const SizedBox(height: 16),

              // Fuel Average
              _buildFuelAverageField(),
              const SizedBox(height: 16),

              // Fuel Type Section
              _buildFuelTypeSection(),
              const SizedBox(height: 16),

              // Engine Capacity Section
              _buildEngineCapacitySection(),
              const SizedBox(height: 16),

              // AC Section
              _buildAcSection(),
              const SizedBox(height: 16),

              // Comfort Features Section
              _buildComfortFeaturesSection(),
              const SizedBox(height: 16),

              // Vehicle Status Section
              _buildVehicleStatusSection(),
              const SizedBox(height: 16),

              // Notes Section
              _buildNotesSection(),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'Update Vehicle' : 'Add Vehicle'),
                ),
              ),
              const SizedBox(height: 32), // Added bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Photo (Optional)',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : InkWell(
                  onTap: _pickImage,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (_selectedImage != null)
          TextButton(
            onPressed: () {
              setState(() {
                _selectedImage = null;
              });
            },
            child: const Text('Remove Photo'),
          ),
      ],
    );
  }

  Widget _buildVehicleTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Type',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VehicleType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(type.icon),
                  const SizedBox(width: 4),
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMakeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Make *',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMake,
          hint: const Text('Select Make'),
          items: VehicleController.popularMakes.map((make) {
            return DropdownMenuItem(
              value: make,
              child: Text(make),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMake = value;
              _selectedModel = null; // Reset model when make changes
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a make';
            }
            return null;
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        if (_selectedMake == 'Other') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customMakeController,
            decoration: const InputDecoration(
              labelText: 'Enter Make',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_selectedMake == 'Other' && (value == null || value.isEmpty)) {
                return 'Please enter the make';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildModelSection() {
    final models = _selectedMake != null 
        ? VehicleController.getModelsByMake(_selectedMake!)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model *',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedModel,
          hint: const Text('Select Model'),
          items: models.map((model) {
            return DropdownMenuItem(
              value: model,
              child: Text(model),
            );
          }).toList(),
          onChanged: _selectedMake != null ? (value) {
            setState(() {
              _selectedModel = value;
            });
          } : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a model';
            }
            return null;
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        if (_selectedModel == 'Other') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customModelController,
            decoration: const InputDecoration(
              labelText: 'Enter Model',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_selectedModel == 'Other' && (value == null || value.isEmpty)) {
                return 'Please enter the model';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildYearSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year *',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedYear,
          hint: const Text('Select Year'),
          items: VehicleController.availableYears.map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedYear = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a year';
            }
            return null;
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color *',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedColor,
          hint: const Text('Select Color'),
          items: VehicleController.popularColors.map((color) {
            return DropdownMenuItem(
              value: color,
              child: Text(color),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedColor = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a color';
            }
            return null;
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        if (_selectedColor == 'Other') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customColorController,
            decoration: const InputDecoration(
              labelText: 'Enter Color',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_selectedColor == 'Other' && (value == null || value.isEmpty)) {
                return 'Please enter the color';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLicensePlateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'License Plate *',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _licensePlateController,
          decoration: const InputDecoration(
            labelText: 'e.g., KHI-1234',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.confirmation_number),
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter license plate number';
            }
            if (value.length < 3) {
              return 'License plate must be at least 3 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSeatsSection() {
    final availableSeats = _selectedSeats > 0 ? _selectedSeats - 1 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Seats',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 4, 5, 6, 7, 8].map((seats) {
            final isSelected = _selectedSeats == seats;
            return ChoiceChip(
              label: Text('$seats'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSeats = seats;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Available for passengers: $availableSeats seats (1 seat reserved for driver)',
                  style: TextStyle(color: Colors.blue[700], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFuelAverageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Average (km/l)',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _fuelAverage,
                min: 5.0,
                max: 25.0,
                divisions: 40,
                onChanged: (value) {
                  setState(() {
                    _fuelAverage = value;
                  });
                },
              ),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_fuelAverage.toStringAsFixed(1)} km/l',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Typical ranges: Car: 10-15 km/l, SUV: 8-12 km/l, Motorcycle: 20-25 km/l',
          style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 600,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get final values
    final make = _selectedMake == 'Other' 
        ? _customMakeController.text.trim()
        : _selectedMake!;
    final model = _selectedModel == 'Other'
        ? _customModelController.text.trim()
        : _selectedModel!;
    final color = _selectedColor == 'Other'
        ? _customColorController.text.trim()
        : _selectedColor!;

    final vehicle = Vehicle(
      id: _isEditing ? widget.vehicle!.id : '',
      userId: 'current_user', // Replace with actual user ID
      make: make,
      model: model,
      year: _selectedYear!,
      color: color,
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      totalSeats: _selectedSeats,
      fuelAverage: _fuelAverage,
      type: _selectedType,
      createdAt: _isEditing ? widget.vehicle!.createdAt : DateTime.now(),
      imageUrl: _selectedImage?.path, // In real app, upload to server first
      // Additional fields
      fuelType: _selectedFuelType ?? 'petrol',
      engineCapacity: _engineCapacityController.text.trim().isEmpty ? null : _engineCapacityController.text.trim(),
      hasAc: _hasAc,
      acType: _selectedAcType ?? 'standard',
      hasMusicSystem: _hasMusicSystem,
      hasPhoneCharger: _hasPhoneCharger,
      smokingAllowed: _smokingAllowed,
      insuranceValid: _insuranceValid,
      fitnessCertificateValid: _fitnessCertificateValid,
      isPrimary: _isPrimary,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    bool success;
    if (_isEditing) {
      success = await _vehicleController.updateVehicle(vehicle);
    } else {
      success = await _vehicleController.addVehicle(vehicle);
    }

    if (success) {
      // Navigate back to vehicle management screen after successful save/update
      if (_isEditing) {
        // For editing, go back to vehicle management screen
        Get.offAndToNamed('/vehicle-management');
      } else {
        // For adding, also go to vehicle management screen to see the new vehicle
        Get.offAndToNamed('/vehicle-management');
      }
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    _customMakeController.dispose();
    _customModelController.dispose();
    _customColorController.dispose();
    _engineCapacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildFuelTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Type',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFuelType,
              hint: const Text('Select fuel type'),
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: ['petrol', 'diesel', 'cng', 'lpg', 'electric', 'hybrid'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFuelType = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngineCapacitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engine Capacity (cc) - Optional',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _engineCapacityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g., 1000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Air Conditioning',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _hasAc,
              onChanged: (value) {
                setState(() {
                  _hasAc = value ?? false;
                  if (!_hasAc) {
                    _selectedAcType = null;
                  }
                });
              },
            ),
            const Text('Has Air Conditioning'),
          ],
        ),
        if (_hasAc) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAcType,
                hint: const Text('Select AC type'),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),                      items: ['none', 'standard', 'climate_control'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAcType = value;
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComfortFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comfort Features',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Music System'),
          value: _hasMusicSystem,
          onChanged: (value) {
            setState(() {
              _hasMusicSystem = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Phone Charger'),
          value: _hasPhoneCharger,
          onChanged: (value) {
            setState(() {
              _hasPhoneCharger = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Smoking Allowed'),
          value: _smokingAllowed,
          onChanged: (value) {
            setState(() {
              _smokingAllowed = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildVehicleStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Status',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Insurance Valid'),
          value: _insuranceValid,
          onChanged: (value) {
            setState(() {
              _insuranceValid = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Fitness Certificate Valid'),
          value: _fitnessCertificateValid,
          onChanged: (value) {
            setState(() {
              _fitnessCertificateValid = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Primary Vehicle'),
          value: _isPrimary,
          onChanged: (value) {
            setState(() {
              _isPrimary = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes - Optional',
          style: Get.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any additional information about your vehicle...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
