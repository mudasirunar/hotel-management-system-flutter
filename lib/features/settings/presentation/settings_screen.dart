import 'package:flutter/material.dart';

import '../../../application/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how the application looks on this device.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final option in <(ThemeMode, String, String, IconData)>[
                    (
                      ThemeMode.system,
                      'System default',
                      'Automatically matches your system theme',
                      Icons.brightness_auto_outlined,
                    ),
                    (
                      ThemeMode.light,
                      'Light theme',
                      'Bright surfaces with green accents',
                      Icons.light_mode_outlined,
                    ),
                    (
                      ThemeMode.dark,
                      'Dark theme',
                      'Deep forest tones for low light',
                      Icons.dark_mode_outlined,
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        selected: controller.mode == option.$1,
                        child: Material(
                          color: scheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: controller.mode == option.$1
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              width: controller.mode == option.$1 ? 1.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: Icon(
                              option.$4,
                              color: controller.mode == option.$1
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            title: Text(
                              option.$2,
                              style: TextStyle(
                                fontWeight: controller.mode == option.$1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(option.$3),
                            trailing: controller.mode == option.$1
                                ? Icon(
                                    Icons.check_circle,
                                    color: scheme.primary,
                                  )
                                : null,
                            onTap: controller.saving || controller.loading
                                ? null
                                : () async {
                                    await controller.select(option.$1);
                                  },
                          ),
                        ),
                      ),
                    ),
                  if (controller.saving) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      semanticsLabel: 'Saving appearance',
                    ),
                  ],
                  if (controller.error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        controller.error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hotel Management System',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0 • Offline-first hotel manager',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Application ID: com.mudasir.hotelmanagementsystem',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
