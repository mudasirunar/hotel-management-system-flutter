import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../application/theme_controller.dart';
import '../../../domain/models/guest.dart';
import '../../../domain/services/guest_search.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../settings/presentation/appearance_screen.dart';
import 'guest_detail_screen.dart';
import 'guest_form_screen.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final HotelController controller;
  final ThemeController themeController;

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
                key: const PageStorageKey('guests-list'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 24, padding, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'HOTEL MANAGEMENT',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        letterSpacing: 1.5,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Appearance settings',
                                icon: const Icon(Icons.brightness_6_outlined),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AppearanceScreen(
                                      controller: widget.themeController,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 24,
                            runSpacing: 16,
                            children: [
                              Text(
                                'Guests',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              FilledButton.icon(
                                onPressed: _add,
                                icon: const Icon(
                                  Icons.person_add_alt_1_outlined,
                                  size: 20,
                                ),
                                label: const Text('Add guest'),
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
                          const SizedBox(height: 24),
                          Text(
                            '${guests.length} ${guests.length == 1 ? 'guest' : 'guests'}${_search.text.trim().isEmpty ? ' in your records' : ' matching'}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (guests.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 40, padding, 48),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Icon(
                              firstUse
                                  ? Icons.people_outline
                                  : Icons.search_off,
                              size: 40,
                              color: scheme.primary,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              firstUse
                                  ? 'Welcome your first guest'
                                  : 'No guests match',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              firstUse
                                  ? 'Add a guest profile to keep their details organized.'
                                  : 'Try another name, phone number, or CNIC.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton(
                              onPressed: firstUse
                                  ? _add
                                  : () => setState(_search.clear),
                              child: Text(
                                firstUse
                                    ? 'Add your first guest'
                                    : 'Clear search',
                              ),
                            ),
                          ],
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
