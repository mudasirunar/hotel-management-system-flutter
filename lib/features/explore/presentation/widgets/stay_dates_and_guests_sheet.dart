import 'package:flutter/material.dart';

import '../../../../domain/models/stay_date.dart';

/// Modal bottom sheet for choosing stay arrival/departure dates and guest party size.
class StayDatesAndGuestsSheet extends StatefulWidget {
  const StayDatesAndGuestsSheet({
    super.key,
    required this.initialArrival,
    required this.initialDeparture,
    required this.initialPartySize,
    required this.onConfirm,
  });

  final StayDate initialArrival;
  final StayDate initialDeparture;
  final int initialPartySize;
  final void Function(StayDate arrival, StayDate departure, int partySize) onConfirm;

  static Future<void> show({
    required BuildContext context,
    required StayDate arrival,
    required StayDate departure,
    required int partySize,
    required void Function(StayDate arrival, StayDate departure, int partySize) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StayDatesAndGuestsSheet(
        initialArrival: arrival,
        initialDeparture: departure,
        initialPartySize: partySize,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<StayDatesAndGuestsSheet> createState() => _StayDatesAndGuestsSheetState();
}

class _StayDatesAndGuestsSheetState extends State<StayDatesAndGuestsSheet> {
  late StayDate _arrival;
  late StayDate _departure;
  late int _partySize;

  @override
  void initState() {
    super.initState();
    _arrival = widget.initialArrival;
    _departure = widget.initialDeparture;
    _partySize = widget.initialPartySize;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final firstAllowed = DateTime(now.year, now.month, now.day);
    final lastAllowed = firstAllowed.add(const Duration(days: 365));

    final initialStart = _arrival.toDateTime();
    final initialEnd = _departure.toDateTime();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstAllowed.isBefore(initialStart) ? firstAllowed : initialStart,
      lastDate: lastAllowed,
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _arrival = StayDate.fromDateTime(picked.start);
        _departure = StayDate.fromDateTime(picked.end);
      });
    }
  }

  String _formatMonthDay(StayDate date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '';
    return '$m ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF141A16) : Colors.white;

    final nights = _departure.differenceInDays(_arrival);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Stay Dates & Guests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Dates Selection Tile
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C3C30) : const Color(0xFFDEE7E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stay Duration',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatMonthDay(_arrival)} → ${_formatMonthDay(_departure)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$nights ${nights == 1 ? "night" : "nights"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_calendar_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Party Size Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF1F5F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C3C30) : const Color(0xFFDEE7E1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_alt_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Guests',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Adults & children',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Plus / Minus Controls
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        onPressed: _partySize > 1
                            ? () => setState(() => _partySize--)
                            : null,
                      ),
                      Text(
                        '$_partySize',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        onPressed: _partySize < 8
                            ? () => setState(() => _partySize++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  widget.onConfirm(_arrival, _departure, _partySize);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Update Dates & Guests',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
