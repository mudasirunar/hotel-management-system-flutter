import 'package:flutter/material.dart';

import '../../../application/customer_controller.dart';
import '../../../domain/models/customer_booking.dart';
import '../../../shared/formatting/app_money_format.dart';

/// Screen displaying the traveler's personal reservations.
class CustomerBookingsScreen extends StatelessWidget {
  const CustomerBookingsScreen({
    super.key,
    required this.customerController,
    this.onNavigateToExplore,
  });

  final CustomerController customerController;
  final VoidCallback? onNavigateToExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: customerController,
      builder: (context, _) {
        final bookings = customerController.state.bookings;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Bookings',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bookings.isEmpty
                            ? 'Your reserved stays and trips'
                            : '${bookings.length} ${bookings.length == 1 ? "booking" : "bookings"} recorded locally',
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

                if (bookings.isEmpty)
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
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                size: 44,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No bookings yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Discover hotels in Karachi, Lahore, Islamabad, or Murree and reserve your room.',
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
                                label: const Text('Find a Stay'),
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
                        final booking = bookings[index];
                        return _buildBookingCard(context, booking, theme, isDark);
                      },
                      childCount: bookings.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    CustomerBooking booking,
    ThemeData theme,
    bool isDark,
  ) {
    final cardBorder = isDark ? const Color(0xFF2B3830) : const Color(0xFFE2EBE5);
    final cardBg = isDark ? const Color(0xFF18201B) : Colors.white;

    final isCancelled = booking.isCancelled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ref: #${booking.id}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? (isDark ? const Color(0xFF3B1D1D) : const Color(0xFFFEE2E2))
                      : (isDark ? const Color(0xFF183324) : const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCancelled ? 'Cancelled' : 'Confirmed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCancelled
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.hotelName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${booking.roomType} • Room ${booking.roomNumber}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '${booking.arrivalDate.format()} → ${booking.departureDate.format()} (${booking.nights} ${booking.nights == 1 ? "night" : "nights"})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${AppMoneyFormat.formatPKRFromMinor(booking.totalAmountMinor)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (!isCancelled)
                TextButton(
                  onPressed: () => customerController.cancelBooking(booking.id),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Cancel stay'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
