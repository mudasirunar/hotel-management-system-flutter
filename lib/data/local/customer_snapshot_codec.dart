import 'dart:convert';

import '../../domain/hotel_exception.dart';
import '../../domain/models/customer_state.dart';

final class CustomerSnapshotCodec {
  const CustomerSnapshotCodec();

  static const supportedSchemaVersion = 1;

  String encode(CustomerState state) =>
      jsonEncode(state.toJson());

  CustomerState decode(String raw) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.corruptStorage,
        'Saved customer records are unreadable. Preserve data and try again.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const HotelException(
        HotelErrorCode.corruptStorage,
        'Saved customer records are formatted unexpectedly.',
      );
    }

    final version = decoded['schemaVersion'];
    if (version != supportedSchemaVersion) {
      throw const HotelException(
        HotelErrorCode.unsupportedSchema,
        'These customer records were saved by another version of the app.',
      );
    }

    try {
      return CustomerState.fromJson(decoded);
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.corruptStorage,
        'Saved customer records contain invalid fields.',
      );
    }
  }
}
