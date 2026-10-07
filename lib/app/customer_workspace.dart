import 'package:flutter/material.dart';

import '../application/customer_controller.dart';
import '../application/location_controller.dart';
import '../application/theme_controller.dart';
import '../domain/models/hotel.dart';
import '../domain/services/connectivity_service.dart';
import '../features/bookings/presentation/customer_bookings_screen.dart';
import '../features/explore/presentation/explore_screen.dart';
import '../features/hotels/presentation/hotel_detail_screen.dart';
import '../features/profile/presentation/customer_profile_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import '../shared/widgets/hotel_bottom_bar.dart';

/// Primary responsive workspace for the customer hotel discovery & booking app.
///
/// Features:
/// - 4 core destinations: Explore, Saved, Bookings, Profile.
/// - Preserves per-tab search, filter, and scroll state via IndexedStack.
/// - Seamless adaptation between mobile frosted glass bottom bar and desktop NavigationRail.
class CustomerWorkspace extends StatefulWidget {
  const CustomerWorkspace({
    super.key,
    required this.customerController,
    required this.themeController,
    this.locationController,
    this.connectivityService,
    this.initialIndex = 0,
    this.onSelectHotel,
  });

  final CustomerController customerController;
  final ThemeController themeController;
  final LocationController? locationController;
  final ConnectivityService? connectivityService;
  final int initialIndex;
  final ValueChanged<Hotel>? onSelectHotel;

  @override
  State<CustomerWorkspace> createState() => _CustomerWorkspaceState();
}

class _CustomerWorkspaceState extends State<CustomerWorkspace> {
  late int _selected;
  late final LocationController _locationController;
  late final ConnectivityService _connectivityService;
  bool _ownsControllers = false;

  static const List<HotelDestination> _destinations = [
    HotelDestination(
      label: 'Explore',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
    ),
    HotelDestination(
      label: 'Saved',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
    ),
    HotelDestination(
      label: 'Bookings',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    HotelDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex;
    if (widget.locationController == null) {
      _locationController = LocationController();
      _ownsControllers = true;
    } else {
      _locationController = widget.locationController!;
    }

    if (widget.connectivityService == null) {
      _connectivityService = ConnectivityService();
      _ownsControllers = true;
    } else {
      _connectivityService = widget.connectivityService!;
    }
  }

  @override
  void dispose() {
    if (_ownsControllers) {
      if (widget.locationController == null) _locationController.dispose();
      if (widget.connectivityService == null) _connectivityService.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selected = index);
  }

  void _handleSelectHotel(Hotel hotel) {
    if (widget.onSelectHotel != null) {
      widget.onSelectHotel!(hotel);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => HotelDetailScreen(
          hotel: hotel,
          customerController: widget.customerController,
          locationController: _locationController,
          connectivityService: _connectivityService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rail = constraints.maxWidth >= 640;

        final screens = [
          ExploreScreen(
            customerController: widget.customerController,
            locationController: _locationController,
            connectivityService: _connectivityService,
            onSelectHotel: _handleSelectHotel,
          ),
          SavedScreen(
            customerController: widget.customerController,
            locationController: _locationController,
            connectivityService: _connectivityService,
            onSelectHotel: _handleSelectHotel,
            onNavigateToExplore: () => _select(0),
          ),
          CustomerBookingsScreen(
            customerController: widget.customerController,
            onNavigateToExplore: () => _select(0),
          ),
          CustomerProfileScreen(
            customerController: widget.customerController,
            themeController: widget.themeController,
          ),
        ];

        final content = IndexedStack(
          index: _selected,
          children: screens,
        );

        return SafeArea(
          top: false,
          bottom: rail,
          child: Row(
            children: [
              if (rail) ...[
                NavigationRail(
                  selectedIndex: _selected,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: Text('Explore'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: Text('Saved'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Bookings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                key: const ValueKey('customer-workspace-content'),
                child: rail
                    ? content
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: content,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: HotelBottomBar(
                              selectedIndex: _selected,
                              onSelected: _select,
                              destinations: _destinations,
                            ),
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
}
