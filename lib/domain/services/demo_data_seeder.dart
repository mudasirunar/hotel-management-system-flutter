import '../models/booking.dart';
import '../models/guest.dart';
import '../models/hotel_state.dart';
import '../models/room.dart';
import '../models/stay_date.dart';
import 'hotel_rules.dart';

class DemoDataSeeder {
  static HotelState createDemoState({DateTime? reference}) {
    final now = (reference ?? DateTime.now()).toUtc();
    final today = StayDate.fromDateTime(now);
    final tomorrow = StayDate.fromDateTime(now.add(const Duration(days: 1)));
    final inTwoDays = StayDate.fromDateTime(now.add(const Duration(days: 2)));
    final inFourDays = StayDate.fromDateTime(now.add(const Duration(days: 4)));

    final rooms = [
      Room(
        id: 'room-101',
        number: '101',
        type: 'Deluxe King',
        nightlyRateMinor: 1200000,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Room(
        id: 'room-102',
        number: '102',
        type: 'Executive Suite',
        nightlyRateMinor: 1800000,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Room(
        id: 'room-103',
        number: '103',
        type: 'Standard Twin',
        nightlyRateMinor: 850000,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      Room(
        id: 'room-201',
        number: '201',
        type: 'Deluxe King',
        nightlyRateMinor: 1200000,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Room(
        id: 'room-202',
        number: '202',
        type: 'Presidential Suite',
        nightlyRateMinor: 3500000,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    final guests = [
      Guest(
        id: 'guest-1',
        name: 'Ali Khan',
        phone: '+923001234567',
        cnic: '3520212345671',
        address: 'House 45, Gulberg III, Lahore',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      Guest(
        id: 'guest-2',
        name: 'Fatima Ahmed',
        phone: '+923219876543',
        cnic: '4210198765432',
        address: 'Apartment 12-B, Clifton Block 5, Karachi',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      Guest(
        id: 'guest-3',
        name: 'Usman Tariq',
        phone: '+923335557788',
        cnic: '3740555577883',
        address: 'Street 9, Sector F-7/2, Islamabad',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      Guest(
        id: 'guest-4',
        name: 'Zainab Malik',
        phone: '+923456789012',
        cnic: '3840367890124',
        address: 'University Town, Peshawar',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    final bookings = [
      Booking(
        id: 'booking-101',
        roomId: 'room-101',
        guestIds: ['guest-1'],
        primaryGuestId: 'guest-1',
        arrivalDate: today,
        departureDate: inTwoDays,
        nightlyRateMinorSnapshot: 1200000,
        status: BookingStatus.checkedIn,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        actualCheckInAt: now.subtract(const Duration(hours: 3)),
      ),
      Booking(
        id: 'booking-102',
        roomId: 'room-102',
        guestIds: ['guest-2'],
        primaryGuestId: 'guest-2',
        arrivalDate: tomorrow,
        departureDate: inFourDays,
        nightlyRateMinorSnapshot: 1800000,
        status: BookingStatus.reserved,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];

    final state = HotelState(rooms: rooms, guests: guests, bookings: bookings);
    HotelRules.validateSnapshot(state);
    return state;
  }
}
