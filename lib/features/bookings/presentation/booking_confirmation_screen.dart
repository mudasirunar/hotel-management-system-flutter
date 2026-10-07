import 'package:flutter/material.dart';

import '../../../domain/models/customer_booking.dart';
import '../../../domain/models/hotel.dart';
import '../../../domain/models/hotel_room.dart';
import '../../../shared/formatting/app_money_format.dart';

/// Screen displayed immediately after a successful customer booking commit.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.hotel,
    required this.room,
  });

  final CustomerBooking booking;
  final Hotel hotel;
  final HotelRoom room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nights = booking.arrivalDate.differenceInDays(booking.departureDate);
    final effectiveNights = nights > 0 ? nights : 1;
    final totalPKR = (booking.totalAmountMinor / 100).round();

    final cardBorder = isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5);
    final cardBg = isDark ? const Color(0xFF18221C) : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              tooltip: 'Done',
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // 1. Success Animation Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 2. Headline & Subtitle
              Center(
                child: Text(
                  'Reservation Confirmed!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Your room has been saved locally on your device.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // 3. Booking Reference Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Booking Code: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                        ),
                      ),
                      Text(
                        booking.id,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Stay Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${hotel.area}, ${hotel.city}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Room & Guest
                    _buildRow(
                      'Room Category',
                      '${room.type} (Room ${room.number})',
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Guests',
                      '${booking.partySize} ${booking.partySize == 1 ? "Guest" : "Guests"}',
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Duration',
                      '$effectiveNights ${effectiveNights == 1 ? "Night" : "Nights"} (${booking.arrivalDate.format()} – ${booking.departureDate.format()})',
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Primary Guest',
                      booking.travelerName,
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Contact Phone',
                      booking.travelerPhone,
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          AppMoneyFormat.formatPKR(totalPKR),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 5. Actions
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Back to Explore',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
