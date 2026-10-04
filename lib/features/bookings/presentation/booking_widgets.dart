import 'package:flutter/material.dart';

import '../../../domain/models/booking.dart';
import '../../../domain/models/stay_date.dart';

String bookingStatusLabel(BookingStatus status) => switch (status) {
  BookingStatus.reserved => 'Reserved',
  BookingStatus.checkedIn => 'Checked In',
  BookingStatus.checkedOut => 'Checked Out',
  BookingStatus.cancelled => 'Cancelled',
};

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (textColor, bgColor, borderColor) = switch (status) {
      BookingStatus.reserved => (
        dark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
        dark ? const Color(0xFF452205) : const Color(0xFFFEF3C7),
        dark ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
      ),
      BookingStatus.checkedIn => (
        dark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
        dark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        dark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
      ),
      BookingStatus.checkedOut => (
        dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      ),
      BookingStatus.cancelled => (
        dark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
        dark ? const Color(0xFF3B181B) : const Color(0xFFFEE2E2),
        dark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        bookingStatusLabel(status),
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String formatStayDates(StayDate arrival, StayDate departure) {
  final nights = arrival.nightsUntil(departure);
  final nightLabel = nights == 1 ? '1 night' : '$nights nights';
  return '$arrival to $departure ($nightLabel)';
}
