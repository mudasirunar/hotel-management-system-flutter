import '../hotel_exception.dart';

abstract final class InputValidation {
  static String requiredText(
    String value,
    String field, {
    int maxLength = 200,
  }) {
    final text = value.trim();
    if (text.isEmpty) invalid(field, 'This field is required.');
    if (text.length > maxLength) {
      invalid(field, 'Use $maxLength characters or fewer.');
    }
    return text;
  }

  static String roomNumber(String value) =>
      requiredText(value, 'number', maxLength: 30);
  static String roomType(String value) =>
      requiredText(value, 'type', maxLength: 60);
  static String name(String value) =>
      requiredText(value, 'name', maxLength: 120);
  static String address(String value) =>
      requiredText(value, 'address', maxLength: 500);

  static String phone(String value) {
    final input = value.trim().replaceAll(RegExp(r'[ \-]'), '');
    if (RegExp(r'^03[0-9]{9}$').hasMatch(input)) {
      return '+92${input.substring(1)}';
    }
    if (RegExp(r'^\+923[0-9]{9}$').hasMatch(input)) return input;
    invalid(
      'phone',
      'Enter a valid phone number, such as 03XXXXXXXXX or +923XXXXXXXXX.',
    );
  }

  static String cnic(String value) {
    final input = value.trim();
    if (RegExp(r'^[0-9]{13}$').hasMatch(input)) return input;
    if (RegExp(r'^[0-9]{5}-[0-9]{7}-[0-9]$').hasMatch(input)) {
      return input.replaceAll('-', '');
    }
    invalid('cnic', 'Enter 13 digits or use XXXXX-XXXXXXX-X.');
  }

  // Use bounded integer minor units; never convert money through a double.
  static const maxRateMinor = 999999999; // Up to 9,999,999.99 per night.
  static int price(String value) {
    final input = value.trim();
    if (!RegExp(r'^[0-9]{1,7}(\.[0-9]{1,2})?$').hasMatch(input)) {
      invalid('price', 'Enter a positive price with up to two decimal places.');
    }
    final parts = input.split('.');
    final minor =
        int.parse(parts.first) * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
    rate(minor);
    return minor;
  }

  static void rate(int minor) {
    if (minor <= 0 || minor > maxRateMinor) {
      invalid('price', 'Enter a price between 0.01 and 9,999,999.99.');
    }
  }

  static Never invalid(String field, String message) =>
      throw HotelException(HotelErrorCode.validation, message, field: field);
}
