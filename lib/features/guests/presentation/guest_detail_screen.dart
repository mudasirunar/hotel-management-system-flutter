import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../domain/hotel_exception.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../bookings/presentation/booking_detail_screen.dart';
import '../../bookings/presentation/booking_widgets.dart';
import 'guest_form_screen.dart';

class GuestDetailScreen extends StatefulWidget {
  const GuestDetailScreen({
    super.key,
    required this.controller,
    required this.guestId,
  });

  final HotelController controller;
  final String guestId;

  @override
  State<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  bool _deleting = false;
  bool _confirming = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleting || _confirming) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete guest?'),
        content: const Text(
          'This permanently removes this guest profile. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep guest'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete guest'),
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
      await widget.controller.deleteGuest(widget.guestId);
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
        builder: (context) => GuestFormScreen(
          controller: widget.controller,
          guest: widget.controller.state.guest(widget.guestId),
        ),
      ),
    );
    if (mounted && saved == true) {
      setState(() => _error = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Guest updated.')));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Guest details'),
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
            final matches = state.guests.where((r) => r.id == widget.guestId);
            if (matches.isEmpty) {
              return Center(
                child: Text(
                  _deleting
                      ? 'Removing guest…'
                      : 'This guest is no longer available.',
                ),
              );
            }
            final guest = matches.first;
            final linked = state.bookings.any(
              (b) => b.guestIds.contains(guest.id),
            );
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        guest.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Guest profile',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DetailField(
                              label: 'Phone number',
                              value: formatPhone(guest.phone),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(),
                            ),
                            _DetailField(
                              label: 'CNIC',
                              value: formatCnic(guest.cnic),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(),
                            ),
                            _DetailField(
                              label: 'Address',
                              value: guest.address,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _deleting ? null : _edit,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Edit guest'),
                      ),
                      const SizedBox(height: 12),
                      if (linked) ...[
                        const AppNotice(
                          message: 'This guest has booking history and cannot be deleted. You can still edit their details without breaking booking links.',
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final guestBookings = state.bookings
                                .where((b) => b.guestIds.contains(guest.id))
                                .toList()
                                .reversed
                                .toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stay History (${guestBookings.length})',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                for (final booking in guestBookings.take(
                                  3,
                                )) ...[
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
                                                    state.rooms.any(
                                                          (r) =>
                                                              r.id ==
                                                              booking.roomId,
                                                        )
                                                        ? 'Room ${state.room(booking.roomId).number} • ${state.room(booking.roomId).type}'
                                                        : 'Room ${booking.roomId}',
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
                        onPressed: _deleting || linked ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: _deleting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Deleting guest',
                                ),
                              )
                            : const Icon(Icons.delete_outline, size: 20),
                        label: Text(
                          _deleting
                              ? 'Deleting…'
                              : _error == null
                              ? 'Delete guest'
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

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}
