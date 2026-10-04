import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/guest.dart';
import '../../../domain/services/guest_search.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/widgets/empty_state_view.dart';
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
      final guests = searchGuests(widget.controller.state.guests, _search.text);
      final firstUse = widget.controller.state.guests.isEmpty;
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: scheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: scheme.outlineVariant),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _open(guest),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
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
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              formatPhone(guest.phone),
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'CNIC ${maskedCnic(guest.cnic)}',
                                              semanticsLabel:
                                                  'CNIC ending ${guest.cnic.substring(9)}; open profile for full details',
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.chevron_right,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
