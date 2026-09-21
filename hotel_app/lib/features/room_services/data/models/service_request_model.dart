/// Room Service request (Laundry, Extra Bed, ...). REQUESTED -> ACCEPTED
/// -> IN_PROGRESS -> COMPLETED -> DELIVERED, matching the backend.
class ServiceRequestModel {
  ServiceRequestModel({
    required this.uuid,
    this.serverId,
    required this.bookingUuid,
    required this.roomId,
    this.roomNumber,
    required this.guestUuid,
    required this.serviceTypeId,
    this.serviceTypeName,
    required this.quantity,
    required this.amount,
    required this.status,
    this.notes,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uuid;
  final int? serverId;
  final String bookingUuid;
  final int roomId;
  final String? roomNumber;
  final String guestUuid;
  final int serviceTypeId;
  final String? serviceTypeName;
  final int quantity;
  final double amount;
  final String status;
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => syncStatus == 'PENDING' || syncStatus == 'FAILED';

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map) {
    return ServiceRequestModel(
      uuid: map['uuid'] as String,
      serverId: map['server_id'] as int?,
      bookingUuid: map['booking_uuid'] as String,
      roomId: map['room_id'] as int,
      roomNumber: map['room_number'] as String?,
      guestUuid: map['guest_uuid'] as String,
      serviceTypeId: map['service_type_id'] as int,
      serviceTypeName: map['service_type_name'] as String?,
      quantity: map['quantity'] as int,
      amount: _toDouble(map['amount']),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'server_id': serverId,
      'booking_uuid': bookingUuid,
      'room_id': roomId,
      'guest_uuid': guestUuid,
      'service_type_id': serviceTypeId,
      'quantity': quantity,
      'amount': amount,
      'status': status,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }
}
