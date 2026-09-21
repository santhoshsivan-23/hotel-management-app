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

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: _toInt(map['id']),
      uuid: map['uuid']?.toString(),
      roomNumber: map['room_number']?.toString() ?? '',
      roomTypeId: _toInt(map['room_type_id']),
      roomTypeName: map['room_type_name']?.toString(),
      floor: map['floor']?.toString(),
      capacity: _toInt(map['capacity'], 1),
      price: _toDouble(map['price']),
      status: map['status']?.toString() ?? 'AVAILABLE',
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
