import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../domain/hotel_exception.dart';
import '../../../domain/models/room.dart';
import '../../../domain/models/stay_date.dart';
import '../../../shared/formatting/guest_details.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../guests/presentation/guest_form_screen.dart';
import '../../rooms/presentation/room_form_screen.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, required this.controller});

  final HotelController controller;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  late StayDate _arrivalDate;
  late StayDate _departureDate;
  String? _selectedRoomId;
  final Set<String> _selectedGuestIds = {};
  String? _primaryGuestId;

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _arrivalDate = StayDate(now.year, now.month, now.day);
    final tomorrow = now.add(const Duration(days: 1));
    _departureDate = StayDate(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  bool get _isDirty =>
      _selectedRoomId != null ||
      _selectedGuestIds.isNotEmpty ||
      _primaryGuestId != null;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty || _saving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard reservation?'),
        content: const Text(
          'You have unconfirmed booking details. If you leave now, your selections will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _pickArrivalDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(
      _arrivalDate.year,
      _arrivalDate.month,
      _arrivalDate.day,
    );
    final initial = current.isBefore(today) ? today : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null) return;

    final newArrival = StayDate.fromDateTime(picked);
    setState(() {
      _arrivalDate = newArrival;
      // Ensure departure is at least 1 day after arrival
      if (!_arrivalDate.isBefore(_departureDate)) {
        final nextDay = picked.add(const Duration(days: 1));
        _departureDate = StayDate.fromDateTime(nextDay);
      }
      _validateRoomAvailability();
    });
  }

  Future<void> _pickDepartureDate() async {
    final arrivalDt = DateTime(
      _arrivalDate.year,
      _arrivalDate.month,
      _arrivalDate.day,
    );
    final minDeparture = arrivalDt.add(const Duration(days: 1));
    final current = DateTime(
      _departureDate.year,
      _departureDate.month,
      _departureDate.day,
    );
    final initial = current.isBefore(minDeparture) ? minDeparture : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDeparture,
      lastDate: minDeparture.add(const Duration(days: 730)),
    );
    if (picked == null) return;

    setState(() {
      _departureDate = StayDate.fromDateTime(picked);
      _validateRoomAvailability();
    });
  }

  void _validateRoomAvailability() {
    if (_selectedRoomId == null) return;
    try {
      final available = widget.controller.availableRooms(
        _arrivalDate,
        _departureDate,
      );
      if (!available.any((r) => r.id == _selectedRoomId)) {
        _selectedRoomId = null;
      }
    } catch (_) {
      _selectedRoomId = null;
    }
  }

  Future<void> _submit() async {
    if (_saving) return;

    if (_selectedRoomId == null) {
      setState(() => _errorMessage = 'Please select an available room.');
      return;
    }
    if (_selectedGuestIds.isEmpty) {
      setState(
        () => _errorMessage = 'Please select at least one guest for this stay.',
      );
      return;
    }
    if (_primaryGuestId == null ||
        !_selectedGuestIds.contains(_primaryGuestId)) {
      setState(
        () => _errorMessage =
            'Please choose a primary guest from the selected guests.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.createBooking(
        roomId: _selectedRoomId!,
        guestIds: _selectedGuestIds.toList(),
        primaryGuestId: _primaryGuestId!,
        arrivalDate: _arrivalDate,
        departureDate: _departureDate,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on HotelException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'An unexpected error occurred while saving.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isDirty || _saving,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final shouldPop = await _confirmDiscard();
      if (shouldPop && context.mounted) {
        Navigator.pop(context);
      }
    },
    child: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        // Check prerequisites
        if (state.rooms.isEmpty || state.guests.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('New Reservation')),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Prerequisites Required',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.rooms.isEmpty && state.guests.isEmpty
                            ? 'You need at least one room and one registered guest before you can create a booking.'
                            : state.rooms.isEmpty
                            ? 'You must add at least one room before you can create a booking.'
                            : 'You must add at least one guest before you can create a booking.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          if (state.rooms.isEmpty)
                            FilledButton.tonal(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomFormScreen(
                                    controller: widget.controller,
                                  ),
                                ),
                              ),
                              child: const Text('Add Room'),
                            ),
                          if (state.guests.isEmpty)
                            FilledButton.tonal(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GuestFormScreen(
                                    controller: widget.controller,
                                  ),
                                ),
                              ),
                              child: const Text('Add Guest'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        List<Room> availableRooms = [];
        try {
          availableRooms = widget.controller.availableRooms(
            _arrivalDate,
            _departureDate,
          );
        } catch (_) {}

        final nights = _arrivalDate.nightsUntil(_departureDate);
        final selectedRoom = state.rooms.any((r) => r.id == _selectedRoomId)
            ? state.room(_selectedRoomId!)
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('New Reservation'),
            actions: [
              TextButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      AppNotice(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // Section 1: Dates
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1. Select Stay Dates',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _saving ? null : _pickArrivalDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Arrival Date',
                                        prefixIcon: const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(_arrivalDate.toString()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _saving ? null : _pickDepartureDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Departure Date',
                                        prefixIcon: const Icon(
                                          Icons.event,
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(_departureDate.toString()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Duration: $nights ${nights == 1 ? 'night' : 'nights'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Room Selection
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '2. Choose Room',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                                Text(
                                  '${availableRooms.length} available',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: availableRooms.isEmpty
                                        ? scheme.error
                                        : scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (availableRooms.isEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer.withAlpha(80),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: scheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No rooms available for the selected dates. Please adjust your dates.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: scheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (final room in availableRooms) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: _selectedRoomId == room.id
                                        ? scheme.primary.withAlpha(20)
                                        : scheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _selectedRoomId == room.id
                                            ? scheme.primary
                                            : scheme.outlineVariant,
                                        width: _selectedRoomId == room.id
                                            ? 1.5
                                            : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: _saving
                                          ? null
                                          : () => setState(
                                              () => _selectedRoomId = room.id,
                                            ),
                                      leading: Icon(
                                        _selectedRoomId == room.id
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: _selectedRoomId == room.id
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant,
                                      ),
                                      title: Text(
                                        'Room ${room.number} • ${room.type}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${formatPkr(room.nightlyRateMinor)} / night',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Guest Selection
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '3. Select Guests',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                                Text(
                                  '${_selectedGuestIds.length} selected',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select one or more guests and assign one as the primary guest.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final guest in state.guests) ...[
                              CheckboxListTile(
                                value: _selectedGuestIds.contains(guest.id),
                                onChanged: _saving
                                    ? null
                                    : (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedGuestIds.add(guest.id);
                                            // Auto-assign primary guest if first one selected
                                            _primaryGuestId ??= guest.id;
                                          } else {
                                            _selectedGuestIds.remove(guest.id);
                                            if (_primaryGuestId == guest.id) {
                                              _primaryGuestId =
                                                  _selectedGuestIds.isNotEmpty
                                                  ? _selectedGuestIds.first
                                                  : null;
                                            }
                                          }
                                        });
                                      },
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        guest.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (_primaryGuestId == guest.id) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.primary.withAlpha(30),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Primary',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${formatPhone(guest.phone)} • ${maskedCnic(guest.cnic)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                    if (_selectedGuestIds.contains(guest.id) &&
                                        _primaryGuestId != guest.id) ...[
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () {
                                          setState(
                                            () => _primaryGuestId = guest.id,
                                          );
                                        },
                                        child: Text(
                                          'Set as primary guest',
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Stay & Pricing Summary
                    if (selectedRoom != null) ...[
                      Card(
                        elevation: 0,
                        color: scheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stay Summary',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Room ${selectedRoom.number} (${selectedRoom.type})',
                                  ),
                                  Text(
                                    '${formatPkr(selectedRoom.nightlyRateMinor)} / night',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Duration ($nights ${nights == 1 ? 'night' : 'nights'})',
                                  ),
                                  Text(
                                    formatPkr(
                                      nights * selectedRoom.nightlyRateMinor,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Reservation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
