enum HotelErrorCode {
  validation,
  duplicate,
  notFound,
  bookingConflict,
  invalidTransition,
  linkedRecord,
  notReady,
  storageRead,
  storageWrite,
  corruptStorage,
  unsupportedSchema,
}

/// Safe to display: messages never contain stored personal data or raw errors.
class HotelException implements Exception {
  const HotelException(this.code, this.message, {this.field});

  final HotelErrorCode code;
  final String message;
  final String? field;

  @override
  String toString() => message;
}
