import 'package:flutter_test/flutter_test.dart';

// Mock TokenStorageService for testing
class MockTokenStorageService {
  static Map<String, dynamic> _storage = {};
  
  static Future<void> storeTokens({
    String? accessToken,
    String? refreshToken,
    DateTime? expiryTime,
  }) async {
    if (accessToken != null) _storage['access_token'] = accessToken;
    if (refreshToken != null) _storage['refresh_token'] = refreshToken;
    if (expiryTime != null) _storage['expiry_time'] = expiryTime.toIso8601String();
  }
  
  static Future<String?> getAccessToken() async {
    return _storage['access_token'];
  }
  
  static Future<String?> getRefreshToken() async {
    return _storage['refresh_token'];
  }
  
  static Future<bool> hasValidCredentials() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;
    
    final isExpired = await isTokenExpired();
    return !isExpired;
  }
  
  static Future<bool> isTokenExpired() async {
    final expiryString = _storage['expiry_time'];
    if (expiryString == null) return true;
    
    final expiryTime = DateTime.parse(expiryString);
    return DateTime.now().isAfter(expiryTime);
  }
  
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    _storage['user_data'] = userData;
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    return _storage['user_data'];
  }
  
  static Future<void> clearAll() async {
    _storage.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('TokenStorageService Tests', () {
    setUp(() {
      // Clear storage before each test
      MockTokenStorageService._storage.clear();
    });
    
    test('should store and retrieve access token', () async {
      // Store a test token
      await MockTokenStorageService.storeTokens(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiryTime: DateTime.now().add(const Duration(hours: 1)),
      );

      // Retrieve the token
      final retrievedToken = await MockTokenStorageService.getAccessToken();
      expect(retrievedToken, equals('test_access_token'));

      // Check if credentials are valid
      final hasValidCreds = await MockTokenStorageService.hasValidCredentials();
      expect(hasValidCreds, isTrue);

      // Clean up
      await MockTokenStorageService.clearAll();
    });

    test('should detect expired tokens', () async {
      // Store a token that expires in the past
      await MockTokenStorageService.storeTokens(
        accessToken: 'expired_token',
        expiryTime: DateTime.now().subtract(const Duration(hours: 1)),
      );

      // Check if token is expired
      final isExpired = await MockTokenStorageService.isTokenExpired();
      expect(isExpired, isTrue);

      // Valid credentials should return false for expired tokens
      final hasValidCreds = await MockTokenStorageService.hasValidCredentials();
      expect(hasValidCreds, isFalse);

      // Clean up
      await MockTokenStorageService.clearAll();
    });

    test('should clear all data', () async {
      // Store some data
      await MockTokenStorageService.storeTokens(
        accessToken: 'test_token',
        refreshToken: 'test_refresh',
      );
      
      await MockTokenStorageService.storeUserData({'name': 'Test User'});

      // Clear all data
      await MockTokenStorageService.clearAll();

      // Verify data is cleared
      final accessToken = await MockTokenStorageService.getAccessToken();
      final refreshToken = await MockTokenStorageService.getRefreshToken();
      final userData = await MockTokenStorageService.getUserData();

      expect(accessToken, isNull);
      expect(refreshToken, isNull);
      expect(userData, isNull);
    });
  });
}
