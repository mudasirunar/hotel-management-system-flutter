import 'package:flutter/material.dart';

import '../../../domain/models/room.dart';

class RoomStatusBadge extends StatelessWidget {
  const RoomStatusBadge({
    super.key,
    required this.status,
    this.isReserved = false,
  });

  final RoomStatus status;
  final bool isReserved;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (textColor, bgColor, label) = () {
      if (status == RoomStatus.occupied) {
        return (
          dark ? const Color(0xFFF3CD90) : const Color(0xFF78500E),
          dark ? const Color(0xFF443725) : const Color(0xFFFFF1D9),
          'Occupied',
        );
      }
      if (isReserved) {
        return (
          dark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
          dark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          'Reserved',
        );
      }
      return (
        dark ? const Color(0xFF9FDCBC) : const Color(0xFF246344),
        dark ? const Color(0xFF253E35) : const Color(0xFFE8F5ED),
        'Available',
      );
    }();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
