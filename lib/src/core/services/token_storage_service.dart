import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';
  
  // Use secure storage for sensitive tokens
  static const _secureStorage = FlutterSecureStorage();

  /// Store access and refresh tokens securely
  static Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiryTime,
  }) async {
    try {
      // Store access token securely
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      
      // Store refresh token if provided
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      // Store expiry time
      if (expiryTime != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
      }
      
      debugPrint('🔐 Tokens stored securely');
    } catch (e) {
      debugPrint('❌ Error storing tokens: $e');
    }
  }

  /// Get access token from secure storage
  static Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('❌ Error reading access token: $e');
      return null;
    }
  }

  /// Get refresh token from secure storage
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error reading refresh token: $e');
      return null;
    }
  }

  /// Check if access token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_tokenExpiryKey);
      
      if (expiryString == null) return false; // No expiry set, assume valid
      
      final expiryTime = DateTime.parse(expiryString);
      final now = DateTime.now();
      
      // Consider token expired if it expires within the next 5 minutes
      return now.isAfter(expiryTime.subtract(const Duration(minutes: 5)));
    } catch (e) {
      debugPrint('❌ Error checking token expiry: $e');
      return false;
    }
  }

  /// Store user data
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
      debugPrint('💾 User data stored');
    } catch (e) {
      debugPrint('❌ Error storing user data: $e');
    }
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      
      if (userDataString != null) {
        return jsonDecode(userDataString);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error reading user data: $e');
      return null;
    }
  }

  /// Clear all stored authentication data
  static Future<void> clearAll() async {
    try {
      // Clear secure storage
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_tokenExpiryKey);
      
      debugPrint('🗑️ All authentication data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing authentication data: $e');
    }
  }

  /// Check if user has valid stored credentials
  static Future<bool> hasValidCredentials() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('🔍 No access token found');
        return false;
      }
      
      // Check if token is expired
      final isExpired = await isTokenExpired();
      if (isExpired) {
        debugPrint('🔍 Access token is expired');
        return false;
      }
      
      debugPrint('✅ Valid credentials found');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking credentials: $e');
      return false;
    }
  }

  /// Check if we have any stored authentication data (regardless of validity)
  static Future<bool> hasStoredCredentials() async {
    try {
      final accessToken = await getAccessToken();
      final userData = await getUserData();
      
      return (accessToken != null && accessToken.isNotEmpty) || 
             (userData != null && userData.isNotEmpty);
    } catch (e) {
      debugPrint('❌ Error checking stored credentials: $e');
      return false;
    }
  }

  /// Get token expiry time
  static Future<DateTime?> getTokenExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_tokenExpiryKey);
      
      if (expiryString != null) {
        return DateTime.parse(expiryString);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error reading token expiry: $e');
      return null;
    }
  }
}
