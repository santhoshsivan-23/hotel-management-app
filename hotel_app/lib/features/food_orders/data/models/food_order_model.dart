class FoodOrderItemModel {
  FoodOrderItemModel({
    required this.uuid,
    required this.productName,
    required this.quantity,
    required this.price,
    this.modifiers,
    this.notes,
  });

  final String uuid;
  final String productName;
  final int quantity;
  final double price;
  final String? modifiers;
  final String? notes;

  double get lineTotal => quantity * price;

  factory FoodOrderItemModel.fromMap(Map<String, dynamic> map) {
    return FoodOrderItemModel(
      uuid: map['uuid'] as String,
      productName: map['product_name'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      modifiers: map['modifiers'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap(String foodOrderUuid) {
    return {
      'uuid': uuid,
      'food_order_uuid': foodOrderUuid,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'modifiers': modifiers,
      'notes': notes,
    };
  }
}

/// In-Room Order. NEW -> ACCEPTED -> PREPARING -> READY -> DELIVERED ->
/// COMPLETED, same lifecycle as the backend's food_orders table.
class FoodOrderModel {
  FoodOrderModel({
    required this.uuid,
    this.serverId,
    required this.bookingUuid,
    required this.roomId,
    this.roomNumber,
    required this.guestUuid,
    required this.status,
    required this.totalAmount,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  final String uuid;
  final int? serverId;
  final String bookingUuid;
  final int roomId;
  final String? roomNumber;
  final String guestUuid;
  final String status;
  final double totalAmount;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FoodOrderItemModel> items;

  bool get isPending => syncStatus == 'PENDING' || syncStatus == 'FAILED';

  factory FoodOrderModel.fromMap(Map<String, dynamic> map, {List<FoodOrderItemModel> items = const []}) {
    return FoodOrderModel(
      uuid: map['uuid'] as String,
      serverId: map['server_id'] as int?,
      bookingUuid: map['booking_uuid'] as String,
      roomId: map['room_id'] as int,
      roomNumber: map['room_number'] as String?,
      guestUuid: map['guest_uuid'] as String,
      status: map['status'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      syncStatus: map['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'server_id': serverId,
      'booking_uuid': bookingUuid,
      'room_id': roomId,
      'guest_uuid': guestUuid,
      'status': status,
      'total_amount': totalAmount,
      'sync_status': syncStatus,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }
}
