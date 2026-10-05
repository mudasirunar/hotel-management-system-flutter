import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/booking.dart';
import '../../../domain/models/hotel_state.dart';
import '../../bookings/presentation/booking_detail_screen.dart';
import '../../bookings/presentation/booking_form_screen.dart';
import '../../bookings/presentation/booking_widgets.dart';
import '../../guests/presentation/guest_form_screen.dart';
import '../../rooms/presentation/room_form_screen.dart';
import '../../rooms/presentation/rooms_screen.dart';
import '../../settings/presentation/settings_screen.dart';

typedef DashboardNavigationCallback = void Function({
  required int tab,
  RoomFilterTab? roomFilter,
  BookingStatus? bookingFilter,
});

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.themeController,
    this.onNavigate,
    this.scrollController,
  });

  final HotelController controller;
  final ThemeController themeController;
  final DashboardNavigationCallback? onNavigate;
  final ScrollController? scrollController;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final metrics = state.metrics;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final dark = theme.brightness == Brightness.dark;

      final inHouseStays =
          state.bookings
              .where((b) => b.status == BookingStatus.checkedIn)
              .toList()
            ..sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));

      final upcomingStays =
          state.bookings
              .where((b) => b.status == BookingStatus.reserved)
              .toList()
            ..sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));

      return LayoutBuilder(
        builder: (context, constraints) {
          final isPhone = constraints.maxWidth < 600;
          final padding = isPhone ? 16.0 : 32.0;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                primary: false,
                controller: widget.scrollController,
                key: const PageStorageKey('dashboard-scroll'),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 20, padding, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App bar header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Dashboard',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Settings',
                                icon: const Icon(Icons.settings_outlined),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SettingsScreen(
                                      controller: widget.themeController,
                                      hotelController: widget.controller,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Real-time overview of rooms, guests, and stays',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Quick Actions in horizontal row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingFormScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('New Booking'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RoomFormScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.meeting_room,
                                    size: 18,
                                  ),
                                  label: const Text('Add Room'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GuestFormScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_add, size: 18),
                                  label: const Text('Add Guest'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section Title: Key Metrics
                          Text(
                            'Hotel Metrics',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Metrics Grid
                          _buildMetricsGrid(
                            context,
                            metrics,
                            state,
                            isPhone,
                            scheme,
                            dark,
                          ),
                          const SizedBox(height: 28),

                          // In-House Stays Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'In-House Guests (${inHouseStays.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.onNavigate != null)
                                TextButton(
                                  onPressed: () => widget.onNavigate!(
                                    tab: 3,
                                    bookingFilter: BookingStatus.checkedIn,
                                  ),
                                  child: const Text('View In-House Stays'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (inHouseStays.isEmpty)
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: scheme.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.hotel_outlined,
                                        size: 36,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No guests currently checked in',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final stay in inHouseStays)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _activeStayCard(context, state, stay),
                              ),

                          const SizedBox(height: 24),

                          // Upcoming Reservations Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Upcoming Stays (${upcomingStays.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.onNavigate != null)
                                TextButton(
                                  onPressed: () => widget.onNavigate!(
                                    tab: 3,
                                    bookingFilter: BookingStatus.reserved,
                                  ),
                                  child: const Text('View Reservations'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (upcomingStays.isEmpty)
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: scheme.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 36,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No pending reservations',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final stay in upcomingStays.take(5))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _activeStayCard(context, state, stay),
                              ),
                        ],
                      ),
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

  Widget _buildMetricsGrid(
    BuildContext context,
    dynamic metrics,
    HotelState state,
    bool isPhone,
    ColorScheme scheme,
    bool dark,
  ) {
    final total = metrics.totalRooms as int;
    final occ = metrics.occupiedRooms as int;
    final avail = metrics.availableRooms as int;
    final reserved = (metrics.reservedRooms as int?) ??
        state.bookings
            .where((b) => b.status == BookingStatus.reserved)
            .map((b) => b.roomId)
            .toSet()
            .length;
    final occRate = total > 0 ? ((occ / total) * 100).round() : 0;
    final availRate = total > 0 ? ((avail / total) * 100).round() : 0;
    final resRate = total > 0 ? ((reserved / total) * 100).round() : 0;

    final upcomingCount = state.bookings
        .where((b) => b.status == BookingStatus.reserved)
        .length;

    final items = [
      _MetricData(
        title: 'Total Rooms',
        value: total.toString(),
        icon: Icons.apartment_outlined,
        color: dark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
        badge: total == 1 ? '1 unit' : '$total units',
        subtitle: 'Inventory capacity',
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 1, roomFilter: RoomFilterTab.all)
            : null,
      ),
      _MetricData(
        title: 'Available',
        value: avail.toString(),
        icon: Icons.key_outlined,
        color: dark ? const Color(0xFF34D399) : const Color(0xFF047857),
        badge: '$availRate% ready',
        subtitle: 'Ready for check-in',
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 1, roomFilter: RoomFilterTab.available)
            : null,
      ),
      _MetricData(
        title: 'Occupied',
        value: occ.toString(),
        icon: Icons.hotel_outlined,
        color: dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
        badge: '$occRate% in-house',
        subtitle: occ == 1 ? '1 in-house stay' : '$occ in-house stays',
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 1, roomFilter: RoomFilterTab.occupied)
            : null,
      ),
      _MetricData(
        title: 'Reserved',
        value: reserved.toString(),
        icon: Icons.bookmark_added_outlined,
        color: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
        badge: resRate > 0 ? '$resRate% reserved' : '$upcomingCount upcoming',
        subtitle: upcomingCount == 1 ? '1 upcoming stay' : '$upcomingCount upcoming stays',
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 1, roomFilter: RoomFilterTab.reserved)
            : null,
      ),
      _MetricData(
        title: 'Total Guests',
        value: metrics.totalGuests.toString(),
        icon: Icons.people_outline,
        color: dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        badge: 'Directory',
        subtitle: 'Registered profiles',
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 2)
            : null,
      ),
      _MetricData(
        title: 'Active Bookings',
        value: metrics.activeBookings.toString(),
        icon: Icons.calendar_today_outlined,
        color: dark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
        badge: 'Live stays',
        subtitle: 'Ongoing & reserved',
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 3, bookingFilter: null)
            : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth < 650 ? 2 : 3;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _metricCard(context, item, dark),
              ),
          ],
        );
      },
    );
  }

  Widget _metricCard(BuildContext context, _MetricData data, bool dark) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: scheme.outlineVariant.withAlpha(dark ? 120 : 160),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: data.color.withAlpha(dark ? 40 : 25),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(data.icon, size: 18, color: data.color),
                  ),
                  if (data.badge != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: data.color.withAlpha(dark ? 30 : 18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.badge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: data.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.1,
                  color: data.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                data.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.onSurface,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (data.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  data.subtitle!,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeStayCard(BuildContext context, dynamic state, Booking booking) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final room = state.rooms.any((r) => r.id == booking.roomId)
        ? state.room(booking.roomId)
        : null;
    final guest = state.guests.any((g) => g.id == booking.primaryGuestId)
        ? state.guest(booking.primaryGuestId)
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      room != null ? room.number : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guest != null ? guest.name : 'Booking ${booking.id}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (room != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            room.type,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formatStayDates(
                        booking.arrivalDate,
                        booking.departureDate,
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: scheme.onSurfaceVariant.withAlpha(150),
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

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.badge,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;
  final String? subtitle;
  final VoidCallback? onTap;
}
