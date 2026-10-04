import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/booking.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/formatting/money.dart';
import '../../guests/presentation/guest_form_screen.dart';
import '../../rooms/presentation/room_form_screen.dart';
import 'booking_detail_screen.dart';
import 'booking_form_screen.dart';
import 'booking_widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({
    super.key,
    required this.controller,
    required this.themeController,
    this.requestedFilter,
    this.filterRequestKey = 0,
    this.scrollController,
  });

  final HotelController controller;
  final ThemeController themeController;
  final BookingStatus? requestedFilter;
  final int filterRequestKey;
  final ScrollController? scrollController;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _search = TextEditingController();
  BookingStatus? _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.requestedFilter;
  }

  @override
  void didUpdateWidget(covariant BookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterRequestKey != oldWidget.filterRequestKey) {
      _search.clear();
      _filter = widget.requestedFilter;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _search.clear();
    _filter = null;
  });

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(controller: widget.controller),
      ),
    );
    if (!mounted || saved != true) return;
    _reset();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reservation confirmed.')));
  }

  Future<void> _open(Booking booking) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          controller: widget.controller,
          bookingId: booking.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final query = _search.text.trim().toLowerCase();

      final filteredBookings = state.bookings.where((booking) {
        if (_filter != null && booking.status != _filter) return false;
        if (query.isEmpty) return true;

        // Match room number or type
        final room = state.rooms.any((r) => r.id == booking.roomId)
            ? state.room(booking.roomId)
            : null;
        if (room != null) {
          if (room.number.toLowerCase().contains(query) ||
              room.type.toLowerCase().contains(query)) {
            return true;
          }
        }

        // Match guest name or phone
        for (final gid in booking.guestIds) {
          if (state.guests.any((g) => g.id == gid)) {
            final guest = state.guest(gid);
            if (guest.name.toLowerCase().contains(query) ||
                guest.phone.contains(query)) {
              return true;
            }
          }
        }

        return false;
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 600 ? 16.0 : 32.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                primary: false,
                controller: widget.scrollController,
                key: const PageStorageKey('bookings-list'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 20, padding, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Bookings',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _add,
                                icon: const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                ),
                                label: const Text('New Booking'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage reservations, stays, and guest check-ins.',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Search field
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            autocorrect: false,
                            onSubmitted: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            decoration: InputDecoration(
                              hintText: 'Search by room, guest, or phone',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(_search.clear),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status filters in a horizontal row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final (index, item)
                                    in <(BookingStatus?, String)>[
                                      (null, 'All'),
                                      (BookingStatus.reserved, 'Reserved'),
                                      (BookingStatus.checkedIn, 'Checked In'),
                                      (BookingStatus.checkedOut, 'Checked Out'),
                                      (BookingStatus.cancelled, 'Cancelled'),
                                    ].indexed) ...[
                                  if (index > 0) const SizedBox(width: 8),
                                  ChoiceChip(
                                    showCheckmark: false,
                                    selectedColor: scheme.primary,
                                    backgroundColor: scheme.surface,
                                    shape: const StadiumBorder(),
                                    side: BorderSide(
                                      color: _filter == item.$1
                                          ? scheme.primary
                                          : scheme.outlineVariant,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    labelStyle: theme.textTheme.labelLarge
                                        ?.copyWith(
                                          color: _filter == item.$1
                                              ? scheme.onPrimary
                                              : scheme.onSurfaceVariant,
                                          fontWeight: _filter == item.$1
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                    label: Text(item.$2),
                                    selected: _filter == item.$1,
                                    onSelected: (_) {
                                      setState(() => _filter = item.$1);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Content states
                  if (state.rooms.isEmpty || state.guests.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hotel_outlined,
                                  size: 48,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Set up rooms and guests first',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bookings link guests with rooms. Add at least one room and one guest to start taking reservations.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    if (state.rooms.isEmpty)
                                      FilledButton.tonal(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RoomFormScreen(
                                              controller: widget.controller,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Add Room'),
                                      ),
                                    if (state.guests.isEmpty)
                                      FilledButton.tonal(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GuestFormScreen(
                                              controller: widget.controller,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Add Guest'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (state.bookings.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 48,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookings yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create a reservation to assign rooms, dates, and guests.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: _add,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('New Booking'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (filteredBookings.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching bookings',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try changing your search query or status filter.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: _reset,
                                child: const Text('Reset filters'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final booking = filteredBookings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _bookingCard(
                              context,
                              state,
                              booking,
                              scheme,
                            ),
                          );
                        }, childCount: filteredBookings.length),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Widget _bookingCard(
    BuildContext context,
    dynamic state,
    Booking booking,
    ColorScheme scheme,
  ) {
    final theme = Theme.of(context);
    final room = state.rooms.any((r) => r.id == booking.roomId)
        ? state.room(booking.roomId)
        : null;
    final primaryGuest = state.guests.any((g) => g.id == booking.primaryGuestId)
        ? state.guest(booking.primaryGuestId)
        : null;
    final nights = booking.nights;
    final totalCost = nights * booking.nightlyRateMinorSnapshot;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room != null
                          ? 'Room ${room.number} • ${room.type}'
                          : 'Room ${booking.roomId}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      primaryGuest != null
                          ? '${primaryGuest.name} ${booking.guestIds.length > 1 ? '(+${booking.guestIds.length - 1} more)' : ''}'
                          : 'Guest ID: ${booking.primaryGuestId}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (primaryGuest != null)
                    Text(
                      formatPhone(primaryGuest.phone),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatStayDates(
                        booking.arrivalDate,
                        booking.departureDate,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    formatPkr(totalCost),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
