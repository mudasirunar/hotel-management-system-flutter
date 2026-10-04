import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../domain/hotel_exception.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../bookings/presentation/booking_detail_screen.dart';
import '../../bookings/presentation/booking_widgets.dart';
import 'room_form_screen.dart';
import 'room_widgets.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.controller,
    required this.roomId,
  });

  final HotelController controller;
  final String roomId;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool _deleting = false;
  bool _confirming = false;
  String? _error;

  Future<void> _delete(String number) async {
    if (_deleting || _confirming) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete room $number?'),
        content: const Text(
          'This permanently removes the room from your inventory. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep room'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete room'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (!mounted || confirmed != true) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.controller.deleteRoom(widget.roomId);
      if (!mounted) return;
      setState(() => _deleting = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } on HotelException catch (error) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = error.message;
        });
      }
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RoomFormScreen(
          controller: widget.controller,
          room: widget.controller.state.room(widget.roomId),
        ),
      ),
    );
    if (mounted && saved == true) {
      setState(() => _error = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Room updated.')));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Room details'),
        leading: IconButton(
          onPressed: _deleting ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            final matches = state.rooms.where((r) => r.id == widget.roomId);
            if (matches.isEmpty) {
              return Center(
                child: Text(
                  _deleting
                      ? 'Removing room…'
                      : 'This room is no longer available.',
                ),
              );
            }
            final room = matches.first;
            final linked = state.bookings.any((b) => b.roomId == room.id);
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RoomStatusBadge(
                          status: state.roomStatus(room.id),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Room ${room.number}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        room.type,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nightly price',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatPkr(room.nightlyRateMinor),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text('Per room, per night'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const AppNotice(
                        message: 'Status reflects current occupancy. Future reservations do not mark a room occupied. Check-in and check-out update it automatically.',
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _deleting ? null : _edit,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Edit room'),
                      ),
                      const SizedBox(height: 12),
                      if (linked) ...[
                        const AppNotice(
                          message: 'This room has booking history and cannot be deleted. You can still edit its details; existing booked rates stay unchanged.',
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final roomBookings = state.bookings
                                .where((b) => b.roomId == room.id)
                                .toList()
                                .reversed
                                .toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Bookings (${roomBookings.length})',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                for (final booking in roomBookings.take(3)) ...[
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingDetailScreen(
                                            controller: widget.controller,
                                            bookingId: booking.id,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    state.guests.any(
                                                          (g) =>
                                                              g.id ==
                                                              booking
                                                                  .primaryGuestId,
                                                        )
                                                        ? state
                                                              .guest(
                                                                booking
                                                                    .primaryGuestId,
                                                              )
                                                              .name
                                                        : 'Guest ${booking.primaryGuestId}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${booking.arrivalDate} → ${booking.departureDate}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            BookingStatusBadge(
                                              status: booking.status,
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.chevron_right,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_error != null) ...[
                        AppNotice(message: _error!, isError: true),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: _deleting || linked
                            ? null
                            : () => _delete(room.number),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: _deleting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Deleting room',
                                ),
                              )
                            : const Icon(Icons.delete_outline, size: 20),
                        label: Text(
                          _deleting
                              ? 'Deleting…'
                              : _error == null
                              ? 'Delete room'
                              : 'Retry delete',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
