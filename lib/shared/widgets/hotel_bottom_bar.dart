import 'dart:ui' show ImageFilter, SemanticsRole;

import 'package:flutter/material.dart';

class HotelDestination {
  const HotelDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// iOS-style frosted glass bottom navigation bar.
///
/// Renders a blurred, semi-transparent surface that lets content scroll
/// underneath it for a modern "glass liquid" effect.
class HotelBottomBar extends StatelessWidget {
  const HotelBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<HotelDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    // Frosted glass surface:
    // Dark mode: ~55% dark obsidian glass
    // Light mode: rich emerald tint (emerald-200) with ultra-high transparency (~21% opacity)
    final glassTint = dark
        ? const Color(0xFF16231D).withAlpha(140)
        : const Color(0xFFA7F3D0).withAlpha(50);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: glassTint,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: dark
                    ? Colors.white.withAlpha(20)
                    : const Color(0xFF007F5F).withAlpha(28),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Semantics(
              role: SemanticsRole.tabBar,
              explicitChildNodes: true,
              child: Stack(
                children: [
                  // Animated active capsule
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    top: 4,
                    height: 36,
                    child: AnimatedAlign(
                      alignment: AlignmentDirectional(
                        -1 +
                            2 *
                                selectedIndex /
                                (destinations.length - 1),
                        0,
                      ),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: FractionallySizedBox(
                        widthFactor: 1 / destinations.length,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, destination)
                          in destinations.indexed)
                        Expanded(
                          child: _Tab(
                            destination: destination,
                            selected: index == selectedIndex,
                            duration: duration,
                            onTap: () => onSelected(index),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final HotelDestination destination;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  child: Center(
                    child: AnimatedScale(
                      scale: selected ? 1 : 0.92,
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: AnimatedSwitcher(
                        duration: duration,
                        child: Icon(
                          selected
                              ? destination.selectedIcon
                              : destination.icon,
                          key: ValueKey(selected),
                          size: 23,
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.2,
                  ),
                  child: Text(destination.label, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
