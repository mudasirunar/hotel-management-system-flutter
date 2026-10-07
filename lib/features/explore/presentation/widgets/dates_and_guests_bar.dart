import 'package:flutter/material.dart';

import '../../../../domain/models/stay_date.dart';

/// Compact bar displaying stay dates and party size, opening the selection sheet on tap.
class DatesAndGuestsBar extends StatelessWidget {
  const DatesAndGuestsBar({
    super.key,
    required this.arrival,
    required this.departure,
    required this.partySize,
    required this.onTap,
  });

  final StayDate arrival;
  final StayDate departure;
  final int partySize;
  final VoidCallback onTap;

  String _formatMonthDay(StayDate date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '';
    return '$m ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nights = departure.differenceInDays(arrival);
    final nightsText = nights == 1 ? '1 night' : '$nights nights';
    final guestsText = partySize == 1 ? '1 guest' : '$partySize guests';

    final bg = isDark ? const Color(0xFF1B231E) : const Color(0xFFF1F5F2);
    final border = isDark ? const Color(0xFF2C3931) : const Color(0xFFDEE7E1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatMonthDay(arrival)} – ${_formatMonthDay(departure)} ($nightsText)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  height: 14,
                  width: 1,
                  color: isDark ? Colors.white24 : Colors.black12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  guestsText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
