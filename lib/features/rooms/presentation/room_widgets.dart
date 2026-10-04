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
