import 'package:flutter/material.dart';

class AppNotice extends StatelessWidget {
  const AppNotice({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: isError,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? scheme.errorContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isError ? scheme.onErrorContainer : scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
