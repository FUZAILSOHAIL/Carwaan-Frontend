import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatelessWidget {
  NotificationSettingsScreen({super.key});

  final NotificationService _notificationService = Get.find<NotificationService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _notificationService.showTestNotification(),
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Notifications',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master notification toggle
            _buildSectionCard(
              title: 'Master Settings',
              children: [
                Obx(() => _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Turn all notifications on or off',
                  icon: Icons.notifications,
                  value: _notificationService.notificationsEnabledRx.value,
                  onChanged: (value) {
                    _notificationService.updateNotificationSettings(
                      notificationsEnabled: value,
                    );
                  },
                )),
              ],
            ),

            const SizedBox(height: 16),

            // Notification types
            Obx(() => _buildSectionCard(
              title: 'Notification Types',
              enabled: _notificationService.notificationsEnabledRx.value,
              children: [
                _buildSwitchTile(
                  title: 'Ride Notifications',
                  subtitle: 'Updates about your rides, bookings, and status changes',
                  icon: Icons.directions_car,
                  value: _notificationService.rideNotificationsEnabledRx.value,
                  onChanged: _notificationService.notificationsEnabledRx.value
                      ? (value) {
                          _notificationService.updateNotificationSettings(
                            rideNotificationsEnabled: value,
                          );
                        }
                      : null,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Chat Notifications',
                  subtitle: 'Messages from drivers and passengers',
                  icon: Icons.chat,
                  value: _notificationService.chatNotificationsEnabledRx.value,
                  onChanged: _notificationService.notificationsEnabledRx.value
                      ? (value) {
                          _notificationService.updateNotificationSettings(
                            chatNotificationsEnabled: value,
                          );
                        }
                      : null,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Promotional Notifications',
                  subtitle: 'Special offers, discounts, and promotional content',
                  icon: Icons.local_offer,
                  value: _notificationService.promotionalNotificationsEnabledRx.value,
                  onChanged: _notificationService.notificationsEnabledRx.value
                      ? (value) {
                          _notificationService.updateNotificationSettings(
                            promotionalNotificationsEnabled: value,
                          );
                        }
                      : null,
                ),
              ],
            )),

            const SizedBox(height: 16),

            // Notification behavior
            Obx(() => _buildSectionCard(
              title: 'Notification Behavior',
              enabled: _notificationService.notificationsEnabledRx.value,
              children: [
                _buildSwitchTile(
                  title: 'Sound',
                  subtitle: 'Play notification sound',
                  icon: Icons.volume_up,
                  value: _notificationService.soundEnabledRx.value,
                  onChanged: _notificationService.notificationsEnabledRx.value
                      ? (value) {
                          _notificationService.updateNotificationSettings(
                            soundEnabled: value,
                          );
                        }
                      : null,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Vibration',
                  subtitle: 'Vibrate on notification',
                  icon: Icons.vibration,
                  value: _notificationService.vibrationEnabledRx.value,
                  onChanged: _notificationService.notificationsEnabledRx.value
                      ? (value) {
                          _notificationService.updateNotificationSettings(
                            vibrationEnabled: value,
                          );
                        }
                      : null,
                ),
              ],
            )),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _notificationService.showTestNotification(),
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await _showClearNotificationsDialog(context);
                      if (confirmed == true) {
                        await _notificationService.cancelAllNotifications();
                        Get.snackbar(
                          'Notifications Cleared',
                          'All pending notifications have been cleared',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Information card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'About Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifications help you stay updated with your rides and messages. You can customize which types of notifications you receive and how they behave.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    final isEnabled = onChanged != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled 
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isEnabled 
                  ? const Color(0xFF2E7D32)
                  : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? Colors.grey[600] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2E7D32),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[300],
      indent: 16,
      endIndent: 16,
    );
  }

  Future<bool?> _showClearNotificationsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This will clear all pending notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
