import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService extends GetxService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification settings observables
  final RxBool _notificationsEnabled = true.obs;
  final RxBool _rideNotificationsEnabled = true.obs;
  final RxBool _chatNotificationsEnabled = true.obs;
  final RxBool _promotionalNotificationsEnabled = false.obs;
  final RxBool _soundEnabled = true.obs;
  final RxBool _vibrationEnabled = true.obs;

  // Getters for settings
  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get rideNotificationsEnabled => _rideNotificationsEnabled.value;
  bool get chatNotificationsEnabled => _chatNotificationsEnabled.value;
  bool get promotionalNotificationsEnabled => _promotionalNotificationsEnabled.value;
  bool get soundEnabled => _soundEnabled.value;
  bool get vibrationEnabled => _vibrationEnabled.value;

  // Reactive getters
  RxBool get notificationsEnabledRx => _notificationsEnabled;
  RxBool get rideNotificationsEnabledRx => _rideNotificationsEnabled;
  RxBool get chatNotificationsEnabledRx => _chatNotificationsEnabled;
  RxBool get promotionalNotificationsEnabledRx => _promotionalNotificationsEnabled;
  RxBool get soundEnabledRx => _soundEnabled;
  RxBool get vibrationEnabledRx => _vibrationEnabled;

  // Notification channels
  static const String _rideChannelId = 'ride_notifications';
  static const String _chatChannelId = 'chat_notifications';
  static const String _generalChannelId = 'general_notifications';
  static const String _promotionalChannelId = 'promotional_notifications';

  @override
  Future<void> onInit() async {
    super.onInit();
    // Initialize timezone data
    tz.initializeTimeZones();
    await _initializeNotifications();
    await _loadSettings();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      // Request permissions
      await _requestPermissions();

      debugPrint('✅ Notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize notifications: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Ride notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _rideChannelId,
          'Ride Notifications',
          description: 'Notifications about ride updates, bookings, and status changes',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Chat notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _chatChannelId,
          'Chat Notifications',
          description: 'Messages from drivers and passengers',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // General notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          'General Notifications',
          description: 'General app notifications and updates',
          importance: Importance.defaultImportance,
        ),
      );

      // Promotional notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _promotionalChannelId,
          'Promotional Notifications',
          description: 'Offers, discounts, and promotional content',
          importance: Importance.low,
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final iosPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped with payload: $payload');
    
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    switch (type) {
      case 'ride_booked':
      case 'ride_confirmed':
      case 'ride_cancelled':
      case 'ride_completed':
        if (id != null) {
          Get.toNamed('/ride-detail', arguments: {'rideId': id});
        }
        break;
      case 'chat_message':
        if (id != null) {
          Get.toNamed('/chat', arguments: {'chatId': id});
        }
        break;
      case 'ride_request':
        Get.toNamed('/dashboard', arguments: {'initialTabIndex': 1});
        break;
      default:
        Get.toNamed('/dashboard');
        break;
    }
  }

  // Notification types and methods
  Future<void> showRideNotification({
    required String title,
    required String body,
    String? rideId,
    String? type,
  }) async {
    if (!_notificationsEnabled.value || !_rideNotificationsEnabled.value) return;

    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
    final payload = jsonEncode({
      'type': type ?? 'ride_update',
      'id': rideId,
    });

    await _showNotification(
      id: id,
      title: title,
      body: body,
      channelId: _rideChannelId,
      payload: payload,
    );
  }

  Future<void> showChatNotification({
    required String title,
    required String body,
    String? chatId,
    String? senderId,
  }) async {
    if (!_notificationsEnabled.value || !_chatNotificationsEnabled.value) return;

    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
    final payload = jsonEncode({
      'type': 'chat_message',
      'id': chatId,
      'senderId': senderId,
    });

    await _showNotification(
      id: id,
      title: title,
      body: body,
      channelId: _chatChannelId,
      payload: payload,
    );
  }

  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled.value) return;

    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _showNotification(
      id: id,
      title: title,
      body: body,
      channelId: _generalChannelId,
      payload: payload,
    );
  }

  Future<void> showPromotionalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled.value || !_promotionalNotificationsEnabled.value) return;

    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _showNotification(
      id: id,
      title: title,
      body: body,
      channelId: _promotionalChannelId,
      payload: payload,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        importance: _getImportance(channelId),
        priority: _getPriority(channelId),
        enableVibration: _vibrationEnabled.value,
        playSound: _soundEnabled.value,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case _rideChannelId:
        return 'Ride Notifications';
      case _chatChannelId:
        return 'Chat Notifications';
      case _generalChannelId:
        return 'General Notifications';
      case _promotionalChannelId:
        return 'Promotional Notifications';
      default:
        return 'Carwaan Notifications';
    }
  }

  Importance _getImportance(String channelId) {
    switch (channelId) {
      case _rideChannelId:
      case _chatChannelId:
        return Importance.high;
      case _generalChannelId:
        return Importance.defaultImportance;
      case _promotionalChannelId:
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _getPriority(String channelId) {
    switch (channelId) {
      case _rideChannelId:
      case _chatChannelId:
        return Priority.high;
      case _generalChannelId:
        return Priority.defaultPriority;
      case _promotionalChannelId:
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  // Scheduled notifications
  Future<void> scheduleRideReminder({
    required String rideId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_notificationsEnabled.value || !_rideNotificationsEnabled.value) return;

    final id = rideId.hashCode;
    final payload = jsonEncode({
      'type': 'ride_reminder',
      'id': rideId,
    });

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _rideChannelId,
            'Ride Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('✅ Scheduled ride reminder for $scheduledTime');
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  // Settings management
  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? rideNotificationsEnabled,
    bool? chatNotificationsEnabled,
    bool? promotionalNotificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) async {
    if (notificationsEnabled != null) {
      _notificationsEnabled.value = notificationsEnabled;
    }
    if (rideNotificationsEnabled != null) {
      _rideNotificationsEnabled.value = rideNotificationsEnabled;
    }
    if (chatNotificationsEnabled != null) {
      _chatNotificationsEnabled.value = chatNotificationsEnabled;
    }
    if (promotionalNotificationsEnabled != null) {
      _promotionalNotificationsEnabled.value = promotionalNotificationsEnabled;
    }
    if (soundEnabled != null) {
      _soundEnabled.value = soundEnabled;
    }
    if (vibrationEnabled != null) {
      _vibrationEnabled.value = vibrationEnabled;
    }

    await _saveSettings();
    debugPrint('✅ Notification settings updated');
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _notificationsEnabled.value = prefs.getBool('notifications_enabled') ?? true;
      _rideNotificationsEnabled.value = prefs.getBool('ride_notifications_enabled') ?? true;
      _chatNotificationsEnabled.value = prefs.getBool('chat_notifications_enabled') ?? true;
      _promotionalNotificationsEnabled.value = prefs.getBool('promotional_notifications_enabled') ?? false;
      _soundEnabled.value = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled.value = prefs.getBool('vibration_enabled') ?? true;

      debugPrint('✅ Notification settings loaded');
    } catch (e) {
      debugPrint('❌ Failed to load notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', _notificationsEnabled.value);
      await prefs.setBool('ride_notifications_enabled', _rideNotificationsEnabled.value);
      await prefs.setBool('chat_notifications_enabled', _chatNotificationsEnabled.value);
      await prefs.setBool('promotional_notifications_enabled', _promotionalNotificationsEnabled.value);
      await prefs.setBool('sound_enabled', _soundEnabled.value);
      await prefs.setBool('vibration_enabled', _vibrationEnabled.value);

      debugPrint('✅ Notification settings saved');
    } catch (e) {
      debugPrint('❌ Failed to save notification settings: $e');
    }
  }

  // Utility methods
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('✅ All notifications cancelled');
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('✅ Notification $id cancelled');
  }

  Future<void> cancelRideNotifications(String rideId) async {
    final id = rideId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('✅ Ride notifications for $rideId cancelled');
  }

  // Test notification
  Future<void> showTestNotification() async {
    await showGeneralNotification(
      title: '🚗 Carwaan Test',
      body: 'Notifications are working properly!',
    );
  }
}
