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
        ? (dark ? const Color(0xFFF3CD90) : const Color(0xFF78500E))
        : (dark ? const Color(0xFF9FDCBC) : const Color(0xFF246344));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: occupied
            ? (dark ? const Color(0xFF443725) : const Color(0xFFFFF1D9))
            : (dark ? const Color(0xFF253E35) : const Color(0xFFE8F5ED)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        occupied ? 'Occupied' : 'Available',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}
