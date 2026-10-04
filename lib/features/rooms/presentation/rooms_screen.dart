import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/booking.dart';
import '../../../domain/models/hotel_state.dart';
import '../../../domain/models/room.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../bookings/presentation/booking_widgets.dart';
import 'room_detail_screen.dart';
import 'room_form_screen.dart';
import 'room_widgets.dart';

enum RoomFilterTab {
  all,
  available,
  occupied,
  reserved;

  static RoomFilterTab fromRoomStatus(RoomStatus? status) => switch (status) {
    RoomStatus.available => RoomFilterTab.available,
    RoomStatus.occupied => RoomFilterTab.occupied,
    null => RoomFilterTab.all,
  };
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({
    super.key,
    required this.controller,
    required this.themeController,
    this.requestedFilter,
    this.filterRequestKey = 0,
    this.scrollController,
  });

  final HotelController controller;
  final ThemeController themeController;
  final RoomStatus? requestedFilter;
  final int filterRequestKey;
  final ScrollController? scrollController;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _search = TextEditingController();
  RoomFilterTab _filter = RoomFilterTab.all;

  @override
  void initState() {
    super.initState();
    _filter = RoomFilterTab.fromRoomStatus(widget.requestedFilter);
  }

  @override
  void didUpdateWidget(covariant RoomsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterRequestKey != oldWidget.filterRequestKey) {
      _search.clear();
      _filter = RoomFilterTab.fromRoomStatus(widget.requestedFilter);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _search.clear();
    _filter = RoomFilterTab.all;
  });

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomFormScreen(controller: widget.controller),
      ),
    );
    if (!mounted || saved != true) return;
    // A newly added room should be visible even after an occupied-only search.
    _reset();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Room added.')));
  }

  Future<void> _open(Room room) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoomDetailScreen(controller: widget.controller, roomId: room.id),
      ),
    );
    if (mounted && deleted == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Room deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final query = _search.text.trim().toLowerCase();
      final rooms =
          state.rooms
              .where((room) {
                if (query.isNotEmpty &&
                    !room.number.toLowerCase().contains(query) &&
                    !room.type.toLowerCase().contains(query)) {
                  return false;
                }
                final roomBookings = state.bookings
                    .where((b) => b.roomId == room.id && b.isActive)
                    .toList();
                final isOccupied = roomBookings.any(
                  (b) => b.status == BookingStatus.checkedIn,
                );
                final isReserved = !isOccupied &&
                    roomBookings.any(
                      (b) => b.status == BookingStatus.reserved,
                    );
                final isAvailable = !isOccupied && !isReserved;

                return switch (_filter) {
                  RoomFilterTab.all => true,
                  RoomFilterTab.available => isAvailable,
                  RoomFilterTab.occupied => isOccupied,
                  RoomFilterTab.reserved =>
                    isReserved ||
                    roomBookings.any((b) => b.status == BookingStatus.reserved),
                };
              })
              .toList()
            ..sort((a, b) {
              // A single lexical ordering stays consistent for mixed identifiers.
              return a.number.toLowerCase().compareTo(b.number.toLowerCase());
            });
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
                key: const PageStorageKey('rooms-list'),
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
                                  'Rooms',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _add,
                                icon: const Icon(
                                  Icons.meeting_room_outlined,
                                  size: 18,
                                ),
                                label: const Text('Add Room'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage your rooms, rates, and current occupancy.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            decoration: InputDecoration(
                              hintText: 'Search room number or type',
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final (index, item) in <(RoomFilterTab, String)>[
                                  (RoomFilterTab.all, 'All'),
                                  (RoomFilterTab.available, 'Available'),
                                  (RoomFilterTab.occupied, 'Occupied'),
                                  (RoomFilterTab.reserved, 'Reserved'),
                                ].indexed) ...[
                                  if (index > 0) const SizedBox(width: 8),
                                  ChoiceChip(
                                    showCheckmark: false,
                                    selectedColor: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    shape: const StadiumBorder(),
                                    side: BorderSide(
                                      color: _filter == item.$1
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: _filter == item.$1
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          fontWeight: _filter == item.$1
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                    label: Text(item.$2),
                                    selected: _filter == item.$1,
                                    onSelected: (_) =>
                                        setState(() => _filter = item.$1),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.padded,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (rooms.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              '${rooms.length} ${rooms.length == 1 ? 'room' : 'rooms'}${query.isNotEmpty || _filter != RoomFilterTab.all ? ' matching' : ' in your hotel'}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (rooms.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 8, padding, 48),
                      sliver: SliverToBoxAdapter(
                        child: _RoomEmpty(
                          firstUse: state.rooms.isEmpty,
                          query: query,
                          filter: _filter,
                          onAdd: _add,
                          onReset: _reset,
                          onClearSearch: () => setState(_search.clear),
                          onClearFilter: () =>
                              setState(() => _filter = RoomFilterTab.all),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
                      sliver: SliverList.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RoomTile(
                              room: room,
                              state: state,
                              showStatusChip: _filter == RoomFilterTab.all,
                              onTap: () => _open(room),
                            ),
                          );
                        },
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
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.state,
    required this.showStatusChip,
    required this.onTap,
  });

  final Room room;
  final HotelState state;
  final bool showStatusChip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final roomBookings = state.bookings
        .where((b) => b.roomId == room.id && b.isActive)
        .toList();

    final checkedInBooking = roomBookings
        .where((b) => b.status == BookingStatus.checkedIn)
        .firstOrNull;

    final reservedBookings = roomBookings
        .where((b) => b.status == BookingStatus.reserved)
        .toList()
      ..sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));

    final nextReservedBooking = reservedBookings.firstOrNull;

    final isOccupied = checkedInBooking != null;
    final isReserved = !isOccupied && nextReservedBooking != null;

    final status = isOccupied ? RoomStatus.occupied : RoomStatus.available;
    final totalStays =
        state.bookings.where((b) => b.roomId == room.id).length;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withAlpha(120)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? (dark
                              ? const Color(0xFF443725)
                              : const Color(0xFFFFF1D9))
                          : (isReserved
                              ? (dark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFEFF6FF))
                              : (dark
                                  ? const Color(0xFF253E35)
                                  : const Color(0xFFE8F5ED))),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isOccupied
                            ? Icons.door_front_door_outlined
                            : (isReserved
                                ? Icons.event_available_outlined
                                : Icons.meeting_room_outlined),
                        size: 22,
                        color: isOccupied
                            ? (dark
                                ? const Color(0xFFF3CD90)
                                : const Color(0xFF78500E))
                            : (isReserved
                                ? (dark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1E40AF))
                                : (dark
                                    ? const Color(0xFF9FDCBC)
                                    : const Color(0xFF246344))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room.number}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showStatusChip) ...[
                    const SizedBox(width: 8),
                    RoomStatusBadge(
                      status: status,
                      isReserved: isReserved,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant.withAlpha(150),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Rate & Stays summary row
              Row(
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formatPkr(room.nightlyRateMinor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          ' / night',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        totalStays == 1 ? '1 stay' : '$totalStays stays',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Context Stay Banner
              const SizedBox(height: 10),
              if (checkedInBooking != null) ...[
                () {
                  final guest = state.guests.any(
                    (g) => g.id == checkedInBooking.primaryGuestId,
                  )
                      ? state.guest(checkedInBooking.primaryGuestId)
                      : null;
                  final nextGuest = nextReservedBooking != null &&
                          state.guests.any(
                            (g) => g.id == nextReservedBooking.primaryGuestId,
                          )
                      ? state.guest(nextReservedBooking.primaryGuestId)
                      : null;
                  final bannerDark = dark;
                  final primaryColor = bannerDark
                      ? const Color(0xFFF3CD90)
                      : const Color(0xFF78500E);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bannerDark
                          ? const Color(0xFF332B1D)
                          : const Color(0xFFFFF7EB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: bannerDark
                            ? const Color(0xFF5A4325)
                            : const Color(0xFFFBE8D3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Occupied by ${guest?.name ?? 'Guest'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: primaryColor.withAlpha(200),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formatStayDates(
                                  checkedInBooking.arrivalDate,
                                  checkedInBooking.departureDate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (nextReservedBooking != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event_outlined,
                                size: 13,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Next: ${nextGuest?.name ?? 'Reserved'} from ${nextReservedBooking.arrivalDate}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }(),
              ] else if (nextReservedBooking != null) ...[
                () {
                  final guest = state.guests.any(
                    (g) => g.id == nextReservedBooking.primaryGuestId,
                  )
                      ? state.guest(nextReservedBooking.primaryGuestId)
                      : null;
                  final bannerDark = dark;
                  final primaryColor = bannerDark
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFF1E40AF);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bannerDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: bannerDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Reserved for ${guest?.name ?? 'Guest'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: primaryColor.withAlpha(200),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formatStayDates(
                                  nextReservedBooking.arrivalDate,
                                  nextReservedBooking.departureDate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }(),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1B382B)
                        : const Color(0xFFE8F5ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFF2C5642)
                          : const Color(0xFFC3E6D2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: dark
                            ? const Color(0xFF9FDCBC)
                            : const Color(0xFF246344),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Available • Ready for check-in',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? const Color(0xFF9FDCBC)
                                : const Color(0xFF246344),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomEmpty extends StatelessWidget {
  const _RoomEmpty({
    required this.firstUse,
    required this.query,
    required this.filter,
    required this.onAdd,
    required this.onReset,
    required this.onClearSearch,
    required this.onClearFilter,
  });

  final bool firstUse;
  final String query;
  final RoomFilterTab filter;
  final VoidCallback onAdd;
  final VoidCallback onReset;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    if (firstUse) {
      return EmptyStateView(
        icon: Icons.meeting_room_outlined,
        title: 'No rooms added yet',
        message:
            'Add your first room to manage room rates, amenities, and guest occupancy.',
        actionLabel: 'Add your first room',
        actionIcon: Icons.add,
        onAction: onAdd,
      );
    }

    final trimmed = query.trim();
    final statusLabel = switch (filter) {
      RoomFilterTab.available => 'Available',
      RoomFilterTab.occupied => 'Occupied',
      RoomFilterTab.reserved => 'Reserved',
      RoomFilterTab.all => '',
    };

    if (trimmed.isNotEmpty && filter != RoomFilterTab.all) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No $statusLabel rooms match "$trimmed"',
        message:
            'We couldn\'t find any ${statusLabel.toLowerCase()} rooms matching "$trimmed". Try clearing the filter or checking your search query.',
        actionLabel: 'Reset search & filter',
        actionIcon: Icons.refresh_rounded,
        onAction: onReset,
      );
    }

    if (trimmed.isNotEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No rooms found for "$trimmed"',
        message:
            'No rooms match your search query. Try searching by room number (e.g. 101) or room type.',
        actionLabel: 'Clear search',
        actionIcon: Icons.clear_rounded,
        onAction: onClearSearch,
      );
    }

    if (filter != RoomFilterTab.all) {
      return EmptyStateView(
        icon: Icons.filter_list_off_rounded,
        title: 'No $statusLabel rooms',
        message:
            'There are currently no rooms marked as ${statusLabel.toLowerCase()} in your hotel.',
        actionLabel: 'Show all rooms',
        actionIcon: Icons.view_list_rounded,
        onAction: onClearFilter,
      );
    }

    return EmptyStateView(
      icon: Icons.meeting_room_outlined,
      title: 'No rooms match',
      message:
          'Try adjusting your search query or filters to find what you are looking for.',
      actionLabel: 'Reset filters',
      actionIcon: Icons.refresh_rounded,
      onAction: onReset,
    );
  }
}
