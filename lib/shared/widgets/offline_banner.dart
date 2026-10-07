import 'package:flutter/material.dart';

/// Compact, non-intrusive offline notification banner.
///
/// Informs travelers that while online photo downloads may be unavailable,
/// local hotel discovery, room selection, and bookings remain fully functional.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.onRetry,
    this.message =
        'Offline mode. Photos may not load, but searching and bookings work locally.',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF1E2822)
        : const Color(0xFFE8F2EC);
    final borderColor = isDark
        ? const Color(0xFF2E3E34)
        : const Color(0xFFC7DECF);
    final textColor = isDark ? Colors.white70 : const Color(0xFF244230);
    final iconColor = isDark ? const Color(0xFF5CD29D) : const Color(0xFF0F764F);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('Check'),
            ),
          ],
        ],
      ),
    );
  }
}
