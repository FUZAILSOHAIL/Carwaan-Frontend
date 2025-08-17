import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/services/connection_status_service.dart';
import '../../../core/widgets/connection_status_widget.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final bool isLogin; // true for login OTP, false for registration OTP
  final String? userType; // User type selection for navigation

  const OTPVerificationScreen({
    super.key,
    required this.email,
    this.isLogin = false,
    this.userType,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;
  String _errorMessage = '';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startResendTimer();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _onOTPChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
        _verifyOTP();
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  void _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String otp = _controllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete OTP';
        _isLoading = false;
      });
      return;
    }

    try {
      bool success;
      if (widget.isLogin) {
        success = await _authController.verifyLoginOTP(widget.email, otp, userType: widget.userType);
      } else {
        success = await _authController.verifyRegistrationOTP(widget.email, otp, userType: widget.userType);
      }

      if (success && mounted) {
        _showSuccessSnackbar(
          widget.isLogin ? 'Login successful!' : 'Email verified successfully!'
        );
        // AuthController handles navigation automatically based on user type
      } else {
        // Use the detailed error message from AuthController
        final errorMessage = _authController.errorMessage.value.isNotEmpty 
            ? _authController.errorMessage.value 
            : (widget.isLogin 
                ? 'Invalid OTP. Please try again.' 
                : 'OTP verification failed. Please try again.');
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      // Use AuthController's error message if available, otherwise use exception message
      final errorMessage = _authController.errorMessage.value.isNotEmpty 
          ? _authController.errorMessage.value 
          : e.toString();
      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resendOTP() async {
    if (_resendTimer > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      bool success;
      if (widget.isLogin) {
        success = await _authController.loginWithOTP(widget.email);
      } else {
        success = await _authController.sendOTP(widget.email);
      }

      if (success && mounted) {
        Get.snackbar(
          'OTP Sent',
          'A new OTP has been sent to your email',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        _startResendTimer();
        
        // Clear OTP fields
        for (var controller in _controllers) {
          controller.clear();
        }
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      } else {
        // Use AuthController's error message if available
        final errorMessage = _authController.errorMessage.value.isNotEmpty 
            ? _authController.errorMessage.value 
            : 'Failed to resend OTP. Please try again.';
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      // Use AuthController's error message if available, otherwise use exception message
      final errorMessage = _authController.errorMessage.value.isNotEmpty 
          ? _authController.errorMessage.value 
          : e.toString();
      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background consistent with theme
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0), // Reduced from 24.0
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16), // Reduced from 20
                  
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                    
                    const SizedBox(height: 32), // Reduced from 40
                    
                    // Title and tagline
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Show user type if available
                    if (widget.userType != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${widget.isLogin ? "Login" : "Registration"} as ${widget.userType?.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    const Text(
                      'Har safar ka saathi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const SizedBox(height: 20), // Reduced from 24
                    
                    // Instruction text
                    Text(
                      'We\'ve sent a 6-digit verification code to',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24), // Reduced from 32
                    
                    // Connection status
                    const ConnectionStatusWidget(showOnlyWhenDisconnected: false),
                    
                    const SizedBox(height: 24), // Reduced from 32
                    
                    // OTP Input Container
                    Container(
                      padding: const EdgeInsets.all(20), // Reduced from 24
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
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Enter Verification Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // OTP Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return Container(
                                width: 38,
                                height: 60,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white54),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white54),
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) => _onOTPChanged(value, index),
                                ),
                              );
                            }),
                          ),
                          
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Verify button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Obx(() {
                              final connectionService = ConnectionStatusService.instance;
                              final isConnected = connectionService.isConnected.value;
                              
                              return ElevatedButton(
                                onPressed: isConnected && !_isLoading ? _verifyOTP : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Verify Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              );
                            }),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Resend OTP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Didn\'t receive the code? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              if (_resendTimer > 0)
                                Text(
                                  'Resend in ${_resendTimer}s',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _isResending ? null : _resendOTP,
                                  child: Text(
                                    _isResending ? 'Sending...' : 'Resend',
                                    style: const TextStyle(
                                      color: Color(0xFF0EA5E9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24), // Reduced from 32
                    
                    // Help text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: const Color(0xFF0EA5E9), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Verification Help',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your email inbox and spam folder. If you still don\'t receive the code, you can request a new one after the timer expires.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24), // Reduced from 32
                  ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
