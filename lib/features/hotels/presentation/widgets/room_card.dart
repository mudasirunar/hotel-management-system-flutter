import 'package:flutter/material.dart';

import '../../../../domain/models/hotel_room.dart';
import '../../../../domain/models/stay_date.dart';
import '../../../../domain/services/customer_availability_service.dart';
import '../../../../shared/formatting/app_money_format.dart';
import '../../../../shared/widgets/hotel_network_image.dart';

/// Card presenting a specific hotel room option with live availability status,
/// pricing breakdown, bed configuration, and reserve action.
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.arrival,
    required this.departure,
    required this.partySize,
    required this.status,
    required this.fallbackImageUrl,
    this.reconnectSignal,
    this.onSelect,
  });

  final HotelRoom room;
  final StayDate arrival;
  final StayDate departure;
  final int partySize;
  final RoomAvailabilityStatus status;
  final String fallbackImageUrl;
  final Listenable? reconnectSignal;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nights = arrival.differenceInDays(departure);
    final effectiveNights = nights > 0 ? nights : 1;
    final nightlyRatePKR = (room.nightlyRateMinor / 100).round();
    final totalStayPKR = nightlyRatePKR * effectiveNights;

    final isCapacityMet = room.capacity >= partySize;
    final isEligible = isCapacityMet && status == RoomAvailabilityStatus.available;

    final primaryImageUrl = room.gallery.isNotEmpty
        ? room.gallery.first
        : fallbackImageUrl;

    final cardBorder = isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5);
    final cardBg = isDark ? const Color(0xFF18221C) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEligible
              ? cardBorder
              : (isDark ? const Color(0xFF332020) : const Color(0xFFF3E5E5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Room Image & Status Pill
          Stack(
            children: [
              HotelNetworkImage(
                imageUrl: primaryImageUrl,
                aspectRatio: 16 / 9,
                fit: BoxFit.cover,
                semanticLabel: '${room.type} room photo',
                reconnectSignal: reconnectSignal,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),

              // Status Pill in Top-Right
              Positioned(
                top: 10,
                right: 10,
                child: _buildStatusPill(isCapacityMet),
              ),

              // Room number pill in Top-Left
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Room ${room.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Room Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Type
                Text(
                  room.type,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (room.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    room.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Specs: Bed, Capacity, Amenities
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildSpecChip(
                      icon: Icons.bed_rounded,
                      label: room.bedDescription,
                      isDark: isDark,
                    ),
                    _buildSpecChip(
                      icon: Icons.person_outline_rounded,
                      label: 'Up to ${room.capacity} ${room.capacity == 1 ? "guest" : "guests"}',
                      isDark: isDark,
                    ),
                  ],
                ),

                if (room.amenities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: room.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222F26) : const Color(0xFFF1F6F3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF2D3748),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Pricing Row & Reserve Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Price calculation
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppMoneyFormat.formatPKR(nightlyRatePKR),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ night',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total: ${AppMoneyFormat.formatPKR(totalStayPKR)} for $effectiveNights ${effectiveNights == 1 ? "night" : "nights"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Reserve button
                    FilledButton(
                      onPressed: isEligible ? onSelect : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEligible ? 'Reserve Room' : 'Unavailable',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(bool isCapacityMet) {
    if (!isCapacityMet) {
      return _pillBadge(
        label: 'Fits max ${room.capacity} guests',
        color: const Color(0xFFFFA000),
        icon: Icons.info_outline_rounded,
      );
    }

    switch (status) {
      case RoomAvailabilityStatus.available:
        return _pillBadge(
          label: 'Available',
          color: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case RoomAvailabilityStatus.occupied:
        return _pillBadge(
          label: 'Occupied for dates',
          color: const Color(0xFFD32F2F),
          icon: Icons.block_rounded,
        );
      case RoomAvailabilityStatus.reserved:
        return _pillBadge(
          label: 'Reserved for dates',
          color: const Color(0xFFE65100),
          icon: Icons.event_busy_rounded,
        );
    }
  }

  Widget _pillBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : const Color(0xFF4A5568),
          ),
        ),
      ],
    );
  }
}
