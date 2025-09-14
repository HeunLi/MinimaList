import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import '../services/device_compatibility_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _dailyReminderEnabled = false;
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
      final enabled = await NotificationService.isDailyReminderEnabled();
      setState(() => _dailyReminderEnabled = enabled);
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDailyReminder(bool value) async {
    setState(() => _isLoading = true);

    try {
      bool success;
      if (value) {
        success = await NotificationService.enableDailyReminder();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Daily reminder enabled! You\'ll get notified at 8 PM every day.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        success = await NotificationService.disableDailyReminder();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Daily reminder disabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (success) {
        setState(() => _dailyReminderEnabled = value);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value
                ? 'Failed to enable daily reminder. Please check notification permissions.'
                : 'Failed to disable daily reminder.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling daily reminder: $e');
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
          // Main setting card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _dailyReminderEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: _dailyReminderEnabled
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
                              'Daily Task Reminder',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '8:00 PM every day',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _dailyReminderEnabled,
                        onChanged: _isLoading ? null : _toggleDailyReminder,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _dailyReminderEnabled
                        ? '✅ You\'ll receive a daily reminder at 8 PM to check your tasks'
                        : '⏰ Enable to get daily reminders to check your tasks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _dailyReminderEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Test notification button
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.science,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Test Notification',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a test notification to see how it looks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _sendTestNotification,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test'),
                  ),
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
                    leading: const Icon(Icons.access_time),
                    title: const Text('Reminder Time'),
                    subtitle: const Text('8:00 PM daily'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: Icon(_dailyReminderEnabled ? Icons.check_circle : Icons.cancel),
                    title: const Text('Status'),
                    subtitle: Text(_dailyReminderEnabled ? 'Active' : 'Disabled'),
                    iconColor: _dailyReminderEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Device-specific help
          if (DeviceCompatibilityService.isProblematicDevice)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Device Setup Required',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your ${DeviceCompatibilityService.deviceType.toUpperCase()} device needs special settings for notifications to work reliably.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        DeviceCompatibilityService.showDeviceSetupDialog(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Text('Show Setup Guide'),
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

  Future<void> _sendTestNotification() async {
    setState(() => _isLoading = true);

    try {
      final success = await NotificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '🧪 Test notification sent! Check your notification panel.'
                : '❌ Failed to send test notification. Check permissions.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
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
}