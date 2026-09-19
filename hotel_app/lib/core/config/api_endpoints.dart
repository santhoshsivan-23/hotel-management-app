/// Every REST path the app calls, mirroring hotel-backend's src/routes/*.
/// Kept as plain string constants/functions so the network layer and the
/// sync layer both build requests off the same source of truth.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // Core resources
  static const String guests = '/guests';
  static String guestById(int id) => '/guests/$id';

  static const String bookings = '/bookings';
  static String bookingById(int id) => '/bookings/$id';
  static String bookingRunningBill(int id) => '/bookings/$id/running-bill';
  static String bookingCancel(int id) => '/bookings/$id/cancel';
  static String bookingCheckin(int id) => '/bookings/$id/checkin';
  static String bookingCheckout(int id) => '/bookings/$id/checkout';
  static String bookingChangeRoom(int id) => '/bookings/$id/change-room';
  static String bookingExtend(int id) => '/bookings/$id/extend';
  static String bookingStatus(int id) => '/bookings/$id/status';

  static const String rooms = '/rooms';
  static const String roomsAvailable = '/rooms/available';
  static String roomById(int id) => '/rooms/$id';
  static String roomStatus(int id) => '/rooms/$id/status';

  static const String roomTypes = '/room-types';
  static const String amenities = '/amenities';
  static const String serviceTypes = '/service-types';
  static const String taxes = '/taxes';
  static const String paymentMethods = '/payment-methods';

  static const String foodOrders = '/food-orders';
  static String foodOrderStatus(int id) => '/food-orders/$id/status';

  static const String serviceRequests = '/service-requests';
  static String serviceRequestStatus(int id) => '/service-requests/$id/status';

  static const String payments = '/payments';
  static String paymentsByBooking(int bookingId) => '/payments/booking/$bookingId';

  static String invoiceByBooking(int bookingId) => '/invoices/booking/$bookingId';
  static String invoiceGenerate(int bookingId) => '/invoices/booking/$bookingId/generate';

  static const String maintenance = '/maintenance';
  static String maintenanceStatus(int id) => '/maintenance/$id/status';

  static const String housekeeping = '/housekeeping';
  static String housekeepingStatus(int id) => '/housekeeping/$id/status';

  static const String users = '/users';
  static const String roles = '/roles';
  static const String hotelSettings = '/hotel-settings';

  // Reports
  static const String reportBookings = '/reports/bookings';
  static const String reportOccupancy = '/reports/occupancy';
  static const String reportRevenue = '/reports/revenue';
  static const String reportFoodSales = '/reports/food-sales';
  static const String reportRoomServices = '/reports/room-services';
  static const String reportPayments = '/reports/payments';
  static const String reportOutstanding = '/reports/outstanding';

  // Offline sync
  static const String syncGuests = '/sync/guests';
  static const String syncBookings = '/sync/bookings';
  static const String syncFoodOrders = '/sync/food-orders';
  static const String syncServiceRequests = '/sync/service-requests';
  static const String syncPayments = '/sync/payments';
  static const String syncMaintenance = '/sync/maintenance';
  static const String syncHousekeeping = '/sync/housekeeping';
  static const String syncReferenceData = '/sync/reference-data';
  // Pulling other devices' active bookings (for local availability checks)
  // is a sub-route of reference-data on the backend, NOT of /sync/bookings
  // (that path is POST-only, for pushing new/changed bookings).
  static const String syncActiveBookings = '/sync/reference-data/bookings';
}
