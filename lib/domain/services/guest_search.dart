import '../models/guest.dart';

/// Match names without case, and identifiers without display separators.
/// Local 03... and international +923... queries find the same phone record.
List<Guest> searchGuests(Iterable<Guest> guests, String query) {
  final text = query.trim().toLowerCase();
  final numericQuery = RegExp(r'^[+0-9\s()\-]+$').hasMatch(text);
  final digits = numericQuery ? text.replaceAll(RegExp(r'[^0-9]'), '') : '';
  final result = guests.where((guest) {
    if (text.isEmpty || guest.name.toLowerCase().contains(text)) return true;
    if (digits.isEmpty) return false;
    final phoneDigits = guest.phone.substring(1);
    final localPhone = '0${guest.phone.substring(3)}';
    return phoneDigits.contains(digits) ||
        localPhone.contains(digits) ||
        guest.cnic.contains(digits);
  }).toList();
  result.sort((a, b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.id.compareTo(b.id);
  });
  return result;
}
