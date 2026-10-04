import 'package:flutter/material.dart';

import '../application/hotel_controller.dart';
import '../application/theme_controller.dart';
import '../domain/models/booking.dart';
import '../features/bookings/presentation/bookings_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/guests/presentation/guests_screen.dart';
import '../features/rooms/presentation/rooms_screen.dart';
import '../shared/widgets/hotel_bottom_bar.dart';

/// All primary destinations are exposed. IndexedStack preserves each list's
/// search, filters, and scroll position while moving between the sections.
class HotelWorkspace extends StatefulWidget {
  const HotelWorkspace({
    super.key,
    required this.controller,
    required this.themeController,
    this.initialIndex = 0,
  });

  final HotelController controller;
  final ThemeController themeController;
  final int initialIndex;

  @override
  State<HotelWorkspace> createState() => _HotelWorkspaceState();
}

class _HotelWorkspaceState extends State<HotelWorkspace> {
  late int _selected;
  RoomFilterTab? _roomFilter;
  int _roomFilterKey = 0;
  BookingStatus? _bookingFilter;
  int _bookingFilterKey = 0;

  late final List<ScrollController> _tabScrollControllers;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex;
    _tabScrollControllers = List.generate(4, (_) => ScrollController());
  }

  @override
  void dispose() {
    for (final c in _tabScrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == _selected) {
      final controller = _tabScrollControllers[index];
      if (controller.hasClients && controller.offset > 0) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      setState(() => _selected = index);
    }
  }

  void _navigateFromDashboard({
    required int tab,
    RoomFilterTab? roomFilter,
    BookingStatus? bookingFilter,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selected = tab;
      if (tab == 1) {
        _roomFilter = roomFilter;
        _roomFilterKey++;
      } else if (tab == 3) {
        _bookingFilter = bookingFilter;
        _bookingFilterKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rail = constraints.maxWidth >= 600;
      final content = Expanded(
        child: IndexedStack(
          index: _selected,
          children: [
            DashboardScreen(
              controller: widget.controller,
              themeController: widget.themeController,
              onNavigate: _navigateFromDashboard,
              scrollController: _tabScrollControllers[0],
            ),
            RoomsScreen(
              controller: widget.controller,
              themeController: widget.themeController,
              requestedFilter: _roomFilter,
              filterRequestKey: _roomFilterKey,
              scrollController: _tabScrollControllers[1],
            ),
            GuestsScreen(
              controller: widget.controller,
              themeController: widget.themeController,
              scrollController: _tabScrollControllers[2],
            ),
            BookingsScreen(
              controller: widget.controller,
              themeController: widget.themeController,
              requestedFilter: _bookingFilter,
              filterRequestKey: _bookingFilterKey,
              scrollController: _tabScrollControllers[3],
            ),
          ],
        ),
      );
      // Keep the same Row/Column ancestry at both widths to retain tab state on rotation.
      return SafeArea(
        top: false,
        bottom: rail,
        child: Row(
          children: [
            if (rail) ...[
              NavigationRail(
                scrollable: true,
                selectedIndex: _selected,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bed_outlined),
                    selectedIcon: Icon(Icons.bed),
                    label: Text('Rooms'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Guests'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_today_outlined),
                    selectedIcon: Icon(Icons.calendar_today),
                    label: Text('Bookings'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              key: const ValueKey('workspace-content'),
              child: Column(
                children: [
                  content,
                  if (!rail)
                    HotelBottomBar(
                      selectedIndex: _selected,
                      onSelected: _select,
                      destinations: const [
                        HotelDestination(
                          icon: Icons.dashboard_outlined,
                          selectedIcon: Icons.dashboard,
                          label: 'Dashboard',
                        ),
                        HotelDestination(
                          icon: Icons.bed_outlined,
                          selectedIcon: Icons.bed,
                          label: 'Rooms',
                        ),
                        HotelDestination(
                          icon: Icons.people_outline,
                          selectedIcon: Icons.people,
                          label: 'Guests',
                        ),
                        HotelDestination(
                          icon: Icons.calendar_today_outlined,
                          selectedIcon: Icons.calendar_today,
                          label: 'Bookings',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
