import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
      _dailySummaryEnabled =
          enabled; // For now, assume daily summary follows main setting
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    final granted = await NotificationService.requestPermission();

    if (granted) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Notifications enabled! You\'ll now receive reminders for your tasks.'),
            duration: Duration(seconds: 3),
          ),
        );

        // Show test notification
        await NotificationService.showInstantNotification(
          title: 'MinimaList Notifications',
          body: 'You\'re all set! This is what task reminders will look like.',
        );
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Notification permission denied. You can enable it in Settings.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    await _checkNotificationStatus();
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
                        onChanged: (value) async {
                          if (value) {
                            await _requestNotificationPermission();
                          } else {
                            await NotificationService.cancelAllNotifications();
                            await _checkNotificationStatus();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _notificationsEnabled
                        ? 'Receive notifications for task due dates and reminders'
                        : 'Enable notifications to get reminders for your tasks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (!_notificationsEnabled) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _requestNotificationPermission,
                      icon: const Icon(Icons.notifications),
                      label: const Text('Enable Notifications'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notification types (only show if notifications are enabled)
          if (_notificationsEnabled) ...[
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Due date reminders
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Due Date Reminders'),
                subtitle:
                    const Text('Get notified 1 day before and on the due date'),
                trailing: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Overdue notifications
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Overdue Notifications'),
                subtitle: const Text('Get notified when tasks become overdue'),
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
                subtitle:
                    const Text('Morning overview of today\'s tasks (8 AM)'),
                trailing: Switch(
                  value: _dailySummaryEnabled,
                  onChanged: (value) async {
                    setState(() => _dailySummaryEnabled = value);
                    if (value) {
                      await NotificationService.scheduleDailySummary();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily summary enabled for 8 AM'),
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
                  },
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
                      'Send a test notification to make sure everything is working',
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

            const SizedBox(height: 24),

            // Debug info
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: ExpansionTile(
                title: Text(
                  'Debug Info',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final pending = await NotificationService
                                .getPendingNotifications();
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Pending Notifications'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${pending.length} scheduled notifications'),
                                      const SizedBox(height: 8),
                                      if (pending.isNotEmpty) ...[
                                        const Text('Scheduled notifications:'),
                                        const SizedBox(height: 8),
                                        ...pending.take(5).map((notif) => Text(
                                              '• ${notif.title} (ID: ${notif.id})',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            )),
                                        if (pending.length > 5)
                                          Text(
                                              '... and ${pending.length - 5} more'),
                                      ],
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: const Text('Show Pending Notifications'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await NotificationService.cancelAllNotifications();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('All notifications cancelled')),
                              );
                            }
                          },
                          child: const Text('Cancel All Notifications'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
