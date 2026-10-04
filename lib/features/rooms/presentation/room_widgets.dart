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
    final (textColor, bgColor, borderColor, label) = () {
      if (status == RoomStatus.occupied) {
        return (
          dark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          dark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          dark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
          'Occupied',
        );
      }
      if (isReserved) {
        return (
          dark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
          dark ? const Color(0xFF452205) : const Color(0xFFFEF3C7),
          dark ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
          'Reserved',
        );
      }
      return (
        dark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
        dark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
        dark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
        'Available',
      );
    }();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
