import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';
import '../screens/notification_settings_screen.dart';
import '../models/task.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.task_alt,
                  size: 40,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MinimaList',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Settings & Options',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Theme Section
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ExpansionTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : themeProvider.isLightMode
                                ? Icons.light_mode
                                : Icons.brightness_auto,
                      ),
                      title: const Text('Theme'),
                      subtitle: Text(
                        themeProvider.isDarkMode
                            ? 'Dark'
                            : themeProvider.isLightMode
                                ? 'Light'
                                : 'System',
                      ),
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.brightness_auto,
                            color: themeProvider.isSystemMode
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: const Text('System'),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.system);
                            Navigator.of(context).pop();
                          },
                          trailing: themeProvider.isSystemMode
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.light_mode,
                            color: themeProvider.isLightMode
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: const Text('Light'),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.light);
                            Navigator.of(context).pop();
                          },
                          trailing: themeProvider.isLightMode
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.dark_mode,
                            color: themeProvider.isDarkMode
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: const Text('Dark'),
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.dark);
                            Navigator.of(context).pop();
                          },
                          trailing: themeProvider.isDarkMode
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      ],
                    );
                  },
                ),

                // Filter Section
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    if (taskProvider.allTasks.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ExpansionTile(
                      leading: const Icon(Icons.filter_list),
                      title: const Text('Filter Tasks'),
                      subtitle: Text(
                        taskProvider.filterPriority != null
                            ? '${taskProvider.filterPriority!.displayName} Priority'
                            : 'All Tasks',
                      ),
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.all_inbox,
                            color: taskProvider.filterPriority == null
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: const Text('All Tasks'),
                          onTap: () {
                            taskProvider.clearFilters();
                            Navigator.of(context).pop();
                          },
                          trailing: taskProvider.filterPriority == null
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.priority_high,
                            color: taskProvider.filterPriority == TaskPriority.high
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: const Text('High Priority'),
                          onTap: () {
                            taskProvider.setPriorityFilter(TaskPriority.high);
                            Navigator.of(context).pop();
                          },
                          trailing: taskProvider.filterPriority == TaskPriority.high
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.remove,
                            color: taskProvider.filterPriority == TaskPriority.medium
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: const Text('Medium Priority'),
                          onTap: () {
                            taskProvider.setPriorityFilter(TaskPriority.medium);
                            Navigator.of(context).pop();
                          },
                          trailing: taskProvider.filterPriority == TaskPriority.medium
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.low_priority,
                            color: taskProvider.filterPriority == TaskPriority.low
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: const Text('Low Priority'),
                          onTap: () {
                            taskProvider.setPriorityFilter(TaskPriority.low);
                            Navigator.of(context).pop();
                          },
                          trailing: taskProvider.filterPriority == TaskPriority.low
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      ],
                    );
                  },
                ),

                const Divider(),

                // Notification Settings
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notification Settings'),
                  subtitle: const Text('Manage your task reminders'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Clear Filters (if any active)
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    if (taskProvider.filterPriority == null &&
                        taskProvider.filterCategory == null) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      leading: Icon(
                        Icons.clear_all,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Clear All Filters',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: const Text('Remove all active filters'),
                      onTap: () {
                        taskProvider.clearFilters();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // App version info
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'MinimaList v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}