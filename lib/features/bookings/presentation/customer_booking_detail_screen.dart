import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../domain/models/customer_booking.dart';
import '../../../shared/formatting/app_money_format.dart';

/// Screen displaying the complete details of a single reservation,
/// with support for eligible cancellation and status feedback.
class CustomerBookingDetailScreen extends StatefulWidget {
  const CustomerBookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.customerController,
  });

  final String bookingId;
  final CustomerController customerController;

  @override
  State<CustomerBookingDetailScreen> createState() => _CustomerBookingDetailScreenState();
}

class _CustomerBookingDetailScreenState extends State<CustomerBookingDetailScreen> {
  bool _isCancelling = false;

  Future<void> _promptCancel(CustomerBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: Text(
          'Are you sure you want to cancel your stay at ${booking.hotelName} for ${booking.arrivalDate.format()}? This will release the room for other guests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Reservation'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel Stay'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await widget.customerController.cancelBooking(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation cancelled successfully.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel reservation: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.customerController,
      builder: (context, _) {
        final booking = widget.customerController.state.bookings
            .cast<CustomerBooking?>()
            .firstWhere((b) => b?.id == widget.bookingId, orElse: () => null);

        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reservation Details')),
            body: const Center(
              child: Text('Reservation not found.'),
            ),
          );
        }

        final nights = booking.arrivalDate.differenceInDays(booking.departureDate);
        final effectiveNights = nights > 0 ? nights : 1;
        final totalPKR = (booking.totalAmountMinor / 100).round();
        final nightlyRatePKR = (booking.nightlyRateMinor / 100).round();

        final cardBorder = isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5);
        final cardBg = isDark ? const Color(0xFF18221C) : Colors.white;

        return Scaffold(
          appBar: AppBar(
            title: Text('Booking #${booking.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: booking.isCancelled
                        ? const Color(0xFFD32F2F).withValues(alpha: 0.1)
                        : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: booking.isCancelled
                          ? const Color(0xFFD32F2F).withValues(alpha: 0.4)
                          : const Color(0xFF2E7D32).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        booking.isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
                        color: booking.isCancelled ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.isCancelled ? 'Reservation Cancelled' : 'Confirmed Booking',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: booking.isCancelled
                                    ? const Color(0xFFD32F2F)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              booking.isCancelled
                                  ? 'This room was released and is no longer reserved.'
                                  : 'Saved to your local on-device booking store.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Hotel & Room Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.hotelName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.hotelAddress,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildRow('Room Category', booking.roomType),
                      const SizedBox(height: 6),
                      _buildRow('Room Number', 'Room ${booking.roomNumber}'),
                      const SizedBox(height: 6),
                      _buildRow('Party Size', '${booking.partySize} ${booking.partySize == 1 ? "Guest" : "Guests"}'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Stay Dates Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stay Schedule',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Check-in', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                booking.arrivalDate.format(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$effectiveNights ${effectiveNights == 1 ? "Night" : "Nights"}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Check-out', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                booking.departureDate.format(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Traveler Contact Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Traveler Contact',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      _buildRow('Primary Guest', booking.travelerName),
                      const SizedBox(height: 6),
                      _buildRow('Phone Number', booking.travelerPhone),
                      if (booking.travelerEmail != null) ...[
                        const SizedBox(height: 6),
                        _buildRow('Email Address', booking.travelerEmail!),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Payment & Cancellation Policy Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment & Terms',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      _buildRow('Nightly Rate', '${AppMoneyFormat.formatPKR(nightlyRatePKR)} / night'),
                      const SizedBox(height: 6),
                      _buildRow('Total Stay Rate', AppMoneyFormat.formatPKR(totalPKR)),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.cancellationPolicy,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 6. Cancel Action Button if active
                if (!booking.isCancelled) ...[
                  OutlinedButton.icon(
                    onPressed: _isCancelling ? null : () => _promptCancel(booking),
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined, color: Color(0xFFD32F2F)),
                    label: const Text(
                      'Cancel This Reservation',
                      style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                const SizedBox(height: 36),
              ],
            ),
          ),
        );
      },
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
