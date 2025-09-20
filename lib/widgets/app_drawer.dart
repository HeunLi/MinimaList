import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                    ),
                    Text(
                      'Settings & Options',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.7),
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
              ],
            ),
          ),

          // App version info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'MinimaList v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'by Jebi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
