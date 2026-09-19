/// Rooms are read-only reference data on the device (see rooms_table.dart)
/// - `id` here IS the server's primary key, not a client uuid, because
/// rooms are never created offline.
class RoomModel {
  RoomModel({
    required this.id,
    this.uuid,
    required this.roomNumber,
    required this.roomTypeId,
    this.roomTypeName,
    this.floor,
    required this.capacity,
    required this.price,
    required this.status,
  });

  final int id;
  final String? uuid;
  final String roomNumber;
  final int roomTypeId;
  final String? roomTypeName;
  final String? floor;
  final int capacity;
  final double price;
  final String status;

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as int,
      uuid: map['uuid'] as String?,
      roomNumber: map['room_number'] as String,
      roomTypeId: map['room_type_id'] as int,
      roomTypeName: map['room_type_name'] as String?,
      floor: map['floor'] as String?,
      capacity: map['capacity'] as int,
      price: (map['price'] as num).toDouble(),
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'uuid': uuid,
      'room_number': roomNumber,
      'room_type_id': roomTypeId,
      'floor': floor,
      'capacity': capacity,
      'price': price,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
