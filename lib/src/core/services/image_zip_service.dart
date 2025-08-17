import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'google_oauth_service.dart'; // Import our centralized backup service
import '../controllers/auth_controller.dart';

class ImageZipService extends GetxService {
  // Progress tracking
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isProcessing = false.obs;
  final RxString currentStatus = ''.obs;

  // Centralized backup service
  late CentralizedBackupService _backupService;

  @override
  void onInit() {
    super.onInit();
    // Initialize centralized backup service
    _backupService = CentralizedBackupService(
      baseUrl: 'http://192.168.100.32:8000/api', // Your Django server URL with /api prefix
      authToken: _getAuthToken(),   // User authentication token
    );
  }

  /// Reset progress and status
  void reset() {
    uploadProgress.value = 0.0;
    currentStatus.value = '';
    isProcessing.value = false;
  }

  /// Main method to collect, compress and upload images using centralized backup
  /// Now runs in background to prevent UI blocking
  Future<bool> collectAndUploadImages() async {
    try {
      isProcessing.value = true;
      uploadProgress.value = 0.0;
      currentStatus.value = 'Requesting permissions...';

      // Request permissions with better handling
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      debugPrint('📱 Photo permission status: $permission');
      
      if (permission != PermissionState.authorized) {
        String errorMessage = 'Photo permission denied.';
        String userAction = 'Please check app settings.';
        
        switch (permission) {
          case PermissionState.denied:
            errorMessage = 'Photo access denied. Please grant permission to backup images.';
            userAction = 'Go to Settings > Apps > Carwaan > Permissions > Photos and allow access.';
            break;
          case PermissionState.restricted:
            errorMessage = 'Photo access restricted. Check device settings.';
            userAction = 'Check your device restrictions or parental controls.';
            break;
          case PermissionState.limited:
            // For limited access, we can still proceed but warn the user
            debugPrint('⚠️ Limited photo access granted - proceeding with backup');
            currentStatus.value = 'Limited photo access - some images may not be backed up';
            // Don't throw error, continue with limited access
            break;
          default:
            errorMessage = 'Photo permission denied. Please enable photo access in settings.';
            userAction = 'Go to Settings > Apps > Carwaan > Permissions and enable photo access.';
        }
        
        if (permission != PermissionState.limited) {
          debugPrint('❌ Permission error: $errorMessage');
          debugPrint('💡 User action: $userAction');
          currentStatus.value = 'Permission denied - Check app settings';
          throw Exception(errorMessage);
        }
      }

      currentStatus.value = 'Loading images...';
      uploadProgress.value = 0.1;

      // Get all image assets
      final List<AssetEntity> images = await _getAllImages();
      if (images.isEmpty) {
        throw Exception('No images found');
      }

      debugPrint('📊 Found ${images.length} images to backup');
      currentStatus.value = 'Starting background upload...';
      uploadProgress.value = 0.2;

      // Run upload process in background to prevent UI blocking
      return await _processImagesInBackground(images);
      
    } catch (e) {
      debugPrint('❌ Error in collectAndUploadImages: $e');
      currentStatus.value = 'Error: ${e.toString()}';
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Process images in background thread to prevent UI blocking
  Future<bool> _processImagesInBackground(List<AssetEntity> images) async {
    try {
      // Refresh authentication token
      await _refreshAuthToken();
      
      int successCount = 0;
      int failureCount = 0;
      
      // Process images in small batches to prevent memory issues
      const int batchSize = 10; // Process 10 images at a time
      
      for (int batchStart = 0; batchStart < images.length; batchStart += batchSize) {
        final int batchEnd = (batchStart + batchSize < images.length) 
            ? batchStart + batchSize 
            : images.length;
        
        final List<AssetEntity> batch = images.sublist(batchStart, batchEnd);
        
        // Process batch in background
        for (int i = 0; i < batch.length; i++) {
          final int globalIndex = batchStart + i;
          
          try {
            currentStatus.value = 'Uploading image ${globalIndex + 1}/${images.length}...';
            
            // Run image processing in compute to prevent UI blocking
            final String imageZipPath = await _createSingleImageZip(batch[i], globalIndex);
            
            final Map<String, dynamic> result = await _backupService.uploadToCentralizedBackup(
              zipFilePath: imageZipPath,
              imageCount: 1,
              onProgress: (progress) {
                // Update progress
                final double baseProgress = 0.2 + (0.8 * globalIndex / images.length);
                final double imageProgress = 0.8 * progress / images.length;
                uploadProgress.value = baseProgress + imageProgress;
              },
            );
            
            // Clean up individual ZIP file
            try {
              await File(imageZipPath).delete();
            } catch (e) {
              debugPrint('⚠️ Could not delete temp file: $e');
            }
            
            if (result['success']) {
              successCount++;
              debugPrint('✅ Successfully uploaded image ${globalIndex + 1}/${images.length}');
            } else {
              failureCount++;
              debugPrint('❌ Failed to upload image ${globalIndex + 1}: ${result['error']}');
            }
            
            // Update overall progress
            uploadProgress.value = 0.2 + (0.8 * (globalIndex + 1) / images.length);
            
          } catch (e) {
            failureCount++;
            debugPrint('❌ Error uploading image ${globalIndex + 1}: $e');
            continue;
          }
        }
        
        // Small delay between batches to prevent overwhelming the system
        if (batchEnd < images.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      debugPrint('📊 Upload completed: $successCount success, $failureCount failures');
      
      if (successCount > 0) {
        uploadProgress.value = 1.0;
        currentStatus.value = 'Upload completed: $successCount/${images.length} images uploaded successfully';
        return true;
      } else {
        throw Exception('All image uploads failed. Please check your connection and try again.');
      }
      
    } catch (e) {
      debugPrint('❌ Error in background processing: $e');
      rethrow;
    }
  }

  /// Get all image assets from device
  Future<List<AssetEntity>> _getAllImages() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return [];

    final AssetPathEntity allPhotos = albums.first;
    final int totalCount = await allPhotos.assetCountAsync;
    
    debugPrint('📊 Found $totalCount total images');
    
    // Since we're processing images individually, we can handle all images without memory issues
    final List<AssetEntity> images = await allPhotos.getAssetListRange(
      start: 0,
      end: totalCount,
    );

    debugPrint('📱 Loaded ${images.length} images for processing');
    return images;
  }

  /// Create ZIP file containing a single image
  Future<String> _createSingleImageZip(AssetEntity image, int index) async {
    // Get temporary directory
    final Directory tempDir = await getTemporaryDirectory();
    final String zipFilePath = path.join(
      tempDir.path, 
      'image_${index}_${DateTime.now().millisecondsSinceEpoch}.zip'
    );

    try {
      final File? file = await image.file;
      if (file == null) {
        throw Exception('Could not get file for image $index');
      }

      final Uint8List bytes = await file.readAsBytes();
      final String filename = '${image.title ?? 'image_$index'}.${image.title?.split('.').last ?? 'jpg'}';
      
      // Create archive with single image
      final Archive archive = Archive();
      archive.addFile(ArchiveFile(filename, bytes.length, bytes));
      
      // Create ZIP data
      final List<int> zipData = ZipEncoder().encode(archive);
      
      // Write ZIP data to file
      final File zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipData);
      
      debugPrint('📦 Created single image ZIP: ${(zipData.length / 1024).toStringAsFixed(1)} KB');
      return zipFilePath;
      
    } catch (e) {
      debugPrint('❌ Failed to create ZIP for image $index: $e');
      rethrow;
    }
  }

  /// Get authentication token from AuthController
  String _getAuthToken() {
    try {
      final AuthController authController = Get.find<AuthController>();
      return authController.token.value;
    } catch (e) {
      debugPrint('❌ Could not get auth token: $e');
      return '';
    }
  }

  /// Refresh the authentication token and update the backup service
  Future<void> _refreshAuthToken() async {
    try {
      final AuthController authController = Get.find<AuthController>();
      
      // Check if token needs refresh
      if (authController.token.value.isEmpty) {
        debugPrint('🔑 No token available, user needs to login');
        throw Exception('Authentication required. Please login again.');
      }
      
      // Get fresh token (this may trigger token refresh in AuthController)
      final freshToken = authController.token.value;
      
      // Update backup service with fresh token
      _backupService = CentralizedBackupService(
        baseUrl: 'http://192.168.100.32:8000/api',
        authToken: freshToken,
      );
      
      debugPrint('🔄 Updated backup service with fresh token');
    } catch (e) {
      debugPrint('❌ Failed to refresh auth token: $e');
      rethrow;
    }
  }

  /// Check if centralized backup service is available
  Future<bool> isBackupServiceAvailable() async {
    try {
      // Refresh token before checking service
      await _refreshAuthToken();
      
      final result = await _backupService.checkBackupServiceStatus();
      
      if (result['available'] == true) {
        debugPrint('✅ Backup service is available');
        return true;
      } else {
        debugPrint('❌ Backup service not available: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking backup service: $e');
      
      // If there's a 401 error, try refreshing token and retry once
      if (e.toString().contains('401')) {
        try {
          await _refreshAuthToken();
          final result = await _backupService.checkBackupServiceStatus();
          return result['available'] == true;
        } catch (retryError) {
          debugPrint('❌ Retry failed: $retryError');
          return false;
        }
      }
      
      return false;
    }
  }
}
