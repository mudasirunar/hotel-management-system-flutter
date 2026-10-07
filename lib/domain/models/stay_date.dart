/// A calendar date without a timezone or time-of-day component.
final class StayDate implements Comparable<StayDate> {
  factory StayDate(int year, int month, int day) {
    final date = DateTime.utc(year, month, day);
    if (year < 1 ||
        year > 9999 ||
        date.year != year ||
        date.month != month ||
        date.day != day) {
      throw const FormatException('Invalid calendar date.');
    }
    return StayDate._(year, month, day);
  }

  const StayDate._(this.year, this.month, this.day);

  factory StayDate.fromDateTime(DateTime value) =>
      StayDate(value.year, value.month, value.day);

  factory StayDate.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Expected a calendar date.');
    }
    return StayDate(
      int.parse(value.substring(0, 4)),
      int.parse(value.substring(5, 7)),
      int.parse(value.substring(8, 10)),
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);
  int nightsUntil(StayDate other) => other._utc.difference(_utc).inDays;
  bool isBefore(StayDate other) => compareTo(other) < 0;

  StayDate addDays(int days) =>
      StayDate.fromDateTime(DateTime.utc(year, month, day).add(Duration(days: days)));

  DateTime toDateTime() => DateTime(year, month, day);

  int differenceInDays(StayDate other) => (nightsUntil(other)).abs();

  String format() => toString();

  @override
  int compareTo(StayDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is StayDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
