import 'package:flutter/material.dart';

import '../../../application/hotel_controller.dart';
import '../../../domain/hotel_exception.dart';
import '../../../domain/models/room.dart';
import '../../../domain/services/input_validation.dart';
import '../../../shared/formatting/money.dart';
import 'room_widgets.dart';

class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({super.key, required this.controller, this.room});

  final HotelController controller;
  final Room? room;

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _form = GlobalKey<FormState>();
  final _numberKey = GlobalKey<FormFieldState<String>>();
  final _typeKey = GlobalKey<FormFieldState<String>>();
  final _priceKey = GlobalKey<FormFieldState<String>>();
  final _numberFocus = FocusNode();
  final _typeFocus = FocusNode();
  final _priceFocus = FocusNode();
  late final TextEditingController _number;
  late final TextEditingController _type;
  late final TextEditingController _price;
  late final List<String> _original;
  late List<String> _lastValues;
  bool _dirty = false;
  bool _saving = false;
  bool _leaving = false;
  bool _submitted = false;
  HotelException? _error;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _number = TextEditingController(text: room?.number ?? '');
    _type = TextEditingController(text: room?.type ?? '');
    _price = TextEditingController(
      text: room == null ? '' : priceInput(room.nightlyRateMinor),
    );
    _original = [_number.text, _type.text, _price.text];
    _lastValues = List.of(_original);
    for (final controller in [_number, _type, _price]) {
      controller.addListener(_changed);
    }
  }

  void _changed() {
    final values = [_number.text, _type.text, _price.text];
    if (values[0] == _lastValues[0] &&
        values[1] == _lastValues[1] &&
        values[2] == _lastValues[2]) {
      return;
    }
    _lastValues = values;
    setState(() {
      _dirty = List.generate(
        3,
        (i) => values[i] != _original[i],
      ).any((changed) => changed);
      _error = null;
    });
  }

  @override
  void dispose() {
    for (final controller in [_number, _type, _price]) {
      controller.dispose();
    }
    for (final focus in [_numberFocus, _typeFocus, _priceFocus]) {
      focus.dispose();
    }
    super.dispose();
  }

  String? _validate(String field, Object Function() validate) {
    try {
      validate();
      return _error?.field == field ? _error!.message : null;
    } on HotelException catch (error) {
      return error.message;
    }
  }

  void _focusInvalid() {
    for (final entry in [
      (_numberKey, _numberFocus),
      (_typeKey, _typeFocus),
      (_priceKey, _priceFocus),
    ]) {
      if (entry.$1.currentState?.hasError ?? false) {
        entry.$2.requestFocus();
        final context = entry.$1.currentContext;
        if (context != null) Scrollable.ensureVisible(context, alignment: 0.2);
        return;
      }
    }
  }

  Future<void> _pop([bool? saved]) async {
    setState(() {
      _dirty = false;
      _saving = false;
    });
    // Let PopScope update before popping a formerly dirty form.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _leave() async {
    if (_saving || _leaving) return;
    _leaving = true;
    final discard =
        !_dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard changes?'),
                content: const Text('Your unsaved room details will be lost.'),
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
            ) ==
            true;
    if (!mounted) return;
    if (discard) {
      await _pop();
    } else {
      _leaving = false;
    }
  }

  Future<void> _save() async {
    if (_saving || _leaving) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) {
      _focusInvalid();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      await widget.controller.saveRoom(
        id: widget.room?.id,
        number: _number.text,
        type: _type.text,
        nightlyRateMinor: InputValidation.price(_price.text),
      );
      if (mounted) await _pop(true);
    } on HotelException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error;
      });
      _form.currentState!.validate();
      _focusInvalid();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.room != null;
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _saving ? null : _leave,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          title: Text(editing ? 'Edit room' : 'Add room'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Form(
                  key: _form,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Room information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        editing
                            ? 'Update the details your team uses every day.'
                            : 'Add a room to your hotel inventory.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        key: _numberKey,
                        controller: _number,
                        focusNode: _numberFocus,
                        enabled: !_saving,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Room number',
                          hintText: 'e.g. 101 or A-12',
                        ),
                        validator: (value) => _validate(
                          'number',
                          () => InputValidation.roomNumber(value ?? ''),
                        ),
                        onFieldSubmitted: (_) => _typeFocus.requestFocus(),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: _typeKey,
                        controller: _type,
                        focusNode: _typeFocus,
                        enabled: !_saving,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Room type',
                          hintText: 'e.g. Single, Double, or Suite',
                        ),
                        validator: (value) => _validate(
                          'type',
                          () => InputValidation.roomType(value ?? ''),
                        ),
                        onFieldSubmitted: (_) => _priceFocus.requestFocus(),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: _priceKey,
                        controller: _price,
                        focusNode: _priceFocus,
                        enabled: !_saving,
                        textInputAction: TextInputAction.done,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nightly price (PKR)',
                          hintText: 'e.g. 8500.00',
                          helperText: 'Price for one room, per night.',
                        ),
                        validator: (value) => _validate(
                          'price',
                          () => InputValidation.price(value ?? ''),
                        ),
                        onFieldSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 24),
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          final exists =
                              editing &&
                              widget.controller.state.rooms.any(
                                (r) => r.id == widget.room!.id,
                              );
                          final status = exists
                              ? widget.controller.state.roomStatus(
                                  widget.room!.id,
                                )
                              : RoomStatus.available;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current status',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              RoomStatusBadge(status: status),
                              const SizedBox(height: 12),
                              const Text(
                                'Occupancy updates automatically through check-in and check-out.',
                              ),
                            ],
                          );
                        },
                      ),
                      if (_error != null && _error!.field == null) ...[
                        const SizedBox(height: 24),
                        RoomNotice(message: _error!.message, isError: true),
                      ],
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Saving room',
                                ),
                              )
                            : const Icon(Icons.check, size: 20),
                        label: Text(
                          _saving
                              ? 'Saving…'
                              : _error?.field == null && _error != null
                              ? 'Retry save'
                              : editing
                              ? 'Save changes'
                              : 'Save room',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _saving ? null : _leave,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
