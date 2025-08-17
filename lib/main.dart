import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'src/features/splash/presentation/splash_screen.dart';
import 'src/features/user_selection/presentation/user_selection_screen.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/features/auth/presentation/login_otp_screen.dart';
import 'src/features/auth/presentation/registration_screen.dart';
import 'src/features/auth/presentation/otp_verification_screen.dart';
import 'src/features/driver/presentation/driver_dashboard_screen.dart';
import 'src/features/passenger/presentation/passenger_dashboard_screen.dart';
import 'src/features/admin/presentation/admin_dashboard_screen.dart';
import 'src/features/user_profile/presentation/user_profile_screen.dart';
import 'src/features/passenger/presentation/ride_preview_screen.dart';
import 'src/features/driver/presentation/vehicle_registration_screen.dart';
import 'src/features/driver/presentation/create_ride_screen.dart';
import 'src/features/driver/presentation/driver_verification_screen.dart';
import 'src/features/driver/presentation/driver_reviews_screen.dart';
import 'src/features/driver/presentation/review_passengers_screen.dart';
import 'src/features/passenger/presentation/passenger_reviews_screen.dart';
import 'src/features/passenger/presentation/review_driver_screen.dart';
import 'src/features/vehicle/presentation/vehicle_management_screen.dart';
import 'src/core/controllers/auth_controller.dart';
import 'src/core/controllers/rides_controller.dart';
import 'src/core/controllers/vehicle_controller.dart';
import 'src/core/controllers/admin_controller.dart';
import 'src/core/services/api_service.dart';
import 'src/core/services/message_service.dart';
import 'src/core/services/connection_status_service.dart';
import 'src/core/services/notification_service.dart';
import 'src/core/services/image_zip_service.dart';
import 'src/core/services/admin_service.dart';
import 'src/core/performance/performance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }

  // Initialize services and controllers once at app startup
  _initializeServices();

  runApp(const MyApp());
}

void _initializeServices() {
  // Initialize services in dependency order
  Get.put(PerformanceService(), permanent: true); // Initialize performance service first
  Get.put(MessageService(), permanent: true);
  Get.put(ApiService(), permanent: true);
  Get.put(ConnectionStatusService(), permanent: true);
  Get.put(NotificationService(), permanent: true); // Initialize notification service
  Get.put(ImageZipService(), permanent: true); // Initialize image zip service
  Get.put(AdminService(), permanent: true); // Initialize admin service
  
  // Initialize AuthController first
  Get.put(AuthController(), permanent: true);
  
  // Initialize other controllers without auto-loading data
  // They will be initialized when needed and load data after authentication
  Get.put(RidesController(), permanent: true);
  Get.put(VehicleController(), permanent: true);
  Get.put(AdminController(), permanent: true); // Initialize admin controller
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Carwaan - کارواں',
      enableLog: true, // Enable GetX logs in development
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0EA5E9), // Sky blue
          secondary: Color(0xFF0284C7), // Darker sky blue
          surface: Colors.black,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          brightness: Brightness.dark,
          error: Colors.red,
          onError: Colors.white,
          outline: Color(0xFF424242),
          surfaceContainerHighest: Color(0xFF1A1A1A),
          onSurfaceVariant: Colors.white70,
        ),
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.black,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.black,
          modalBackgroundColor: Colors.black,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.black,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.black,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.black,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Color(0xFF0EA5E9),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9), // Sky blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0EA5E9), // Sky blue
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2), // Sky blue
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.grey[900],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0EA5E9), // Sky blue
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        // Text themes
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white70,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Always start with splash screen
      getPages: [
        GetPage(name: '/user-selection', page: () => const UserSelectionScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/login-otp', page: () => const LoginOTPScreen()),
        GetPage(name: '/register', page: () => const RegistrationScreen()),
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(
          name: '/otp-verification', 
          page: () {
            final args = Get.arguments as Map<String, dynamic>;
            return OTPVerificationScreen(
              email: args['email'],
              isLogin: args['isLogin'] ?? false,
              userType: args['userType'], // Pass userType
            );
          },
        ),
        GetPage(name: '/driver-dashboard', page: () {
          // Role guard for driver dashboard
          final authController = Get.find<AuthController>();
          if (!authController.canAccessDashboard('driver')) {
            authController.redirectWithRoleError('DRIVER');
           
            return const UserSelectionScreen();
          }
          return const DriverDashboardScreen();
        }),
        GetPage(name: '/driver-requests', page: () {
          // Role guard for driver dashboard with requests tab
          final authController = Get.find<AuthController>();
          if (!authController.canAccessDashboard('driver')) {
            authController.redirectWithRoleError('DRIVER');
            return const UserSelectionScreen();
          }
          // Use Get.offNamed to replace current route and go to driver dashboard with requests tab
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offNamed('/driver-dashboard', arguments: {'initialTabIndex': 2});
          });
          return const DriverDashboardScreen();
        }),
        GetPage(name: '/passenger-dashboard', page: () {
          // Role guard for passenger dashboard
          final authController = Get.find<AuthController>();
          if (!authController.canAccessDashboard('passenger')) {
            authController.redirectWithRoleError('PASSENGER');
            return const UserSelectionScreen();
          }
          return const PassengerDashboardScreen();
        }),
        GetPage(name: '/admin-dashboard', page: () {
          // Role guard for admin dashboard
          final authController = Get.find<AuthController>();
          if (!authController.canAccessDashboard('admin')) {
            authController.redirectWithRoleError('ADMIN');
            return const UserSelectionScreen();
          }
          return const AdminDashboardScreen();
        }),
        GetPage(
          name: '/profile', 
          page: () {
            return const UserProfileScreen();
          },
        ),
        // Driver screens
        GetPage(
          name: '/ride-preview',
          page: () {
            final args = Get.arguments as Map<String, dynamic>;
            return RidePreviewScreen(rideId: args['rideId']);
          },
        ),
        GetPage(name: '/vehicle-registration', page: () => const VehicleRegistrationScreen()),
        GetPage(name: '/vehicle-management', page: () => const VehicleManagementScreen()),
        GetPage(name: '/driver-verification', page: () => const DriverVerificationScreen()),
        GetPage(name: '/create-ride', page: () => const CreateRideScreen()),
        GetPage(name: '/driver-reviews', page: () => const DriverReviewsScreen()),
        GetPage(
          name: '/review-passengers',
          page: () => const ReviewPassengersScreen(),
        ),
        GetPage(name: '/passenger-reviews', page: () => const PassengerReviewsScreen()),
        GetPage(
          name: '/review-driver',
          page: () => const ReviewDriverScreen(),
        ),
      ],
    );
  }
}
