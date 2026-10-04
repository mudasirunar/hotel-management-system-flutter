import 'package:flutter/material.dart';

import '../application/hotel_controller.dart';
import '../application/theme_controller.dart';
import '../features/guests/presentation/guests_screen.dart';
import '../features/rooms/presentation/rooms_screen.dart';
import '../shared/widgets/hotel_bottom_bar.dart';

/// Only completed destinations are exposed. IndexedStack preserves each list's
/// search, filters, and scroll position while moving between the two sections.
class HotelWorkspace extends StatefulWidget {
  const HotelWorkspace({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final HotelController controller;
  final ThemeController themeController;

  @override
  State<HotelWorkspace> createState() => _HotelWorkspaceState();
}

class _HotelWorkspaceState extends State<HotelWorkspace> {
  int _selected = 0;

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rail = constraints.maxWidth >= 600;
      final content = Expanded(
        child: IndexedStack(
          index: _selected,
          children: [
            RoomsScreen(
              controller: widget.controller,
              themeController: widget.themeController,
            ),
            GuestsScreen(
              controller: widget.controller,
              themeController: widget.themeController,
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
                    icon: Icon(Icons.bed_outlined),
                    selectedIcon: Icon(Icons.bed),
                    label: Text('Rooms'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Guests'),
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
                          icon: Icons.bed_outlined,
                          selectedIcon: Icons.bed,
                          label: 'Rooms',
                        ),
                        HotelDestination(
                          icon: Icons.people_outline,
                          selectedIcon: Icons.people,
                          label: 'Guests',
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
