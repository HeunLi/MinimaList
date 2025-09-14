import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service_clean.dart' as clean_service;
import '../services/device_compatibility_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkDeviceSetup();
  }

  Future<void> _checkDeviceSetup() async {
    if (DeviceCompatibilityService.isProblematicDevice) {
      final hasSeenSetup = await DeviceCompatibilityService.hasSeenDeviceSetup();
      if (!hasSeenSetup && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            DeviceCompatibilityService.showDeviceSetupDialog(context);
          }
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final notificationService = clean_service.NotificationService();
      final dailyEnabled = await notificationService.isDailyReminderEnabled();
      final morningEnabled = await notificationService.isMorningReminderEnabled();

      // Debug: Check what's stored in SharedPreferences
      debugPrint('🔍 Daily reminder status: $dailyEnabled');
      debugPrint('🔍 Morning reminder status: $morningEnabled');
      final status = await notificationService.getStatus();
      debugPrint('🔍 Notification service status: $status');

      setState(() {
        _notificationsEnabled = dailyEnabled || morningEnabled;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _isLoading = true);

    try {
      final notificationService = clean_service.NotificationService();

      if (value) {
        // Enable both morning and evening reminders
        final morningSuccess = await notificationService.enableMorningReminder();
        final dailySuccess = await notificationService.enableDailyReminder();

        debugPrint('🔍 Enable morning reminder result: $morningSuccess');
        debugPrint('🔍 Enable daily reminder result: $dailySuccess');

        final success = morningSuccess && dailySuccess;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                ? '✅ Notifications enabled! You\'ll get reminders at 11 AM and 8 PM daily.'
                : '❌ Failed to enable notifications. Check permissions.'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Disable both reminders
        final morningSuccess = await notificationService.disableMorningReminder();
        final dailySuccess = await notificationService.disableDailyReminder();

        debugPrint('🔍 Disable morning reminder result: $morningSuccess');
        debugPrint('🔍 Disable daily reminder result: $dailySuccess');

        final success = morningSuccess && dailySuccess;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                ? '❌ Notifications disabled'
                : '❌ Failed to disable notifications'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Always update the UI state - the service will handle permissions
      setState(() => _notificationsEnabled = value);

    } catch (e) {
      debugPrint('Error toggling notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unified notification card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: _notificationsEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Reminders',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '11:00 AM & 8:00 PM daily',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: _isLoading ? null : _toggleNotifications,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _notificationsEnabled
                        ? '✅ You\'ll receive reminders at 11 AM and 8 PM daily to check your tasks'
                        : '⏰ Enable to get daily reminders to check your tasks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _notificationsEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Morning: 11:00 AM',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.nights_stay,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Evening: 8:00 PM',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),


          // Status info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'System Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Icon(_notificationsEnabled ? Icons.notifications_active : Icons.notifications_off),
                    title: const Text('Task Reminders'),
                    subtitle: Text(_notificationsEnabled ? '11:00 AM & 8:00 PM - Active' : 'Disabled'),
                    iconColor: _notificationsEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),


          // General help
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Need Help?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('If notifications don\'t work:'),
                  const SizedBox(height: 8),
                  const Text('• Make sure notifications are enabled in device settings'),
                  const Text('• Disable battery optimization for this app'),
                  const Text('• Ensure Do Not Disturb allows notifications'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('Open App Settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}