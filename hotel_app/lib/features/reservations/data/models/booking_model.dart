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

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      uuid: map['uuid'] as String,
      serverId: map['server_id'] as int?,
      bookingNumber: map['booking_number'] as String?,
      guestUuid: map['guest_uuid'] as String,
      guestName: map['guest_name'] as String?,
      guestMobile: map['guest_mobile'] as String?,
      roomId: map['room_id'] as int,
      roomNumber: map['room_number'] as String?,
      checkIn: DateTime.parse(map['check_in'] as String),
      checkOut: DateTime.parse(map['check_out'] as String),
      adults: map['adults'] as int,
      children: map['children'] as int,
      roomRate: (map['room_rate'] as num).toDouble(),
      nights: map['nights'] as int,
      roomTotal: (map['room_total'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      grandTotal: (map['grand_total'] as num).toDouble(),
      advancePaid: (map['advance_paid'] as num).toDouble(),
      status: map['status'] as String,
      syncStatus: map['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
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
