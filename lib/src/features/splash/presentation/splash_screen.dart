import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _authController = Get.find<AuthController>();
  bool _isCheckingAuth = true;
  bool _showContinueButton = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      debugPrint('🔍 Splash: Checking authentication status...');
      
      // Wait a moment for a better splash experience
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Use the AuthController's comprehensive authentication check
      final isAuthenticated = await _authController.checkAuthenticationStatus();
      
      if (isAuthenticated) {
        debugPrint('✅ Splash: Authentication found, waiting for auth controller to complete...');
        
        // Give auth controller time to complete initialization
        int attempts = 0;
        const maxAttempts = 10; // 5 seconds max wait
        
        while (attempts < maxAttempts && 
               (!_authController.isLoggedIn.value || _authController.currentUser.value == null)) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
          debugPrint('⏳ Splash: Waiting for auth controller... attempt $attempts');
        }
        
        // Check final authentication state
        if (_authController.isLoggedIn.value && _authController.currentUser.value != null) {
          debugPrint('✅ Splash: User fully authenticated, routing to dashboard');
          _routeToDashboard();
        } else {
          debugPrint('⚠️ Splash: Auth controller didn\'t complete, showing continue button');
          _showContinueButtonState();
        }
      } else {
        debugPrint('ℹ️ Splash: No authentication found, showing continue button');
        _showContinueButtonState();
      }
    } catch (e) {
      debugPrint('❌ Splash: Error checking authentication: $e');
      _showContinueButtonState();
    }
  }

  void _showContinueButtonState() {
    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
        _showContinueButton = true;
      });
    }
  }

  void _routeToDashboard() {
    final user = _authController.currentUser.value;
    
    if (user?.userType == 'admin') {
      Get.offAllNamed('/admin-dashboard');
    } else if (user?.userType == 'driver') {
      if (user?.isDriverVerified == true) {
        Get.offAllNamed('/driver-dashboard');
      } else {
        Get.offAllNamed('/driver-verification');
      }
    } else {
      Get.offAllNamed('/passenger-dashboard');
    }
  }

  void _onContinuePressed() {
    // Navigate to user selection page
    Get.offAllNamed('/user-selection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background as required
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered "Carwaan" text in white
              const Text(
                'Carwaan',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Show loading indicator or continue button based on auth check status
              if (_isCheckingAuth)
                const Column(
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF0EA5E9),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              else if (_showContinueButton)
                // Sky blue "Continue" button with white text
                ElevatedButton(
                  onPressed: _onContinuePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9), // Sky blue color (consistent with theme)
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
