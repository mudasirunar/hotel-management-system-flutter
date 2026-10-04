import 'package:flutter/material.dart';

import '../../domain/hotel_exception.dart';
import 'app_notice.dart';

/// Shared form behavior for room and guest records. Domain validation and saving
/// remain supplied by the feature; this widget only manages editing and feedback.
class RecordField {
  const RecordField({
    required this.id,
    required this.label,
    required this.validate,
    this.initialValue = '',
    this.hint,
    this.helper,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.lines = 1,
  });

  final String id;
  final String label;
  final String initialValue;
  final String? hint;
  final String? helper;
  final Object Function(String) validate;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final int lines;
}

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({
    super.key,
    required this.title,
    required this.description,
    required this.fields,
    required this.onSave,
    required this.saveLabel,
    this.footer,
  });

  final String title;
  final String description;
  final List<RecordField> fields;
  final Future<void> Function(Map<String, String>) onSave;
  final String saveLabel;
  final Widget? footer;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _inputs;
  late final List<FocusNode> _focus;
  late final List<GlobalKey<FormFieldState<String>>> _keys;
  bool _saving = false;
  bool _leaving = false;
  bool _allowPop = false;
  bool _submitted = false;
  HotelException? _error;

  bool get _dirty => widget.fields.indexed.any(
    (entry) => entry.$2.initialValue != _inputs[entry.$1].text,
  );

  @override
  void initState() {
    super.initState();
    _inputs = [
      for (final field in widget.fields)
        TextEditingController(text: field.initialValue),
    ];
    _focus = [for (final _ in widget.fields) FocusNode()];
    _keys = [
      for (final _ in widget.fields) GlobalKey<FormFieldState<String>>(),
    ];
  }

  @override
  void dispose() {
    for (final input in _inputs) {
      input.dispose();
    }
    for (final focus in _focus) {
      focus.dispose();
    }
    super.dispose();
  }

  void _focusInvalid() {
    for (var i = 0; i < _keys.length; i++) {
      if (_keys[i].currentState?.hasError ?? false) {
        _focus[i].requestFocus();
        final fieldContext = _keys[i].currentContext;
        if (fieldContext != null) {
          Scrollable.ensureVisible(fieldContext, alignment: 0.2);
        }
        return;
      }
    }
  }

  Future<void> _pop([bool? saved]) async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, saved);
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
                content: const Text('Your unsaved changes will be lost.'),
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
    if (_saving || _leaving || _allowPop) return;
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
      await widget.onSave({
        for (var i = 0; i < widget.fields.length; i++)
          widget.fields[i].id: _inputs[i].text,
      });
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
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          onPressed: _saving ? null : _leave,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
        ),
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
                      widget.description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    for (final entry in widget.fields.indexed) ...[
                      TextFormField(
                        key: _keys[entry.$1],
                        controller: _inputs[entry.$1],
                        focusNode: _focus[entry.$1],
                        enabled: !_saving && !_allowPop,
                        keyboardType: entry.$2.keyboardType,
                        textCapitalization: entry.$2.capitalization,
                        minLines: entry.$2.lines,
                        maxLines: entry.$2.lines == 1 ? 1 : 6,
                        autocorrect: false,
                        textInputAction: entry.$2.lines > 1
                            ? TextInputAction.newline
                            : entry.$1 == widget.fields.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: entry.$2.label,
                          hintText: entry.$2.hint,
                          helperText: entry.$2.helper,
                          helperMaxLines: 3,
                          alignLabelWithHint: entry.$2.lines > 1,
                        ),
                        onChanged: (_) => setState(() {
                          if (_error?.field == null ||
                              _error?.field == entry.$2.id) {
                            _error = null;
                          }
                        }),
                        validator: (value) {
                          try {
                            entry.$2.validate(value ?? '');
                          } on HotelException catch (error) {
                            return error.message;
                          }
                          return _error?.field == entry.$2.id
                              ? _error!.message
                              : null;
                        },
                        onFieldSubmitted: (_) {
                          if (entry.$1 < widget.fields.length - 1) {
                            _focus[entry.$1 + 1].requestFocus();
                          } else {
                            _save();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.footer != null) ...[
                      widget.footer!,
                      const SizedBox(height: 24),
                    ],
                    if (_error != null && _error!.field == null) ...[
                      AppNotice(message: _error!.message, isError: true),
                      const SizedBox(height: 24),
                    ],
                    FilledButton.icon(
                      onPressed: _saving || _allowPop ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: 'Saving changes',
                              ),
                            )
                          : const Icon(Icons.check, size: 20),
                      label: Text(
                        _saving
                            ? 'Saving…'
                            : _error != null && _error!.field == null
                            ? 'Retry save'
                            : widget.saveLabel,
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
