import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'api_service.dart';
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
      baseUrl: ApiService.baseUrl, // Your Django server URL
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
  Future<bool> collectAndUploadImages() async {
    try {
      isProcessing.value = true;
      uploadProgress.value = 0.0;
      currentStatus.value = 'Requesting permissions...';

      // Request permissions
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      if (permission != PermissionState.authorized) {
        throw Exception('Photo permission denied');
      }

      currentStatus.value = 'Loading images...';
      uploadProgress.value = 0.1;

      // Get all image assets
      final List<AssetEntity> images = await _getAllImages();
      if (images.isEmpty) {
        throw Exception('No images found');
      }

      debugPrint('📸 Found ${images.length} images');
      currentStatus.value = 'Compressing images...';
      uploadProgress.value = 0.2;

      // Create ZIP file and save to temp directory
      final String zipFilePath = await _createZipFileFromImages(images);
      
      currentStatus.value = 'Uploading to centralized backup...';
      uploadProgress.value = 0.7;

      // Upload using centralized backup service
      final Map<String, dynamic> result = await _backupService.uploadToCentralizedBackup(
        zipFilePath: zipFilePath,
        imageCount: images.length,
        onProgress: (progress) {
          // Update progress: 0.7 base + 0.3 for upload progress
          uploadProgress.value = 0.7 + (progress * 0.3);
        },
      );
      
      // Clean up temp file
      try {
        await File(zipFilePath).delete();
      } catch (e) {
        debugPrint('⚠️ Could not delete temp file (Windows file locking): $e');
      }

      if (result['success']) {
        uploadProgress.value = 1.0;
        currentStatus.value = 'Backup completed successfully!';
        
        debugPrint('✅ Centralized backup successful!');
        debugPrint('📁 Upload method: ${result['upload_method']}');
        debugPrint('📂 Backup location: ${result['backup_location']}');
        debugPrint('🔗 File ID: ${result['file_id'] ?? 'N/A'}');
        debugPrint('🌐 Web link: ${result['web_link'] ?? 'N/A'}');
        
        return true;
      } else {
        currentStatus.value = 'Backup failed: ${result['error']}';
        debugPrint('❌ Centralized backup failed: ${result['error']}');
        debugPrint('📋 Details: ${result['details'] ?? 'No details'}');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Error in collectAndUploadImages: $e');
      currentStatus.value = 'Error: ${e.toString()}';
      return false;
    } finally {
      isProcessing.value = false;
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
    final List<AssetEntity> images = await allPhotos.getAssetListRange(
      start: 0,
      end: await allPhotos.assetCountAsync,
    );

    return images;
  }

  /// Create ZIP file from images and save to temp directory
  Future<String> _createZipFileFromImages(List<AssetEntity> images) async {
    // Get temporary directory
    final Directory tempDir = await getTemporaryDirectory();
    final String zipFilePath = path.join(
      tempDir.path, 
      'user_images_backup_${DateTime.now().millisecondsSinceEpoch}.zip'
    );

    // Prepare data for background compression
    final List<Map<String, dynamic>> imageData = [];
    
    for (int i = 0; i < images.length; i++) {
      final AssetEntity image = images[i];
      final File? file = await image.file;
      
      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        imageData.add({
          'filename': '${image.title ?? 'image_$i'}.${image.title?.split('.').last ?? 'jpg'}',
          'bytes': bytes,
        });
        
        // Update progress as we collect images
        uploadProgress.value = 0.2 + (0.5 * (i + 1) / images.length);
        currentStatus.value = 'Processing image ${i + 1}/${images.length}...';
      }
    }

    // Create ZIP file in background
    final Uint8List zipData = await compute(_createZipArchive, imageData);

    // Write ZIP data to file
    final File zipFile = File(zipFilePath);
    await zipFile.writeAsBytes(zipData);

    debugPrint('📦 Created ZIP file: $zipFilePath');
    debugPrint('📏 ZIP size: ${(zipData.length / 1024 / 1024).toStringAsFixed(2)} MB');

    return zipFilePath;
  }

  /// Get authentication token
  String? _getAuthToken() {
    try {
      final AuthController authController = Get.find<AuthController>();
      return authController.token.value;
    } catch (e) {
      debugPrint('⚠️ Could not get auth token: $e');
      return null;
    }
  }

  /// Check if centralized backup service is available
  Future<bool> isBackupServiceAvailable() async {
    try {
      final result = await _backupService.checkBackupServiceStatus();
      return result['available'] ?? false;
    } catch (e) {
      debugPrint('❌ Error checking backup service: $e');
      return false;
    }
  }
}

/// Static function to create ZIP archive in isolate
Uint8List _createZipArchive(List<Map<String, dynamic>> imageData) {
  final Archive archive = Archive();

  for (final Map<String, dynamic> data in imageData) {
    final String filename = data['filename'] as String;
    final Uint8List bytes = data['bytes'] as Uint8List;

    final ArchiveFile file = ArchiveFile(filename, bytes.length, bytes);
    archive.addFile(file);
  }

  return Uint8List.fromList(ZipEncoder().encode(archive));
}
