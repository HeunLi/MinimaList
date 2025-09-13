import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = false;
  bool _dailySummaryEnabled = false;
  bool _isLoading = true;

  // Keys for SharedPreferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _dailySummaryEnabledKey = 'daily_summary_enabled';

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final systemPermissionGranted =
          await NotificationService.areNotificationsEnabled();

      // Check both system permission AND user preference
      final userEnabledNotifications =
          prefs.getBool(_notificationsEnabledKey) ?? false;
      final userEnabledDailySummary =
          prefs.getBool(_dailySummaryEnabledKey) ?? false;

      setState(() {
        // Notifications are truly enabled only if BOTH system permission is granted AND user preference is true
        _notificationsEnabled =
            systemPermissionGranted && userEnabledNotifications;
        _dailySummaryEnabled = _notificationsEnabled && userEnabledDailySummary;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() {
        _notificationsEnabled = false;
        _dailySummaryEnabled = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
      await prefs.setBool(_dailySummaryEnabledKey, _dailySummaryEnabled);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _isLoading = true);

    try {
      if (value) {
        // User wants to ENABLE notifications
        final systemPermissionGranted =
            await NotificationService.requestPermission();

        if (systemPermissionGranted) {
          setState(() => _notificationsEnabled = true);
          await _saveNotificationSettings();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Notifications enabled! You\'ll receive task reminders.'),
                duration: Duration(seconds: 3),
              ),
            );

            await NotificationService.showInstantNotification(
              title: 'Notifications Enabled',
              body: 'You\'ll receive reminders for your tasks.',
            );
          }
        } else {
          setState(() => _notificationsEnabled = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable notifications in Settings.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // User wants to DISABLE notifications
        setState(() {
          _notificationsEnabled = false;
          _dailySummaryEnabled = false; // Also disable daily summary
        });

        await _saveNotificationSettings();
        await NotificationService.cancelAllNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications disabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling notifications: $e');
      // Revert state on error
      setState(() => _notificationsEnabled = !value);

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

  Future<void> _toggleDailySummary(bool value) async {
    if (!_notificationsEnabled)
      return; // Can't enable if main notifications are off

    setState(() => _dailySummaryEnabled = value);
    await _saveNotificationSettings();

    try {
      if (value) {
        await NotificationService.scheduleDailySummary();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily summary enabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await NotificationService.cancelDailySummary();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily summary disabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling daily summary: $e');
      // Revert on error
      setState(() => _dailySummaryEnabled = !value);
      await _saveNotificationSettings();
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
          // Main notification toggle
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Task Reminders',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: _isLoading ? null : _toggleNotifications,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _notificationsEnabled
                        ? 'Receive notifications for task due dates'
                        : 'Enable notifications to get reminders',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (!_notificationsEnabled) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed:
                          _isLoading ? null : () => _toggleNotifications(true),
                      icon: const Icon(Icons.notifications),
                      label: const Text('Enable Notifications'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notification types (only show if enabled)
          if (_notificationsEnabled) ...[
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Due date reminders (always enabled when notifications are on)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Due Date Reminders'),
                subtitle: const Text('Notified 1 day before and on due date'),
                trailing: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Overdue notifications (always enabled when notifications are on)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Overdue Notifications'),
                subtitle: const Text('Notified when tasks become overdue'),
                trailing: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Daily summary toggle
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                title: const Text('Daily Summary'),
                subtitle: const Text('Morning overview at 8 AM'),
                trailing: Switch(
                  value: _dailySummaryEnabled,
                  onChanged: _toggleDailySummary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test notification button
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send a test notification',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () async {
                        await NotificationService.showInstantNotification(
                          title: 'Test Notification',
                          body: 'This is how your task reminders will look!',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('Send Test Notification'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug info
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: const Text('Scheduled Notifications'),
                subtitle: const Text('View pending reminders'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final pending =
                      await NotificationService.getPendingNotifications();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Scheduled Notifications'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${pending.length} notifications scheduled'),
                              const SizedBox(height: 8),
                              Text(
                                  'Notifications enabled: $_notificationsEnabled'),
                              Text(
                                  'Daily summary enabled: $_dailySummaryEnabled'),
                              if (pending.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ...pending.take(10).map((notif) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.title ?? 'No title',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            notif.body ?? 'No body',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    )),
                                if (pending.length > 10)
                                  Text('... and ${pending.length - 10} more'),
                              ],
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // Settings help
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Troubleshooting',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'If notifications aren\'t working:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Enable app notifications in Settings'),
                    const Text('• Disable battery optimization for this app'),
                    const Text('• Allow exact alarms (Android 12+)'),
                    const Text('• For Huawei: Enable Auto-launch'),
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
        ],
      ),
    );
  }
}
