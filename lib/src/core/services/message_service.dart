import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class MessageService extends GetxService {
  static MessageService get instance => Get.find<MessageService>();
  
  // Track if a snackbar is currently showing to prevent duplicates
  bool _isShowingSnackbar = false;
  Timer? _snackbarTimer;
  
  void showSuccess(String message, {String? title}) {
    if (_isShowingSnackbar) return;
    
    _showSnackbar(
      title ?? 'Success',
      message,
      Colors.green,
      Icons.check_circle,
      3,
    );
  }
  
  void showError(String message, {String? title}) {
    if (_isShowingSnackbar) return;
    
    _showSnackbar(
      title ?? 'Error',
      message,
      Colors.red,
      Icons.error,
      4,
    );
  }
  
  void showInfo(String message, {String? title}) {
    if (_isShowingSnackbar) return;
    
    _showSnackbar(
      title ?? 'Info',
      message,
      Colors.blue,
      Icons.info,
      3,
    );
  }
  
  void showWarning(String message, {String? title}) {
    if (_isShowingSnackbar) return;
    
    _showSnackbar(
      title ?? 'Warning',
      message,
      Colors.orange,
      Icons.warning,
      3,
    );
  }
  
  void _showSnackbar(String title, String message, Color backgroundColor, IconData icon, int durationSeconds) {
    _isShowingSnackbar = true;
    
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: durationSeconds),
      icon: Icon(icon, color: Colors.white),
      onTap: (_) => _resetSnackbarState(),
      isDismissible: true,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
    
    // Reset state after duration
    _snackbarTimer?.cancel();
    _snackbarTimer = Timer(Duration(seconds: durationSeconds), () {
      _resetSnackbarState();
    });
  }
  
  void _resetSnackbarState() {
    _isShowingSnackbar = false;
    _snackbarTimer?.cancel();
  }
  
  // Force close any currently showing snackbar
  void hideCurrentSnackbar() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    _resetSnackbarState();
  }
  
  @override
  void onClose() {
    _snackbarTimer?.cancel();
    super.onClose();
  }
}
