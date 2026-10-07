import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../application/location_controller.dart';
import '../../../domain/models/hotel.dart';
import '../../../domain/services/connectivity_service.dart';
import '../../../domain/services/hotel_search_service.dart';
import '../../../shared/widgets/offline_banner.dart';
import 'widgets/dates_and_guests_bar.dart';
import 'widgets/explore_search_bar.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/hotel_card.dart';
import 'widgets/stay_dates_and_guests_sheet.dart';

/// Primary customer hotel discovery and exploration screen.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.customerController,
    required this.locationController,
    this.connectivityService,
    this.searchService = const HotelSearchService(),
    this.onSelectHotel,
  });

  final CustomerController customerController;
  final LocationController locationController;
  final ConnectivityService? connectivityService;
  final HotelSearchService searchService;
  final ValueChanged<Hotel>? onSelectHotel;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late HotelFilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    final anchor = widget.customerController.state.anchorDate;
    final arrival = anchor;
    final departure = anchor.addDays(1);

    _criteria = HotelFilterCriteria(
      arrival: arrival,
      departure: departure,
      city: widget.customerController.state.selectedCity,
      partySize: 1,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _criteria = _criteria.copyWith(query: query);
    });
  }

  void _onClearSearch() {
    _searchCtrl.clear();
    setState(() {
      _criteria = _criteria.copyWith(query: '');
    });
  }

  void _openDatesAndGuestsSheet() {
    StayDatesAndGuestsSheet.show(
      context: context,
      arrival: _criteria.arrival,
      departure: _criteria.departure,
      partySize: _criteria.partySize,
      onConfirm: (arrival, departure, partySize) {
        setState(() {
          _criteria = _criteria.copyWith(
            arrival: arrival,
            departure: departure,
            partySize: partySize,
          );
        });
      },
    );
  }

  void _openFilterSheet() {
    FilterBottomSheet.show(
      context: context,
      criteria: _criteria,
      onApply: (newCriteria) {
        setState(() {
          _criteria = newCriteria;
        });
        if (newCriteria.city != null && newCriteria.city != 'All Cities') {
          widget.locationController.selectCity(newCriteria.city!);
        }
      },
    );
  }

  void _selectSort(HotelSortOption sort) {
    setState(() {
      _criteria = _criteria.copyWith(sortOption: sort);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.customerController,
        widget.locationController,
      ]),
      builder: (context, _) {
        final catalog = widget.customerController.catalog;
        final savedIds = widget.customerController.state.savedHotelIds;
        final origin = widget.locationController.currentOrigin;

        // Perform search/filtering
        final searchResults = widget.searchService.searchHotels(
          catalog: catalog,
          userBookings: widget.customerController.state.bookings,
          criteria: _criteria,
          origin: origin,
        );

        final isOffline = widget.connectivityService?.isOffline ?? false;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // 1. Discovery Header & Destination Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find your stay',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.locationController.getOriginDescription(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // "Use my location" button
                        TextButton.icon(
                          onPressed: () =>
                              widget.locationController.requestDeviceLocation(),
                          icon: Icon(
                            widget.locationController.isDeviceLocation
                                ? Icons.my_location
                                : Icons.location_searching_rounded,
                            size: 16,
                          ),
                          label: Text(
                            widget.locationController.isDeviceLocation
                                ? 'GPS Active'
                                : 'Near me',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Offline Notice Banner if offline
                if (isOffline)
                  SliverToBoxAdapter(
                    child: OfflineBanner(
                      onRetry: () =>
                          widget.connectivityService?.checkConnectivity(),
                    ),
                  ),

                // 3. Search Bar
                SliverToBoxAdapter(
                  child: ExploreSearchBar(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    onClear: _onClearSearch,
                    onFilterTap: _openFilterSheet,
                    hasActiveFilters: _criteria.hasActiveFilters,
                  ),
                ),

                // 4. Dates & Guests Selector Bar
                SliverToBoxAdapter(
                  child: DatesAndGuestsBar(
                    arrival: _criteria.arrival,
                    departure: _criteria.departure,
                    partySize: _criteria.partySize,
                    onTap: _openDatesAndGuestsSheet,
                  ),
                ),

                // 5. Sort Chips Row
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _buildSortChip('Recommended', HotelSortOption.recommended),
                        const SizedBox(width: 8),
                        _buildSortChip('Price: Low to High', HotelSortOption.priceLowToHigh),
                        const SizedBox(width: 8),
                        _buildSortChip('Rating: High to Low', HotelSortOption.ratingHighToLow),
                        if (widget.locationController.hasOrigin) ...[
                          const SizedBox(width: 8),
                          _buildSortChip('Nearest', HotelSortOption.nearest),
                        ],
                      ],
                    ),
                  ),
                ),

                // 6. Results count header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${searchResults.length} ${searchResults.length == 1 ? "stay" : "stays"} available',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_criteria.hasActiveFilters)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {
                                _criteria = _criteria.copyWith(
                                  query: '',
                                  clearCity: true,
                                  clearMaxPrice: true,
                                  clearMinRating: true,
                                  requiredAmenities: const {},
                                  onlyAvailableRooms: false,
                                );
                              });
                            },
                            child: Text(
                              'Clear filters',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 7. Hotel Cards Feed or Empty State
                if (searchResults.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(theme, isDark),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final result = searchResults[index];
                        final hotel = result.hotel;
                        final isSaved = savedIds.contains(hotel.id);
                        final distanceText = result.distanceKm != null
                            ? widget.locationController.formatDistanceToHotel(hotel)
                            : null;

                        return HotelCard(
                          hotel: hotel,
                          lowestNightlyRatePKR: result.lowestNightlyRatePKR,
                          distanceText: distanceText,
                          isSaved: isSaved,
                          reconnectSignal: widget.connectivityService?.reconnectTick,
                          onToggleSaved: () =>
                              widget.customerController.toggleSavedHotel(hotel.id),
                          onTap: () => widget.onSelectHotel?.call(hotel),
                        );
                      },
                      childCount: searchResults.length,
                    ),
                  ),

                // Bottom padding spacer
                const SliverToBoxAdapter(
                  child: SizedBox(height: 132),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortChip(String label, HotelSortOption sort) {
    final isSelected = _criteria.sortOption == sort;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _selectSort(sort);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No stays match your search',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your city filter, budget, or dates to find available rooms.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _criteria = _criteria.copyWith(
                    query: '',
                    clearCity: true,
                    clearMaxPrice: true,
                    clearMinRating: true,
                    requiredAmenities: const {},
                    onlyAvailableRooms: false,
                  );
                });
              },
              child: const Text('Reset search & filters'),
            ),
          ],
        ),
      ),
    );
  }
}
