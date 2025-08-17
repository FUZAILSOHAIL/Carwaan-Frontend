import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/controllers/auth_controller.dart';

final ApiService apiService = Get.find<ApiService>();

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();
  final MessageService messageService = Get.find<MessageService>();
  
  // Form controllers
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  
  int _seats = 4;
  File? _registrationBookImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Registration'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildSeatsSection(),
              const SizedBox(height: 24),
              _buildDocumentSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.directions_car,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Register Your Vehicle',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your vehicle details and upload your registration book for verification.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _makeController,
              decoration: const InputDecoration(
                labelText: 'Make (Brand)',
                hintText: 'e.g., Toyota, Honda, Suzuki',
                prefixIcon: Icon(Icons.directions_car),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter vehicle make';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'e.g., Corolla, Civic, Alto',
                prefixIcon: Icon(Icons.car_repair),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter vehicle model';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                hintText: 'e.g., 2020',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter vehicle year';
                }
                final year = int.tryParse(value);
                if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                hintText: 'e.g., White, Black, Silver',
                prefixIcon: Icon(Icons.palette),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter vehicle color';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateNumberController,
              decoration: const InputDecoration(
                labelText: 'License Plate Number',
                hintText: 'e.g., ABC-123',
                prefixIcon: Icon(Icons.pin),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter license plate number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seating Capacity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'How many passengers can your vehicle accommodate?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.people, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Number of seats: $_seats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_seats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: _seats < 8 ? () => setState(() => _seats++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of your vehicle registration book for verification.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickRegistrationBookImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _registrationBookImage != null 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: _registrationBookImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _registrationBookImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload registration book',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG up to 10MB',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitRegistration,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Register Vehicle'),
    );
  }

  Future<void> _pickRegistrationBookImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (image != null) {
        setState(() {
          _registrationBookImage = File(image.path);
        });
      }
    } catch (e) {
      messageService.showError('Failed to pick image: $e');
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_registrationBookImage == null) {
      messageService.showError('Please upload vehicle registration book');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create vehicle data map
      final vehicleData = {
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'color': _colorController.text.trim(),
        'plate_number': _plateNumberController.text.trim(),
        'seats': _seats,
        // Note: For file upload, would need FormData - simplified for now
      };

      await apiService.createVehicle(vehicleData);

      messageService.showSuccess('Vehicle registered successfully! Verification pending.');
      Get.back(result: true);
    } catch (e) {
      messageService.showError('Failed to register vehicle: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }
}
