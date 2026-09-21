/// A reservation/stay. `guestUuid` and `roomId` link to a (possibly still
/// PENDING) local guest and a cached (read-only) room respectively - see
/// bookings_table.dart for why those two are different kinds of
/// reference.
class BookingModel {
  BookingModel({
    required this.uuid,
    this.serverId,
    this.bookingNumber,
    required this.guestUuid,
    this.guestName,
    this.guestMobile,
    required this.roomId,
    this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.roomRate,
    required this.nights,
    required this.roomTotal,
    required this.discount,
    required this.taxAmount,
    required this.grandTotal,
    required this.advancePaid,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uuid;
  final int? serverId;
  final String? bookingNumber;
  final String guestUuid;
  final String? guestName;
  final String? guestMobile;
  final int roomId;
  final String? roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double roomRate;
  final int nights;
  final double roomTotal;
  final double discount;
  final double taxAmount;
  final double grandTotal;
  final double advancePaid;
  final String status;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => syncStatus == 'PENDING' || syncStatus == 'FAILED';
  bool get isActive => status == 'CONFIRMED' || status == 'CHECKED_IN';

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

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      uuid: map['uuid']?.toString() ?? '',
      serverId: _toNullableInt(map['server_id']),
      bookingNumber: map['booking_number']?.toString(),
      guestUuid: map['guest_uuid']?.toString() ?? '',
      guestName: map['guest_name']?.toString(),
      guestMobile: map['guest_mobile']?.toString(),
      roomId: _toInt(map['room_id']),
      roomNumber: map['room_number']?.toString(),
      checkIn: DateTime.tryParse(map['check_in']?.toString() ?? '') ?? DateTime.now(),
      checkOut: DateTime.tryParse(map['check_out']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 1)),
      adults: _toInt(map['adults'], 1),
      children: _toInt(map['children'], 0),
      roomRate: _toDouble(map['room_rate']),
      nights: _toInt(map['nights'], 1),
      roomTotal: _toDouble(map['room_total']),
      discount: _toDouble(map['discount']),
      taxAmount: _toDouble(map['tax_amount']),
      grandTotal: _toDouble(map['grand_total']),
      advancePaid: _toDouble(map['advance_paid']),
      status: map['status']?.toString() ?? 'CONFIRMED',
      syncStatus: map['sync_status']?.toString() ?? 'PENDING',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'server_id': serverId,
      'booking_number': bookingNumber,
      'guest_uuid': guestUuid,
      'room_id': roomId,
      'check_in': checkIn.toUtc().toIso8601String(),
      'check_out': checkOut.toUtc().toIso8601String(),
      'adults': adults,
      'children': children,
      'room_rate': roomRate,
      'nights': nights,
      'room_total': roomTotal,
      'discount': discount,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'advance_paid': advancePaid,
      'status': status,
      'sync_status': syncStatus,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }
}

/// Result of the local pricing calculation - mirrors booking.service.js's
/// calculatePricing() on the backend so a receptionist sees the same
/// numbers offline that the server will recompute on sync.
class PricingBreakdown {
  PricingBreakdown({
    required this.nights,
    required this.roomTotal,
    required this.discount,
    required this.taxAmount,
    required this.taxPercent,
    required this.grandTotal,
  });

  final int nights;
  final double roomTotal;
  final double discount;
  final double taxAmount;
  final double taxPercent;
  final double grandTotal;
}
