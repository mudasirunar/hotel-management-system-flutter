import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../domain/hotel_exception.dart';
import '../../../domain/models/booking.dart';
import '../../../domain/models/stay_date.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/app_notice.dart';
import 'booking_widgets.dart';

String formatTimestamp(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.controller,
    required this.bookingId,
  });

  final HotelController controller;
  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _operating = false;
  String? _error;

  Future<void> _checkIn(String roomNumber) async {
    if (_operating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check in to Room $roomNumber?'),
        content: Text(
          'Confirm guest arrival and mark Room $roomNumber as Occupied.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Check In'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _operating = true;
      _error = null;
    });

    try {
      await widget.controller.checkIn(widget.bookingId);
      if (!mounted) return;
      setState(() => _operating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest checked into Room $roomNumber.')),
      );
    } on HotelException catch (error) {
      if (mounted) {
        setState(() {
          _operating = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _operating = false;
          _error = 'Unable to check in. Please try again.';
        });
      }
    }
  }

  Future<void> _checkOut(String roomNumber) async {
    if (_operating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check out of Room $roomNumber?'),
        content: Text(
          'Confirm guest departure and mark Room $roomNumber as Available for other guests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _operating = true;
      _error = null;
    });

    try {
      await widget.controller.checkOut(widget.bookingId);
      if (!mounted) return;
      setState(() => _operating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guest checked out of Room $roomNumber. Room is now available.',
          ),
        ),
      );
    } on HotelException catch (error) {
      if (mounted) {
        setState(() {
          _operating = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _operating = false;
          _error = 'Unable to check out. Please try again.';
        });
      }
    }
  }

  Future<void> _cancelReservation() async {
    if (_operating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: const Text(
          'Are you sure you want to cancel this reservation? The room will be made available for other bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep reservation'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _operating = true;
      _error = null;
    });

    try {
      await widget.controller.cancelBooking(widget.bookingId);
      if (!mounted) return;
      setState(() => _operating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reservation cancelled.')));
    } on HotelException catch (error) {
      if (mounted) {
        setState(() {
          _operating = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      Booking booking;
      try {
        booking = state.booking(widget.bookingId);
      } catch (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Booking Details')),
          body: const Center(child: Text('Booking not found.')),
        );
      }

      final room = state.rooms.any((r) => r.id == booking.roomId)
          ? state.room(booking.roomId)
          : null;
      final roomNumber = room?.number ?? booking.roomId;
      final nights = booking.nights;
      final totalRateMinor = nights * booking.nightlyRateMinorSnapshot;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;

      final today = StayDate.fromDateTime(DateTime.now());
      final isCheckInEligible =
          booking.status == BookingStatus.reserved &&
          !today.isBefore(booking.arrivalDate) &&
          today.isBefore(booking.departureDate);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            room != null ? 'Room ${room.number} Booking' : 'Booking Details',
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AppNotice(message: _error!),
                    const SizedBox(height: 16),
                  ],

                  // Header status card
                  Card(
                    elevation: 0,
                    color: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room != null
                                      ? 'Room ${room.number} • ${room.type}'
                                      : 'Room ${booking.roomId}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatStayDates(
                                    booking.arrivalDate,
                                    booking.departureDate,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BookingStatusBadge(status: booking.status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stay Lifecycle Actions
                  if (booking.status == BookingStatus.reserved) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Stay Actions',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            const Divider(height: 20),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: _operating || !isCheckInEligible
                                  ? null
                                  : () => _checkIn(roomNumber),
                              icon: _operating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(
                                _operating ? 'Processing...' : 'Check In Guest',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!isCheckInEligible)
                              Text(
                                today.isBefore(booking.arrivalDate)
                                    ? 'Check-in is eligible starting on arrival date (${booking.arrivalDate}).'
                                    : 'Check-in date has passed.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: scheme.error,
                                side: BorderSide(color: scheme.error),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _operating ? null : _cancelReservation,
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancel Reservation'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (booking.status == BookingStatus.checkedIn) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Stay Actions',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            const Divider(height: 20),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB45309),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: _operating
                                  ? null
                                  : () => _checkOut(roomNumber),
                              icon: _operating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.logout),
                              label: Text(
                                _operating
                                    ? 'Processing...'
                                    : 'Check Out Guest',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Checking out frees Room $roomNumber for new guests.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stay & Pricing Summary
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stay & Pricing',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                          const Divider(height: 24),
                          _infoRow(
                            context,
                            'Arrival Date',
                            booking.arrivalDate.toString(),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            context,
                            'Departure Date',
                            booking.departureDate.toString(),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            context,
                            'Duration',
                            nights == 1 ? '1 night' : '$nights nights',
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            context,
                            'Locked Rate',
                            '${formatPkr(booking.nightlyRateMinorSnapshot)} / night',
                          ),
                          const Divider(height: 24),
                          _infoRow(
                            context,
                            'Estimated Total',
                            formatPkr(totalRateMinor),
                            isBold: true,
                            valueColor: scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stay History / Timestamps Card
                  if (booking.actualCheckInAt != null ||
                      booking.actualCheckOutAt != null) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stay Timestamps',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            const Divider(height: 20),
                            if (booking.actualCheckInAt != null) ...[
                              _infoRow(
                                context,
                                'Actual Check-In',
                                formatTimestamp(booking.actualCheckInAt!),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (booking.actualCheckOutAt != null) ...[
                              _infoRow(
                                context,
                                'Actual Check-Out',
                                formatTimestamp(booking.actualCheckOutAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Guests Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guests (${booking.guestIds.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                          const Divider(height: 24),
                          for (final guestId in booking.guestIds) ...[
                            _guestTile(context, state, guestId, booking),
                            if (guestId != booking.guestIds.last)
                              const Divider(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _guestTile(
    BuildContext context,
    dynamic state,
    String guestId,
    Booking booking,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPrimary = guestId == booking.primaryGuestId;

    if (!state.guests.any((g) => g.id == guestId)) {
      return Text('Guest ID: $guestId', style: theme.textTheme.bodyMedium);
    }
    final guest = state.guest(guestId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isPrimary
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          child: Icon(
            Icons.person_outline,
            size: 20,
            color: isPrimary ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      guest.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isPrimary) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Primary',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${formatPhone(guest.phone)} • ${maskedCnic(guest.cnic)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
