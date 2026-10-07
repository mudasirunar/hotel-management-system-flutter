import '../models/customer_state.dart';
import '../models/hotel_catalog.dart';

abstract interface class CustomerRepository {
  /// Loads the bundled hotel catalog.
  Future<HotelCatalog> loadCatalog();

  /// Loads the committed customer state from local storage.
  /// If uninitialized, performs safe idempotent bootstrap without user data loss.
  Future<CustomerState> loadState();

  /// Persists the updated customer state atomically to storage.
  Future<void> saveState(CustomerState state);

  /// Releases storage resources.
  Future<void> close();
}
