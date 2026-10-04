import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/room.dart';
import '../../../shared/formatting/money.dart';
import 'room_detail_screen.dart';
import 'room_form_screen.dart';
import 'room_widgets.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({
    super.key,
    required this.controller,
    required this.themeController,
    this.requestedFilter,
    this.filterRequestKey = 0,
    this.scrollController,
  });

  final HotelController controller;
  final ThemeController themeController;
  final RoomStatus? requestedFilter;
  final int filterRequestKey;
  final ScrollController? scrollController;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _search = TextEditingController();
  RoomStatus? _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.requestedFilter;
  }

  @override
  void didUpdateWidget(covariant RoomsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterRequestKey != oldWidget.filterRequestKey) {
      _search.clear();
      _filter = widget.requestedFilter;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _search.clear();
    _filter = null;
  });

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomFormScreen(controller: widget.controller),
      ),
    );
    if (!mounted || saved != true) return;
    // A newly added room should be visible even after an occupied-only search.
    _reset();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Room added.')));
  }

  Future<void> _open(Room room) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoomDetailScreen(controller: widget.controller, roomId: room.id),
      ),
    );
    if (mounted && deleted == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Room deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final query = _search.text.trim().toLowerCase();
      final rooms =
          state.rooms
              .where(
                (room) =>
                    (query.isEmpty ||
                        room.number.toLowerCase().contains(query) ||
                        room.type.toLowerCase().contains(query)) &&
                    (_filter == null || state.roomStatus(room.id) == _filter),
              )
              .toList()
            ..sort((a, b) {
              // A single lexical ordering stays consistent for mixed identifiers.
              return a.number.toLowerCase().compareTo(b.number.toLowerCase());
            });
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
                key: const PageStorageKey('rooms-list'),
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
                                  'Rooms',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _add,
                                icon: const Icon(
                                  Icons.meeting_room_outlined,
                                  size: 18,
                                ),
                                label: const Text('Add Room'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage your rooms, rates, and current occupancy.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            decoration: InputDecoration(
                              hintText: 'Search room number or type',
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
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final item in <(RoomStatus?, String)>[
                                (null, 'All'),
                                (RoomStatus.available, 'Available'),
                                (RoomStatus.occupied, 'Occupied'),
                              ])
                                ChoiceChip(
                                  showCheckmark: false,
                                  selectedColor: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surface,
                                  shape: const StadiumBorder(),
                                  side: BorderSide(
                                    color: _filter == item.$1
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: _filter == item.$1
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        fontWeight: _filter == item.$1
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                  label: Text(item.$2),
                                  selected: _filter == item.$1,
                                  onSelected: (_) =>
                                      setState(() => _filter = item.$1),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '${rooms.length} ${rooms.length == 1 ? 'room' : 'rooms'}${query.isNotEmpty || _filter != null ? ' matching' : ' in your hotel'}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (rooms.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 16, padding, 48),
                      sliver: SliverToBoxAdapter(
                        child: _RoomEmpty(
                          firstUse: state.rooms.isEmpty,
                          onAction: state.rooms.isEmpty ? _add : _reset,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
                      sliver: SliverList.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RoomTile(
                              room: room,
                              status: state.roomStatus(room.id),
                              onTap: () => _open(room),
                            ),
                          );
                        },
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

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.status,
    required this.onTap,
  });

  final Room room;
  final RoomStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${room.number}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  room.type,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatPkr(room.nightlyRateMinor)} / night',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            // Keep long values and larger accessibility text out of tight rows.
            final wide =
                constraints.maxWidth >= 500 &&
                MediaQuery.textScalerOf(context).scale(14) <= 21;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 24),
                  RoomStatusBadge(status: status),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RoomStatusBadge(status: status),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                details,
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _RoomEmpty extends StatelessWidget {
  const _RoomEmpty({required this.firstUse, required this.onAction});

  final bool firstUse;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(
          firstUse ? Icons.bed_outlined : Icons.search_off,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          firstUse ? 'A place for every room' : 'No rooms match',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          firstUse
              ? 'Add your first room to start organizing your hotel.'
              : 'Try another room number or type, or reset your filters.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: onAction,
          child: Text(
            firstUse ? 'Add your first room' : 'Reset search and filters',
          ),
        ),
      ],
    ),
  );
}
