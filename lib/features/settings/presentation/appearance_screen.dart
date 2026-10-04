import 'package:flutter/material.dart';

import '../../../application/theme_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Appearance')),
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
                  'Make it feel right',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Follow your device appearance or choose a theme. Your preference is saved on this device.',
                ),
                const SizedBox(height: 24),
                for (final option in <(ThemeMode, String, String, IconData)>[
                  (
                    ThemeMode.system,
                    'System',
                    'Automatically follows your device theme',
                    Icons.brightness_auto_outlined,
                  ),
                  (
                    ThemeMode.light,
                    'Light',
                    'A clear, light workspace',
                    Icons.light_mode_outlined,
                  ),
                  (
                    ThemeMode.dark,
                    'Dark',
                    'A softer workspace for low light',
                    Icons.dark_mode_outlined,
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      selected: controller.mode == option.$1,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: controller.mode == option.$1
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          leading: Icon(option.$4),
                          title: Text(option.$2),
                          subtitle: Text(option.$3),
                          trailing: controller.mode == option.$1
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
