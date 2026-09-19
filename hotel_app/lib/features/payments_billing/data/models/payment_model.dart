class PaymentModel {
  PaymentModel({
    required this.uuid,
    this.serverId,
    required this.bookingUuid,
    required this.amount,
    required this.method,
    this.referenceNo,
    required this.paidAt,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uuid;
  final int? serverId;
  final String bookingUuid;
  final double amount;
  final String method;
  final String? referenceNo;
  final DateTime paidAt;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => syncStatus == 'PENDING' || syncStatus == 'FAILED';

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      uuid: map['uuid'] as String,
      serverId: map['server_id'] as int?,
      bookingUuid: map['booking_uuid'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: map['method'] as String,
      referenceNo: map['reference_no'] as String?,
      paidAt: DateTime.parse(map['paid_at'] as String),
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
      'amount': amount,
      'method': method,
      'reference_no': referenceNo,
      'paid_at': paidAt.toUtc().toIso8601String(),
      'sync_status': syncStatus,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }
}
