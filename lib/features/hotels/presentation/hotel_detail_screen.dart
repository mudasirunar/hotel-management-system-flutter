import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../application/location_controller.dart';
import '../../../domain/models/hotel.dart';
import '../../../domain/models/hotel_room.dart';
import '../../../domain/models/stay_date.dart';
import '../../../domain/services/connectivity_service.dart';
import '../../../domain/services/customer_availability_service.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../explore/presentation/widgets/dates_and_guests_bar.dart';
import '../../explore/presentation/widgets/stay_dates_and_guests_sheet.dart';
import 'widgets/hotel_amenities_grid.dart';
import 'widgets/hotel_gallery_carousel.dart';
import 'widgets/room_card.dart';

/// Detailed hotel presentation screen with photo carousel, amenities, policies,
/// date/guest modification, and room selection with real-time availability checks.
class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({
    super.key,
    required this.hotel,
    required this.customerController,
    required this.locationController,
    this.connectivityService,
    this.initialArrival,
    this.initialDeparture,
    this.initialPartySize = 1,
    this.onProceedToBooking,
  });

  final Hotel hotel;
  final CustomerController customerController;
  final LocationController locationController;
  final ConnectivityService? connectivityService;
  final StayDate? initialArrival;
  final StayDate? initialDeparture;
  final int initialPartySize;
  final void Function(
    Hotel hotel,
    HotelRoom room,
    StayDate arrival,
    StayDate departure,
    int partySize,
  )? onProceedToBooking;

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late StayDate _arrival;
  late StayDate _departure;
  late int _partySize;
  bool _onlyAvailable = false;

  @override
  void initState() {
    super.initState();
    final anchor = widget.customerController.state.anchorDate;
    _arrival = widget.initialArrival ?? anchor;
    _departure = widget.initialDeparture ?? anchor.addDays(1);
    _partySize = widget.initialPartySize > 0 ? widget.initialPartySize : 1;
  }

  void _openDatesAndGuestsSheet() {
    StayDatesAndGuestsSheet.show(
      context: context,
      arrival: _arrival,
      departure: _departure,
      partySize: _partySize,
      onConfirm: (arrival, departure, partySize) {
        setState(() {
          _arrival = arrival;
          _departure = departure;
          _partySize = partySize;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hotel = widget.hotel;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.customerController,
        widget.locationController,
      ]),
      builder: (context, _) {
        final isSaved = widget.customerController.state.savedHotelIds.contains(hotel.id);
        final isOffline = widget.connectivityService?.isOffline ?? false;
        final distanceText = widget.locationController.hasOrigin
            ? widget.locationController.formatDistanceToHotel(hotel)
            : null;

        // Compute room statuses for current dates
        final roomStatuses = <String, RoomAvailabilityStatus>{};
        var availableCount = 0;

        for (final room in hotel.rooms) {
          final status = widget.customerController.checkRoomStatus(
            room: room,
            arrival: _arrival,
            departure: _departure,
          );
          roomStatuses[room.id] = status;
          if (status == RoomAvailabilityStatus.available && room.capacity >= _partySize) {
            availableCount++;
          }
        }

        final visibleRooms = _onlyAvailable
            ? hotel.rooms.where((r) =>
                roomStatuses[r.id] == RoomAvailabilityStatus.available &&
                r.capacity >= _partySize).toList()
            : hotel.rooms;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // 1. App Bar with Gallery Carousel
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? const Color(0xFF0F1712) : Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          color: isSaved ? const Color(0xFFE53935) : Colors.white,
                          size: 20,
                        ),
                        onPressed: () =>
                            widget.customerController.toggleSavedHotel(hotel.id),
                        tooltip: isSaved ? 'Remove from saved' : 'Save hotel',
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: HotelGalleryCarousel(
                    hotelId: hotel.id,
                    images: hotel.gallery,
                    aspectRatio: 16 / 10,
                    reconnectSignal: widget.connectivityService?.reconnectTick,
                  ),
                ),
              ),

              // 2. Offline Notice
              if (isOffline)
                SliverToBoxAdapter(
                  child: OfflineBanner(
                    onRetry: () => widget.connectivityService?.checkConnectivity(),
                  ),
                ),

              // 3. Hotel Header Information
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating & Distance Pill Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF26332A) : const Color(0xFFEAF5EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107)),
                                const SizedBox(width: 4),
                                Text(
                                  hotel.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1B4D3E),
                                  ),
                                ),
                                Text(
                                  ' (${hotel.reviewCount} reviews)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : const Color(0xFF4A5568),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (distanceText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F6F3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.navigation_rounded,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    distanceText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF2D3748),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Hotel Name
                      Text(
                        hotel.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Address / Area
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${hotel.area}, ${hotel.city} • ${hotel.address}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 24),
                ),
              ),

              // 4. Dates & Guests Selector Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: DatesAndGuestsBar(
                    arrival: _arrival,
                    departure: _departure,
                    partySize: _partySize,
                    onTap: _openDatesAndGuestsSheet,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 24),
                ),
              ),

              // 5. Amenities Section
              if (hotel.amenities.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Amenities',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        HotelAmenitiesGrid(amenities: hotel.amenities),
                      ],
                    ),
                  ),
                ),

              if (hotel.amenities.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Divider(height: 24),
                  ),
                ),

              // 6. About Section
              if (hotel.description.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this property',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hotel.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (hotel.description.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Divider(height: 24),
                  ),
                ),

              // 7. Rooms Section Header & Availability Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Room',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$availableCount of ${hotel.rooms.length} rooms available',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      // Filter chip: Available Only
                      FilterChip(
                        label: const Text('Available only', style: TextStyle(fontSize: 12)),
                        selected: _onlyAvailable,
                        onSelected: (val) {
                          setState(() {
                            _onlyAvailable = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 8. Room Cards List
              if (visibleRooms.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 40, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'No rooms match your filter',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try changing your dates or toggle off "Available only" to view all room options.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final room = visibleRooms[index];
                      final status = roomStatuses[room.id] ?? RoomAvailabilityStatus.available;

                      return RoomCard(
                        room: room,
                        arrival: _arrival,
                        departure: _departure,
                        partySize: _partySize,
                        status: status,
                        fallbackImageUrl: hotel.gallery.isNotEmpty ? hotel.gallery.first : '',
                        reconnectSignal: widget.connectivityService?.reconnectTick,
                        onSelect: () {
                          widget.onProceedToBooking?.call(
                            hotel,
                            room,
                            _arrival,
                            _departure,
                            _partySize,
                          );
                        },
                      );
                    },
                    childCount: visibleRooms.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 32),
                ),
              ),

              // 9. Hotel Policies Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F6F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B3A30) : const Color(0xFFE2EBE5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.policy_outlined, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Hotel Policies',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Check-in', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'From ${hotel.checkInTime}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Check-out', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Until ${hotel.checkOutTime}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hotel.cancellationPolicy,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: 60),
              ),
            ],
          ),
        );
      },
    );
  }
}
