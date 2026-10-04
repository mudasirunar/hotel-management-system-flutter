import 'package:flutter/material.dart';

/// A polished, consistent card widget for displaying empty states,
/// search results not found, and filter mismatches.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
    this.customActions,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final List<Widget>? customActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            if (customActions != null && customActions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: customActions!,
              ),
            ] else if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (actionIcon != null) ...[
                          Icon(actionIcon, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(actionLabel!),
                      ],
                    ),
                  ),
                  if (onSecondaryAction != null && secondaryActionLabel != null)
                    FilledButton.tonal(
                      onPressed: onSecondaryAction,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (secondaryActionIcon != null) ...[
                            Icon(secondaryActionIcon, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(secondaryActionLabel!),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
