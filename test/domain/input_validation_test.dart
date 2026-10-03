import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:hotel_management_system/domain/services/input_validation.dart';

import '../support/fixtures.dart';

void main() {
  test(
    'normalizes required text while accepting natural names and addresses',
    () {
      expect(InputValidation.name('  علی  '), 'علی');
      expect(InputValidation.address(' Line 1\nLine 2 '), 'Line 1\nLine 2');
      expect(
        () => InputValidation.roomNumber(' \t '),
        throwsA(hotelError(HotelErrorCode.validation)),
      );
      expect(
        () => InputValidation.name('x' * 121),
        throwsA(hotelError(HotelErrorCode.validation)),
      );
    },
  );

  test('normalizes supported phone forms and rejects invalid digits', () {
    for (final phone in ['0300 1234567', '0300-1234567', '+92 300 1234567']) {
      expect(InputValidation.phone(phone), '+923001234567');
    }
    for (final phone in [
      '',
      '0300123',
      '030012345678',
      '+922001234567',
      '0300x1234567',
    ]) {
      expect(
        () => InputValidation.phone(phone),
        throwsA(hotelError(HotelErrorCode.validation)),
      );
    }
  });

  test('CNIC accepts exactly two input formats', () {
    expect(InputValidation.cnic(' 12345-1234567-1 '), '1234512345671');
    expect(InputValidation.cnic('1234512345671'), '1234512345671');
    for (final cnic in [
      '',
      '123451234567',
      '1234-51234567-1',
      '12345 1234567 1',
      '12345-1234567-X',
    ]) {
      expect(
        () => InputValidation.cnic(cnic),
        throwsA(hotelError(HotelErrorCode.validation)),
      );
    }
  });

  test('money parsing is exact and bounded without double rounding', () {
    expect(InputValidation.price('1250.50'), 125050);
    expect(InputValidation.price('0.01'), 1);
    expect(InputValidation.price('12.1'), 1210);
    expect(InputValidation.price('12'), 1200);
    expect(InputValidation.price('9999999.99'), InputValidation.maxRateMinor);
    for (final price in [
      '',
      '0',
      '-1',
      '1.234',
      'NaN',
      'Infinity',
      '1e3',
      '10000000',
      '1,200',
    ]) {
      expect(
        () => InputValidation.price(price),
        throwsA(hotelError(HotelErrorCode.validation)),
      );
    }
  });

  test('calendar dates reject normalization and preserve leap days', () {
    expect(StayDate.parse('2028-02-29').toString(), '2028-02-29');
    for (final raw in [
      '2026-02-29',
      '2026-04-31',
      '2026-13-01',
      '2026-1-01',
      '0000-01-01',
      '2026-10-04T00:00:00Z',
    ]) {
      expect(() => StayDate.parse(raw), throwsFormatException);
    }
    expect(StayDate(2026, 3, 7).nightsUntil(StayDate(2026, 3, 9)), 2);
    expect(StayDate(2026, 10, 4), StayDate.parse('2026-10-04'));
  });
}
