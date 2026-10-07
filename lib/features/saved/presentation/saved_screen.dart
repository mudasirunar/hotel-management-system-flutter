import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../application/location_controller.dart';
import '../../../domain/models/hotel.dart';
import '../../../domain/services/connectivity_service.dart';
import '../../explore/presentation/widgets/hotel_card.dart';

/// Screen displaying the traveler's locally saved/favorited hotels.
class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.customerController,
    required this.locationController,
    this.connectivityService,
    this.onSelectHotel,
    this.onNavigateToExplore,
  });

  final CustomerController customerController;
  final LocationController locationController;
  final ConnectivityService? connectivityService;
  final ValueChanged<Hotel>? onSelectHotel;
  final VoidCallback? onNavigateToExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: customerController,
      builder: (context, _) {
        final catalog = customerController.catalog;
        final savedIds = customerController.state.savedHotelIds;

        final savedHotels = catalog.hotels
            .where((hotel) => savedIds.contains(hotel.id))
            .toList();

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Stays',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          savedHotels.isEmpty
                              ? 'Your favorite accommodations'
                              : '${savedHotels.length} ${savedHotels.length == 1 ? "stay" : "stays"} saved locally',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Saved list or empty state
                if (savedHotels.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                size: 44,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No saved stays yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the heart icon on any hotel card in Explore to save places you want to remember.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (onNavigateToExplore != null) ...[
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: onNavigateToExplore,
                                icon: const Icon(Icons.explore_outlined, size: 18),
                                label: const Text('Explore Hotels'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hotel = savedHotels[index];
                        final distanceText =
                            locationController.formatDistanceToHotel(hotel);

                        // Calculate lowest rate from catalog rooms
                        int? lowestRate;
                        for (final r in hotel.rooms) {
                          final rate = (r.nightlyRateMinor / 100).round();
                          if (lowestRate == null || rate < lowestRate) {
                            lowestRate = rate;
                          }
                        }

                        return HotelCard(
                          hotel: hotel,
                          lowestNightlyRatePKR: lowestRate,
                          distanceText: distanceText,
                          isSaved: true,
                          reconnectSignal: connectivityService?.reconnectTick,
                          onToggleSaved: () =>
                              customerController.toggleSavedHotel(hotel.id),
                          onTap: () => onSelectHotel?.call(hotel),
                        );
                      },
                      childCount: savedHotels.length,
                    ),
                  ),

                // Bottom padding
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
}
