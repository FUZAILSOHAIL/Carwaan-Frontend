import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'api_service.dart';

class ConnectionStatusService extends GetxService {
  static ConnectionStatusService get instance => Get.find<ConnectionStatusService>();
  
  late final ApiService _apiService;
  Timer? _connectionTimer;
  
  // Observable connection status
  final RxBool isConnected = true.obs;
  final RxString connectionError = ''.obs;
  
  // Connection check intervals (in seconds)
  static const int _baseCheckInterval = 60; // Base interval: 60 seconds (increased from 30)
  static const int _maxRetryInterval = 600; // Max 10 minutes (increased from 5)
  int _currentRetryInterval = 60;
  bool _isRateLimited = false;
  
  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    startMonitoring();
  }
  
  @override
  void onClose() {
    stopMonitoring();
    super.onClose();
  }
  
  /// Start monitoring the connection to the backend
  void startMonitoring() {
    debugPrint('🔄 Starting connection monitoring...');
    
    // Check immediately
    _checkConnection();
    
    // Set up periodic checks
    _scheduleNextCheck();
  }
  
  /// Schedule the next connection check
  void _scheduleNextCheck() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer(
      Duration(seconds: _currentRetryInterval),
      () {
        _checkConnection();
        _scheduleNextCheck();
      },
    );
  }
  
  /// Stop monitoring the connection
  void stopMonitoring() {
    debugPrint('⏹️ Stopping connection monitoring...');
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }
  
  /// Check connection status
  Future<void> _checkConnection() async {
    try {
      final bool connected = await _apiService.testConnection();
      
      // Reset retry interval on successful connection
      if (connected) {
        _currentRetryInterval = _baseCheckInterval;
        _isRateLimited = false;
      }
      
      if (connected != isConnected.value) {
        isConnected.value = connected;
        connectionError.value = '';
        
        if (connected) {
          debugPrint('✅ Backend server reconnected');
        } else {
          debugPrint('❌ Backend server disconnected');
          connectionError.value = 'Server disconnected';
          _increaseRetryInterval();
        }
      }
    } catch (e) {
      final errorMessage = e.toString();
      
      // Handle rate limiting
      if (errorMessage.contains('429') || errorMessage.contains('Too Many Requests')) {
        _isRateLimited = true;
        // For development, increase interval more aggressively when rate limited
        _currentRetryInterval = (_currentRetryInterval * 3).clamp(_baseCheckInterval, _maxRetryInterval);
        debugPrint('⚠️ Rate limited, increasing check interval to $_currentRetryInterval seconds');
        
        if (isConnected.value) {
          // Don't mark as disconnected for rate limiting
          connectionError.value = 'Rate limited - checking less frequently';
        }
      } else {
        if (isConnected.value) {
          isConnected.value = false;
          connectionError.value = 'Connection failed';
          debugPrint('❌ Connection check failed: $e');
          _increaseRetryInterval();
        }
      }
    }
  }
  
  /// Increase retry interval with exponential backoff
  void _increaseRetryInterval() {
    if (!_isRateLimited) {
      _currentRetryInterval = (_currentRetryInterval * 1.5).round().clamp(_baseCheckInterval, _maxRetryInterval);
      debugPrint('🔄 Increased retry interval to $_currentRetryInterval seconds');
    }
  }
  
  /// Force a connection check
  Future<bool> checkConnectionNow() async {
    await _checkConnection();
    return isConnected.value;
  }
  
  /// Get connection status description
  String getStatusDescription() {
    if (isConnected.value) {
      return 'Connected to server';
    } else {
      if (_isRateLimited) {
        return 'Rate limited - checking less frequently';
      }
      return connectionError.value.isNotEmpty 
          ? connectionError.value 
          : 'Server disconnected';
    }
  }
}
