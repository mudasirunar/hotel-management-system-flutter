import 'package:flutter/material.dart';

/// Clean chips grid displaying curated hotel amenities with icons.
class HotelAmenitiesGrid extends StatelessWidget {
  const HotelAmenitiesGrid({
    super.key,
    required this.amenities,
  });

  final List<String> amenities;

  static IconData getIconForAmenity(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('pool') || lower.contains('swim')) {
      return Icons.pool_rounded;
    }
    if (lower.contains('breakfast') || lower.contains('dining') || lower.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('park')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('spa') || lower.contains('sauna')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('ac') || lower.contains('air') || lower.contains('cooling')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('bar') || lower.contains('lounge')) {
      return Icons.local_bar_rounded;
    }
    if (lower.contains('service') || lower.contains('concierge')) {
      return Icons.room_service_rounded;
    }
    if (lower.contains('shuttle') || lower.contains('transfer')) {
      return Icons.airport_shuttle_rounded;
    }
    if (lower.contains('view') || lower.contains('balcony')) {
      return Icons.balcony_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((amenity) {
        final icon = getIconForAmenity(amenity);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F6F3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                amenity,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
