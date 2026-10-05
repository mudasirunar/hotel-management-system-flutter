import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/booking.dart';
import '../../../domain/models/hotel_state.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/empty_state_view.dart';
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
                              hintText: 'Search room, guest, or phone',
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
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 8, padding, 48),
                      sliver: SliverToBoxAdapter(
                        child: EmptyStateView(
                          icon: Icons.hotel_outlined,
                          title: 'Set up rooms and guests first',
                          message: 'Bookings link guests with rooms. Add at least one room and one guest to start taking reservations.',
                          customActions: [
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 18),
                                    SizedBox(width: 8),
                                    Text('Add Room'),
                                  ],
                                ),
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_add_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Add Guest'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else if (state.bookings.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 8, padding, 48),
                      sliver: SliverToBoxAdapter(
                        child: EmptyStateView(
                          icon: Icons.calendar_month_outlined,
                          title: 'No bookings yet',
                          message: 'Create a reservation to assign rooms, dates, and guests for your hotel.',
                          actionLabel: 'New Booking',
                          actionIcon: Icons.add,
                          onAction: _add,
                        ),
                      ),
                    )
                  else if (filteredBookings.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 8, padding, 48),
                      sliver: SliverToBoxAdapter(
                        child: _buildBookingEmptyState(
                          query: _search.text.trim(),
                          filter: _filter,
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
                  // Bottom spacer so content scrolls clear of floating bottom bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom,
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

  Widget _buildBookingEmptyState({
    required String query,
    required BookingStatus? filter,
  }) {
    final statusLabel = switch (filter) {
      BookingStatus.reserved => 'Reserved',
      BookingStatus.checkedIn => 'Checked-in',
      BookingStatus.checkedOut => 'Checked-out',
      BookingStatus.cancelled => 'Cancelled',
      null => '',
    };

    if (query.isNotEmpty && filter != null) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No $statusLabel bookings match "$query"',
        message:
            'We couldn\'t find any $statusLabel bookings matching "$query". Try clearing the filter or checking your search query.',
        actionLabel: 'Reset search & filter',
        actionIcon: Icons.refresh_rounded,
        onAction: _reset,
      );
    }

    if (query.isNotEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No bookings found for "$query"',
        message: 'No bookings match your search query. Try searching by guest name, phone number, or room number.',
        actionLabel: 'Clear search',
        actionIcon: Icons.clear_rounded,
        onAction: () => setState(_search.clear),
      );
    }

    if (filter != null) {
      return EmptyStateView(
        icon: Icons.filter_list_off_rounded,
        title: 'No $statusLabel bookings',
        message:
            'There are currently no bookings with status "$statusLabel" in your records.',
        actionLabel: 'Show all bookings',
        actionIcon: Icons.view_list_rounded,
        onAction: () => setState(() => _filter = null),
      );
    }

    return EmptyStateView(
      icon: Icons.calendar_month_outlined,
      title: 'No matching bookings',
      message: 'Try adjusting your search query or status filter to find what you are looking for.',
      actionLabel: 'Reset filters',
      actionIcon: Icons.refresh_rounded,
      onAction: _reset,
    );
  }

  Widget _bookingCard(
    BuildContext context,
    HotelState state,
    Booking booking,
    ColorScheme scheme,
  ) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final room = state.rooms.any((r) => r.id == booking.roomId)
        ? state.room(booking.roomId)
        : null;
    final primaryGuest = state.guests.any((g) => g.id == booking.primaryGuestId)
        ? state.guest(booking.primaryGuestId)
        : null;
    final nights = booking.nights;
    final totalCost = nights * booking.nightlyRateMinorSnapshot;

    final (statusColor, statusBg, statusBorder, statusIcon) =
        switch (booking.status) {
          BookingStatus.checkedIn => (
            dark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
            dark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            dark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
            Icons.hotel_outlined,
          ),
          BookingStatus.reserved => (
            dark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
            dark ? const Color(0xFF452205) : const Color(0xFFFEF3C7),
            dark ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
            Icons.event_available_outlined,
          ),
          BookingStatus.checkedOut => (
            dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            Icons.done_all_rounded,
          ),
          BookingStatus.cancelled => (
            dark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
            dark ? const Color(0xFF3B181B) : const Color(0xFFFEE2E2),
            dark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
            Icons.event_busy_outlined,
          ),
        };

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(booking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Status icon avatar + Guest name & Phone + Status badge + Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: statusBorder, width: 1.5),
                    ),
                    child: Center(
                      child: Icon(statusIcon, size: 20, color: statusColor),
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
                                primaryGuest?.name ??
                                    'Guest ${booking.primaryGuestId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (booking.guestIds.length > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest
                                      .withAlpha(dark ? 120 : 180),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${booking.guestIds.length - 1}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (primaryGuest != null &&
                            primaryGuest.phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            formatPhone(primaryGuest.phone),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BookingStatusBadge(status: booking.status),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant.withAlpha(140),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Room Details Row (Full Width - No Truncation)
              Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 15,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    room != null
                        ? 'Room ${room.number}'
                        : 'Room ${booking.roomId}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (room != null && room.type.isNotEmpty) ...[
                    Expanded(
                      child: Text(
                        '  •  ${room.type}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Stay Dates & Duration Row (Full Width - No Truncation)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${booking.arrivalDate}  →  ${booking.departureDate}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(
                              dark ? 120 : 160,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            nights == 1 ? '1 night' : '$nights nights',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Financials Row: Rate Breakdown & Total Cost
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatPkr(booking.nightlyRateMinorSnapshot)} / night',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total: ',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        formatPkr(totalCost),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
