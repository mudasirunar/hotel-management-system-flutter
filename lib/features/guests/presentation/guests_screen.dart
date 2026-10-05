import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/booking.dart';
import '../../../domain/models/guest.dart';
import '../../../domain/models/room.dart';
import '../../../domain/services/guest_search.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../bookings/presentation/booking_widgets.dart';
import 'guest_detail_screen.dart';
import 'guest_form_screen.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({
    super.key,
    required this.controller,
    required this.themeController,
    this.scrollController,
  });

  final HotelController controller;
  final ThemeController themeController;
  final ScrollController? scrollController;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GuestFormScreen(controller: widget.controller),
      ),
    );
    if (!mounted || saved != true) return;
    setState(_search.clear);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Guest added.')));
  }

  Future<void> _open(Guest guest) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GuestDetailScreen(controller: widget.controller, guestId: guest.id),
      ),
    );
    if (mounted && deleted == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Guest deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final guests = searchGuests(state.guests, _search.text);
      final firstUse = state.guests.isEmpty;
      final scheme = Theme.of(context).colorScheme;
      return LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 600 ? 16.0 : 32.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                primary: false,
                controller: widget.scrollController,
                key: const PageStorageKey('guests-list'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 20, padding, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Guests',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _add,
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('Add Guest'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Guest details, ready when you need them.',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            autocorrect: false,
                            onSubmitted: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            decoration: InputDecoration(
                              hintText: 'Search name, phone, or CNIC',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(_search.clear),
                                    ),
                            ),
                          ),
                          if (guests.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              '${guests.length} ${guests.length == 1 ? 'guest' : 'guests'}${_search.text.trim().isEmpty ? ' in your records' : ' matching'}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (guests.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 8, padding, 48),
                      sliver: SliverToBoxAdapter(
                        child: firstUse
                            ? EmptyStateView(
                                icon: Icons.people_outline_rounded,
                                title: 'Welcome your first guest',
                                message: 'Add a guest profile to keep their contact details, CNIC, and booking history organized.',
                                actionLabel: 'Add your first guest',
                                actionIcon: Icons.person_add_outlined,
                                onAction: _add,
                              )
                            : EmptyStateView(
                                icon: Icons.person_search_outlined,
                                title:
                                    'No guests found for "${_search.text.trim()}"',
                                message:
                                    'We couldn\'t find any guest profiles matching "${_search.text.trim()}". Check for typos or search by phone or CNIC.',
                                actionLabel: 'Clear search',
                                actionIcon: Icons.clear_rounded,
                                onAction: () => setState(_search.clear),
                              ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
                      sliver: SliverList.builder(
                        itemCount: guests.length,
                        itemBuilder: (context, index) {
                          final guest = guests[index];
                          final guestBookings = state.bookings
                              .where((b) => b.guestIds.contains(guest.id))
                              .toList();

                          Booking? activeBooking;
                          final checkedIn = guestBookings.where(
                            (b) => b.status == BookingStatus.checkedIn,
                          );
                          if (checkedIn.isNotEmpty) {
                            activeBooking = checkedIn.first;
                          } else {
                            final reserved = guestBookings.where(
                              (b) => b.status == BookingStatus.reserved,
                            );
                            if (reserved.isNotEmpty) {
                              final sorted = reserved.toList()
                                ..sort(
                                  (a, b) => a.arrivalDate.compareTo(b.arrivalDate),
                                );
                              activeBooking = sorted.first;
                            }
                          }

                          Room? assignedRoom;
                          if (activeBooking != null) {
                            final matchingRooms = state.rooms.where(
                              (r) => r.id == activeBooking!.roomId,
                            );
                            if (matchingRooms.isNotEmpty) {
                              assignedRoom = matchingRooms.first;
                            }
                          }

                          final dark =
                              Theme.of(context).brightness == Brightness.dark;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: scheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: scheme.outlineVariant),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _open(guest),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor:
                                                scheme.primaryContainer,
                                            child: Text(
                                              _getInitials(guest.name),
                                              style: TextStyle(
                                                color:
                                                    scheme.onPrimaryContainer,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  guest.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  formatPhone(guest.phone),
                                                  style: TextStyle(
                                                    color: scheme
                                                        .onSurfaceVariant,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (activeBooking != null) ...[
                                            BookingStatusBadge(
                                              status: activeBooking.status,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Icon(
                                            Icons.chevron_right,
                                            color: scheme.onSurfaceVariant
                                                .withAlpha(150),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.badge_outlined,
                                            size: 14,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'CNIC ${maskedCnic(guest.cnic)}',
                                            semanticsLabel:
                                                'CNIC ending ${guest.cnic.substring(9)}; open profile for full details',
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (guest.address.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                guest.address,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: scheme.onSurfaceVariant,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (activeBooking != null) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: activeBooking.status ==
                                                    BookingStatus.checkedIn
                                                ? (dark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFEFF6FF))
                                                : (dark
                                                    ? const Color(0xFF452205)
                                                    : const Color(0xFFFEF3C7)),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: activeBooking.status ==
                                                      BookingStatus.checkedIn
                                                  ? (dark
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFFBFDBFE))
                                                  : (dark
                                                      ? const Color(0xFFD97706)
                                                      : const Color(0xFFFDE68A)),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                activeBooking.status ==
                                                        BookingStatus.checkedIn
                                                    ? Icons.hotel_rounded
                                                    : Icons
                                                        .event_available_rounded,
                                                size: 14,
                                                color: activeBooking.status ==
                                                        BookingStatus.checkedIn
                                                    ? (dark
                                                        ? const Color(0xFF93C5FD)
                                                        : const Color(0xFF1E3A8A))
                                                    : (dark
                                                        ? const Color(0xFFFDE68A)
                                                        : const Color(0xFF92400E)),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  activeBooking.status ==
                                                          BookingStatus.checkedIn
                                                      ? 'Room ${assignedRoom?.number ?? activeBooking.roomId} • Currently In-House (until ${activeBooking.departureDate})'
                                                      : 'Room ${assignedRoom?.number ?? activeBooking.roomId} • Reserved (Arriving ${activeBooking.arrivalDate})',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: activeBooking.status ==
                                                            BookingStatus.checkedIn
                                                        ? (dark
                                                            ? const Color(
                                                                0xFF93C5FD,
                                                             )
                                                            : const Color(
                                                                0xFF1E3A8A,
                                                              ))
                                                        : (dark
                                                            ? const Color(
                                                                0xFFFDE68A,
                                                              )
                                                            : const Color(
                                                                0xFF92400E,
                                                              )),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Bottom spacer so content scrolls clear of floating bottom bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _getInitials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'G';
  if (parts.length == 1) {
    return parts[0].substring(0, 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

