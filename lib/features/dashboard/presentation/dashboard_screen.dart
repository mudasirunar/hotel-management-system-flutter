import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/booking.dart';
import '../../../domain/models/room.dart';
import '../../bookings/presentation/booking_detail_screen.dart';
import '../../bookings/presentation/booking_form_screen.dart';
import '../../bookings/presentation/booking_widgets.dart';
import '../../guests/presentation/guest_form_screen.dart';
import '../../rooms/presentation/room_form_screen.dart';
import '../../settings/presentation/settings_screen.dart';

typedef DashboardNavigationCallback = void Function({
  required int tab,
  RoomStatus? roomFilter,
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
                            isPhone,
                            scheme,
                            dark,
                          ),
                          const SizedBox(height: 28),

                          // In-House Stays Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'In-House Guests (${inHouseStays.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                              Text(
                                'Upcoming Stays (${upcomingStays.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
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
    bool isPhone,
    ColorScheme scheme,
    bool dark,
  ) {
    final items = [
      _MetricData(
        title: 'Total Rooms',
        value: metrics.totalRooms.toString(),
        icon: Icons.apartment_outlined,
        color: dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 1, roomFilter: null)
            : null,
      ),
      _MetricData(
        title: 'Available Rooms',
        value: metrics.availableRooms.toString(),
        icon: Icons.key_outlined,
        color: dark ? const Color(0xFF34D399) : const Color(0xFF007F5F),
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 1, roomFilter: RoomStatus.available)
            : null,
      ),
      _MetricData(
        title: 'Occupied Rooms',
        value: metrics.occupiedRooms.toString(),
        icon: Icons.hotel_outlined,
        color: dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 1, roomFilter: RoomStatus.occupied)
            : null,
      ),
      _MetricData(
        title: 'Total Guests',
        value: metrics.totalGuests.toString(),
        icon: Icons.people_outline,
        color: dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 2)
            : null,
      ),
      _MetricData(
        title: 'Active Bookings',
        value: metrics.activeBookings.toString(),
        icon: Icons.calendar_today_outlined,
        color: dark ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(tab: 3, bookingFilter: null)
            : null,
      ),
    ];

    if (isPhone) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (index, item) in items.indexed)
                SizedBox(
                  width: index == 4 ? constraints.maxWidth : halfWidth,
                  child: _metricCard(context, item),
                ),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          for (final item in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _metricCard(context, item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, _MetricData data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: data.color.withAlpha(24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, size: 22, color: data.color),
                  ),
                  if (data.onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: data.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Text(
                  room != null ? room.number : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontSize: 14,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${room != null ? room.type : 'Room'} • ${formatStayDates(booking.arrivalDate, booking.departureDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}
