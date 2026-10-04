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
    final (textColor, bgColor) = switch (status) {
      BookingStatus.reserved => (
        dark ? const Color(0xFFF3CD90) : const Color(0xFF78500E),
        dark ? const Color(0xFF443725) : const Color(0xFFFFF1D9),
      ),
      BookingStatus.checkedIn => (
        dark ? const Color(0xFF9FDCBC) : const Color(0xFF246344),
        dark ? const Color(0xFF253E35) : const Color(0xFFE8F5ED),
      ),
      BookingStatus.checkedOut => (
        dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      ),
      BookingStatus.cancelled => (
        dark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
        dark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        bookingStatusLabel(status),
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String formatStayDates(StayDate arrival, StayDate departure) {
  final nights = arrival.nightsUntil(departure);
  final nightLabel = nights == 1 ? '1 night' : '$nights nights';
  return '$arrival to $departure ($nightLabel)';
}
