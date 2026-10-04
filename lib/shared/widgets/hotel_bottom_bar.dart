import 'dart:ui' show SemanticsRole;

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

/// Compact vertical destinations keep the same design as more tabs are added.
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
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        child: Semantics(
          role: SemanticsRole.tabBar,
          explicitChildNodes: true,
          child: Stack(
            children: [
              // Only the icon gets the active capsule; labels never widen it.
              PositionedDirectional(
                start: 0,
                end: 0,
                top: 4,
                height: 36,
                child: AnimatedAlign(
                  alignment: AlignmentDirectional(
                    -1 + 2 * selectedIndex / (destinations.length - 1),
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
                  for (final (index, destination) in destinations.indexed)
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
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(18),
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
