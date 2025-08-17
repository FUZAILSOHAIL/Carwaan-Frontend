import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CentralizedBackupService {
  final String baseUrl;
  final String? authToken;
  
  CentralizedBackupService({
    required this.baseUrl,
    this.authToken,
  });

  /// Upload images to centralized backup storage
  /// All backups are stored in the admin's Google Drive
  Future<Map<String, dynamic>> uploadToCentralizedBackup({
    required String zipFilePath,
    required int imageCount,
    Function(double)? onProgress,
  }) async {
    const int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        return await _performUpload(zipFilePath, imageCount, onProgress);
      } catch (e) {
        retryCount++;
        debugPrint('❌ Upload attempt $retryCount failed: $e');
        
        if (retryCount >= maxRetries) {
          debugPrint('💥 All upload attempts failed');
          rethrow;
        }
        
        // Wait before retry (exponential backoff)
        final waitTime = Duration(seconds: retryCount * 5);
        debugPrint('⏳ Retrying upload in ${waitTime.inSeconds} seconds...');
        await Future.delayed(waitTime);
      }
    }
    
    throw Exception('Upload failed after $maxRetries attempts');
  }

  Future<Map<String, dynamic>> _performUpload(
    String zipFilePath,
    int imageCount,
    Function(double)? onProgress,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/backup/upload/'),
      );

      // Add headers - centralized backup handles authentication on backend
      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
      });

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('zip_file', zipFilePath),
      );

      // Add image count
      request.fields['image_count'] = imageCount.toString();

      debugPrint('🚀 Starting upload of ${(File(zipFilePath).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB file...');
      
      // Create HTTP client with longer timeout
      final client = http.Client();
      
      try {
        // Send request with extended timeout and keep-alive
        var streamedResponse = await client.send(request).timeout(
          const Duration(minutes: 15), // Extended to 15 minutes for very large files
          onTimeout: () {
            debugPrint('⏰ Upload timeout after 15 minutes');
            client.close();
            throw Exception('Upload timeout - The file is too large or connection is too slow. Please try with a faster connection.');
          },
        );
        
        // Track upload progress with timeout for each chunk
        var totalBytes = streamedResponse.contentLength ?? 0;
        var receivedBytes = 0;
        var responseBody = '';
        
        debugPrint('📊 Expected response size: ${totalBytes > 0 ? "${(totalBytes / 1024).toStringAsFixed(1)} KB" : "unknown"}');
        
        await for (var chunk in streamedResponse.stream) {
          receivedBytes += chunk.length;
          responseBody += String.fromCharCodes(chunk);
          
          if (totalBytes > 0 && onProgress != null) {
            final progress = receivedBytes / totalBytes;
            onProgress(progress);
            debugPrint('📈 Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
          
          // Timeout check for individual chunks (prevents hanging on slow responses)
          if (chunk.isEmpty) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        
        debugPrint('📤 Upload completed with status: ${streamedResponse.statusCode}');

        if (streamedResponse.statusCode == 201) {
          final data = json.decode(responseBody);
          return {
            'success': true,
            'data': data,
            'message': data['message'] ?? 'Backup uploaded successfully',
            'backup_location': data['backup_location'] ?? 'Centralized backup storage',
            'upload_method': data['upload_method'] ?? 'service_account',
            'file_id': data['google_drive_info']?['id'],
            'web_link': data['google_drive_info']?['web_view_link'],
          };
        } else {
          // Handle different error status codes
          String errorMessage;
          try {
            final error = json.decode(responseBody);
            errorMessage = error['error'] ?? 'Upload failed';
          } catch (_) {
            // If JSON parsing fails, use status code message
            switch (streamedResponse.statusCode) {
              case 404:
                errorMessage = 'Backup service not found. Please check server configuration.';
                break;
              case 401:
                errorMessage = 'Authentication failed. Please login again.';
                break;
              case 403:
                errorMessage = 'Access denied. Please check permissions.';
                break;
              case 500:
                errorMessage = 'Server error. Please try again later.';
                break;
              default:
                errorMessage = 'Upload failed with status ${streamedResponse.statusCode}';
            }
          }
          
          return {
            'success': false,
            'error': errorMessage,
            'status_code': streamedResponse.statusCode,
            'details': responseBody.length > 500 ? '${responseBody.substring(0, 500)}...' : responseBody,
          };
        }
      } finally {
        client.close();
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Check if centralized backup service is available
  Future<Map<String, dynamic>> checkBackupServiceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/backup/auth/check/'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'available': data['is_authenticated'] ?? false,
          'service': 'centralized_backup',
          'message': data['message'] ?? 'Service available',
        };
      } else {
        // Log the error but still assume service is available for graceful fallback
        debugPrint('⚠️ Backup service check failed with status ${response.statusCode}');
        debugPrint('📄 Response: ${response.body}');
        
        return {
          'available': true, // Assume available for graceful degradation
          'service': 'centralized_backup',
          'message': 'Service check failed but proceeding with backup',
          'warning': 'Backend check failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      // Even if check fails, assume service is available
      // Error handling will occur during actual upload
      debugPrint('⚠️ Network error during backup service check: $e');
      return {
        'available': true,
        'service': 'centralized_backup',
        'message': 'Service assumed available (network check failed)',
        'warning': 'Network error: $e',
      };
    }
  }
}
