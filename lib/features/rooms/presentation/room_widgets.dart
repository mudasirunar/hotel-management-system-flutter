import 'package:flutter/material.dart';

import '../../../domain/models/room.dart';

class RoomStatusBadge extends StatelessWidget {
  const RoomStatusBadge({super.key, required this.status});

  final RoomStatus status;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final occupied = status == RoomStatus.occupied;
    final color = occupied
        ? (dark ? const Color(0xFFF4CA88) : const Color(0xFF84510C))
        : (dark ? const Color(0xFFA2DABC) : const Color(0xFF286147));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: occupied
            ? (dark ? const Color(0xFF48361D) : const Color(0xFFFFF0D9))
            : (dark ? const Color(0xFF213E30) : const Color(0xFFE8F3EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        occupied ? 'Occupied' : 'Available',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class RoomNotice extends StatelessWidget {
  const RoomNotice({super.key, required this.message, this.isError = false});

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
