import 'hotel.dart';
import 'hotel_room.dart';
import 'inventory_block.dart';

/// An immutable catalog of all available hotels, rooms, and anonymous inventory blocks.
final class HotelCatalog {
  const HotelCatalog({
    this.catalogVersion = 1,
    this.hotels = const [],
    this.inventoryBlocks = const [],
  });

  factory HotelCatalog.fromJson(Map<String, dynamic> json) {
    final version = json['catalogVersion'] as int? ?? 1;

    final rawHotels = json['hotels'] as List<dynamic>? ?? const [];
    final hotels = rawHotels
        .map((h) => Hotel.fromJson(h as Map<String, dynamic>))
        .toList();

    final rawBlocks = json['inventoryBlocks'] as List<dynamic>? ?? const [];
    final inventoryBlocks = rawBlocks
        .map((b) => InventoryBlock.fromJson(b as Map<String, dynamic>))
        .toList();

    return HotelCatalog(
      catalogVersion: version,
      hotels: List.unmodifiable(hotels),
      inventoryBlocks: List.unmodifiable(inventoryBlocks),
    );
  }

  final int catalogVersion;
  final List<Hotel> hotels;
  final List<InventoryBlock> inventoryBlocks;

  Hotel? findHotel(String id) {
    for (final hotel in hotels) {
      if (hotel.id == id) return hotel;
    }
    return null;
  }

  HotelRoom? findRoom(String roomId) {
    for (final hotel in hotels) {
      for (final room in hotel.rooms) {
        if (room.id == roomId) return room;
      }
    }
    return null;
  }

  Hotel? findHotelForRoom(String roomId) {
    for (final hotel in hotels) {
      for (final room in hotel.rooms) {
        if (room.id == roomId) return hotel;
      }
    }
    return null;
  }

  List<InventoryBlock> inventoryBlocksForRoom(String roomId) =>
      inventoryBlocks.where((b) => b.roomId == roomId).toList();

  Map<String, dynamic> toJson() => {
    'catalogVersion': catalogVersion,
    'hotels': hotels.map((h) => h.toJson()).toList(),
    'inventoryBlocks': inventoryBlocks.map((b) => b.toJson()).toList(),
  };
}
