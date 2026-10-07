import 'package:flutter/material.dart';

import '../../../../domain/models/hotel.dart';
import '../../../../shared/formatting/app_money_format.dart';
import '../../../../shared/widgets/hotel_network_image.dart';

/// Photo-led card representing a hotel in the Explore and Saved feeds.
class HotelCard extends StatelessWidget {
  const HotelCard({
    super.key,
    required this.hotel,
    this.lowestNightlyRatePKR,
    this.distanceText,
    this.isSaved = false,
    this.onTap,
    this.onToggleSaved,
    this.reconnectSignal,
  });

  final Hotel hotel;
  final int? lowestNightlyRatePKR;
  final String? distanceText;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSaved;
  final Listenable? reconnectSignal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBorder = isDark ? const Color(0xFF2B3830) : const Color(0xFFE2EBE5);
    final cardBg = isDark ? const Color(0xFF18201B) : Colors.white;

    final primaryImageUrl =
        hotel.gallery.isNotEmpty ? hotel.gallery.first : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Stack with Badges & Save Action
          Stack(
            children: [
              GestureDetector(
                onTap: onTap,
                child: HotelNetworkImage(
                  imageUrl: primaryImageUrl,
                  aspectRatio: 16 / 9,
                  semanticLabel: '${hotel.name} exterior',
                  reconnectSignal: reconnectSignal,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),

                // Top-Left: Rating Pill
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC107),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hotel.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' (${hotel.reviewCount})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-Right: Saved Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        color: isSaved
                            ? const Color(0xFFE53935)
                            : Colors.white,
                        size: 20,
                      ),
                      onPressed: onToggleSaved,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      tooltip: isSaved ? 'Remove from saved' : 'Save hotel',
                    ),
                  ),
                ),
              ],
            ),

            // Content Area
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location and Distance Row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${hotel.area}, ${hotel.city}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            distanceText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Pricing & Availability Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (lowestNightlyRatePKR != null) ...[
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'From ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  AppMoneyFormat.formatPKRFromMinor(lowestNightlyRatePKR! * 100),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                ' / night',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C241E)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'No rooms for these dates',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF92400E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],

                      // View stay indicator
                      Row(
                        children: [
                          Text(
                            'View rooms',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
