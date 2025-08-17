import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/controllers/auth_controller.dart';

// CNIC Input Formatter
class CNICInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 13 digits maximum
    if (digitsOnly.length > 13) {
      digitsOnly = digitsOnly.substring(0, 13);
    }
    
    // Format with dashes
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 5 || i == 12) {
        formatted += '-';
      }
      formatted += digitsOnly[i];
    }
    
    // Calculate the new cursor position
    int newOffset = formatted.length;
    if (newValue.selection.baseOffset < oldValue.text.length) {
      // If user is editing in the middle, try to maintain relative position
      int oldDigitsBeforeCursor = oldValue.text.substring(0, newValue.selection.baseOffset).replaceAll(RegExp(r'[^0-9]'), '').length;
      int newPosition = 0;
      int digitCount = 0;
      
      for (int i = 0; i < formatted.length; i++) {
        if (digitCount == oldDigitsBeforeCursor) {
          newPosition = i;
          break;
        }
        if (formatted[i] != '-') {
          digitCount++;
        }
        newPosition = i + 1;
      }
      newOffset = newPosition;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = Get.find<ApiService>();
  final MessageService messageService = Get.find<MessageService>();
  final AuthController authController = Get.find<AuthController>();
  
  // Form controllers
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  
  // Images
  File? _cnicFrontImage;
  File? _cnicBackImage;
  File? _licenseFrontImage;
  File? _licenseBackImage;
  
  // Image URLs from server (for previously uploaded images)
  String? _cnicFrontImageUrl;
  String? _cnicBackImageUrl;
  String? _licenseFrontImageUrl;
  String? _licenseBackImageUrl;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _verificationStatus = 'pending';
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint('🔍 Loading driver verification status...');
      final status = await apiService.getDriverVerificationStatus();
      debugPrint('🔍 Driver Verification API Response: $status');
      
      if (status != null) {
        setState(() {
          // Extract text field values with fallbacks
          _cnicController.text = status['cnic_number']?.toString() ?? '';
          _licenseController.text = status['driver_license_number']?.toString() ?? '';
          _verificationStatus = status['verification_status']?.toString() ?? 'pending';
          
          debugPrint('🔍 Parsed values:');
          debugPrint('  - CNIC: ${_cnicController.text}');
          debugPrint('  - License: ${_licenseController.text}');
          debugPrint('  - Status: $_verificationStatus');
          
          // Load image URLs if they exist
          final images = status['images'];
          if (images != null && images is Map) {
            _cnicFrontImageUrl = images['cnic_front_image']?.toString();
            _cnicBackImageUrl = images['cnic_back_image']?.toString();
            _licenseFrontImageUrl = images['driver_license_front_image']?.toString();
            _licenseBackImageUrl = images['driver_license_back_image']?.toString();
            
            debugPrint('🔍 Image URLs loaded:');
            debugPrint('  - CNIC Front: $_cnicFrontImageUrl');
            debugPrint('  - CNIC Back: $_cnicBackImageUrl');
            debugPrint('  - License Front: $_licenseFrontImageUrl');
            debugPrint('  - License Back: $_licenseBackImageUrl');
          } else {
            debugPrint('🔍 No images found in response');
          }
        });
        
        // If fields are still empty, try to get from current user profile
        if (_cnicController.text.isEmpty || _licenseController.text.isEmpty) {
          await _loadFromUserProfile();
        }
      } else {
        debugPrint('🔍 API returned null response - loading from user profile');
        await _loadFromUserProfile();
      }
    } catch (e) {
      debugPrint('❌ Error loading verification status: $e');
      messageService.showError('Failed to load verification status. Using cached data.');
      // Try to load from user profile as fallback
      await _loadFromUserProfile();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromUserProfile() async {
    try {
      debugPrint('🔄 Loading from user profile...');
      final user = authController.currentUser.value;
      if (user != null) {
        setState(() {
          if (_cnicController.text.isEmpty && user.cnicNumber != null) {
            _cnicController.text = user.cnicNumber!;
          }
          if (_licenseController.text.isEmpty && user.driverLicenseNumber != null) {
            _licenseController.text = user.driverLicenseNumber!;
          }
          if (_verificationStatus == 'pending' && user.driverVerificationStatus != null) {
            _verificationStatus = user.driverVerificationStatus!;
          }
        });
        debugPrint('🔄 Loaded from user profile:');
        debugPrint('  - CNIC: ${_cnicController.text}');
        debugPrint('  - License: ${_licenseController.text}');
        debugPrint('  - Status: $_verificationStatus');
      } else {
        debugPrint('🔄 No user data available in profile');
      }
    } catch (e) {
      debugPrint('❌ Error loading from user profile: $e');
    }
  }

  Future<void> _pickImage(String type) async {
    // First, remove focus from any text fields before showing the dialog
    FocusScope.of(context).unfocus();
    
    // Add a small delay to ensure focus is properly removed
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Show dialog to choose between camera and gallery
    if (!mounted) return;
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    // Immediately remove focus after dialog closes, regardless of selection
    if (mounted) {
      FocusScope.of(context).unfocus();
      
      // Add a delay to ensure dialog closing animation completes
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Remove focus again to ensure it's cleared
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    }

    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          switch (type) {
            case 'cnic_front':
              _cnicFrontImage = File(image.path);
              break;
            case 'cnic_back':
              _cnicBackImage = File(image.path);
              break;
            case 'license_front':
              _licenseFrontImage = File(image.path);
              break;
            case 'license_back':
              _licenseBackImage = File(image.path);
              break;
          }
        });
        
        // Remove focus again after image selection
        if (mounted) {
          FocusScope.of(context).unfocus();
        }
      }
    }
    
    // Ensure focus is removed after the entire process
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if this is a first-time submission (no existing images)
    bool hasExistingImages = (_cnicFrontImageUrl != null && _cnicFrontImageUrl!.isNotEmpty) ||
                            (_cnicBackImageUrl != null && _cnicBackImageUrl!.isNotEmpty) ||
                            (_licenseFrontImageUrl != null && _licenseFrontImageUrl!.isNotEmpty) ||
                            (_licenseBackImageUrl != null && _licenseBackImageUrl!.isNotEmpty);

    if (!hasExistingImages) {
      // First-time submission - require all images
      if (_cnicFrontImage == null || _cnicBackImage == null || 
          _licenseFrontImage == null || _licenseBackImage == null) {
        messageService.showError('Please upload all required images');
        return;
      }
    } else {
      // Resubmission - check if at least one field has changed
      bool hasChanges = false;
      
      // Check if text fields have changed from the original values
      final user = authController.currentUser.value;
      if (user != null) {
        if (_cnicController.text.trim() != (user.cnicNumber ?? '')) {
          hasChanges = true;
          debugPrint('📝 CNIC changed: "${user.cnicNumber}" -> "${_cnicController.text.trim()}"');
        }
        if (_licenseController.text.trim() != (user.driverLicenseNumber ?? '')) {
          hasChanges = true;
          debugPrint('📝 License changed: "${user.driverLicenseNumber}" -> "${_licenseController.text.trim()}"');
        }
      }
      
      // Check if any new images have been selected
      if (_cnicFrontImage != null || _cnicBackImage != null || 
          _licenseFrontImage != null || _licenseBackImage != null) {
        hasChanges = true;
        debugPrint('📝 New images selected');
      }
      
      if (!hasChanges) {
        messageService.showError('Please make changes to your information or select new images to resubmit');
        return;
      }
      
      // For resubmission, we need at least the existing images or new ones for each document
      List<String> missingDocuments = [];
      
      if (_cnicFrontImage == null && (_cnicFrontImageUrl == null || _cnicFrontImageUrl!.isEmpty)) {
        missingDocuments.add('CNIC Front');
      }
      if (_cnicBackImage == null && (_cnicBackImageUrl == null || _cnicBackImageUrl!.isEmpty)) {
        missingDocuments.add('CNIC Back');
      }
      if (_licenseFrontImage == null && (_licenseFrontImageUrl == null || _licenseFrontImageUrl!.isEmpty)) {
        missingDocuments.add('License Front');
      }
      if (_licenseBackImage == null && (_licenseBackImageUrl == null || _licenseBackImageUrl!.isEmpty)) {
        missingDocuments.add('License Back');
      }
      
      if (missingDocuments.isNotEmpty) {
        messageService.showError('Please upload images for: ${missingDocuments.join(', ')}');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await apiService.submitDriverVerification(
        cnicNumber: _cnicController.text.trim(),
        driverLicenseNumber: _licenseController.text.trim(),
        cnicFrontImage: _cnicFrontImage,
        cnicBackImage: _cnicBackImage,
        licenseFrontImage: _licenseFrontImage,
        licenseBackImage: _licenseBackImage,
      );

      messageService.showSuccess('Verification documents submitted successfully!');
      
      // Refresh user data and verification status
      await authController.refreshUserData();
      await _loadVerificationStatus();
      
      // Navigate to create ride page
      Get.offAndToNamed('/create-ride');
    } catch (e) {
      messageService.showError('Failed to submit verification: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Verification'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVerificationStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildPersonalInfoSection(),
                      const SizedBox(height: 24),
                      _buildDocumentSection(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 32), // Bottom padding
                    ],
                  ),
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
              Icons.verified_user,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Driver Verification',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildStatusIndicator(),
            const SizedBox(height: 8),
            Text(
              _getStatusDescription(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_verificationStatus) {
      case 'pending':
        statusColor = Colors.grey;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'under_review':
        statusColor = Colors.orange;
        statusText = 'Under Review';
        statusIcon = Icons.rate_review;
        break;
      case 'verified':
        statusColor = Colors.green;
        statusText = 'Verified';
        statusIcon = Icons.verified;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription() {
    switch (_verificationStatus) {
      case 'pending':
        return 'Complete your driver verification to start offering rides.';
      case 'under_review':
        return 'Your documents are being reviewed. You\'ll be notified once approved.';
      case 'verified':
        return 'Congratulations! You can now create and offer rides.';
      case 'rejected':
        return 'Your verification was rejected. Please resubmit with correct documents.';
      default:
        return 'Complete your driver verification to start offering rides.';
    }
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cnicController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                CNICInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'CNIC Number',
                hintText: '42101-1019754-7',
                prefixIcon: Icon(Icons.credit_card),
                helperText: 'Enter 13-digit CNIC number',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your CNIC number';
                }
                // Remove dashes for length validation
                String digitsOnly = value.replaceAll('-', '');
                if (digitsOnly.length != 13) {
                  return 'CNIC must be 13 digits long';
                }
                if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(value.trim())) {
                  return 'CNIC format should be: 42101-1019754-7';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseController,
              enableInteractiveSelection: true,
              decoration: const InputDecoration(
                labelText: 'Driving License Number',
                hintText: 'Enter your driving license number',
                prefixIcon: Icon(Icons.drive_eta),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your driving license number';
                }
                return null;
              },
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
              'Document Photos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload clear photos of your documents',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            _buildImageUploadSection('CNIC Front', 'cnic_front', _cnicFrontImage),
            const SizedBox(height: 16),
            _buildImageUploadSection('CNIC Back', 'cnic_back', _cnicBackImage),
            const SizedBox(height: 16),
            _buildImageUploadSection('Driving License Front', 'license_front', _licenseFrontImage),
            const SizedBox(height: 16),
            _buildImageUploadSection('Driving License Back', 'license_back', _licenseBackImage),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(String title, String type, File? image) {
    // Get the corresponding image URL based on type
    String? imageUrl;
    switch (type) {
      case 'cnic_front':
        imageUrl = _cnicFrontImageUrl;
        break;
      case 'cnic_back':
        imageUrl = _cnicBackImageUrl;
        break;
      case 'license_front':
        imageUrl = _licenseFrontImageUrl;
        break;
      case 'license_back':
        imageUrl = _licenseBackImageUrl;
        break;
    }

    // Determine if we have an image (either local file or URL)
    bool hasImage = image != null || (imageUrl != null && imageUrl.isNotEmpty);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(type),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: image != null
                        ? Image.file(
                            image,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    size: 48,
                                    color: Colors.red.shade500,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 48,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (hasImage)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  image != null ? 'New photo selected' : 'Photo uploaded',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    // Don't show submit button if already verified
    if (_verificationStatus == 'verified') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text(
              'Verification Complete',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Show status message if under review
    if (_verificationStatus == 'under_review') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your documents are under review',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitVerification,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.orange,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Resubmit Documents',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      );
    }

    // Default submit button for pending or rejected status
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitVerification,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _verificationStatus == 'rejected' ? 'Resubmit for Verification' : 'Submit for Verification',
              style: const TextStyle(fontSize: 16),
            ),
    );
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
}
