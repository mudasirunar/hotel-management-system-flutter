import '../models/hotel_state.dart';

abstract interface class HotelRepository {
  Future<HotelState> load();
  Future<void> save(HotelState state);
  Future<void> close();
}
