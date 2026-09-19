import 'auth_service.dart';

/// Client-side UI gating only - the backend's role.middleware.js remains
/// the real authority. This just hides/disables actions a role can't use,
/// mirroring the Users & Roles permission sets from the app spec:
///   Receptionist: view rooms, create booking, check-in/out, manage
///     guests, add food order, add services, take payment
///   Housekeeping: view assigned rooms, update cleaning status, view
///     housekeeping requests
///   Admin: full access
class PermissionService {
  PermissionService(this._authService);
  final AuthService _authService;

  static const admin = 'Admin';
  static const manager = 'Manager';
  static const receptionist = 'Receptionist';
  static const housekeeping = 'Housekeeping';
  static const kitchen = 'Kitchen';

  String? get _role => _authService.role;

  bool get isAdmin => _role == admin;
  bool get isManagerOrAbove => _role == admin || _role == manager;

  bool get canManageSettings => isManagerOrAbove;
  bool get canManageUsers => isAdmin;

  bool get canCreateBooking => _role == admin || _role == manager || _role == receptionist;
  bool get canCheckInOut => canCreateBooking;
  bool get canManageGuests => canCreateBooking;
  bool get canTakePayment => canCreateBooking;
  bool get canAddFoodOrder => canCreateBooking || _role == kitchen;
  bool get canAddService => canCreateBooking;

  bool get canUpdateHousekeeping => _role == admin || _role == manager || _role == housekeeping;
  bool get canUpdateFoodOrders => _role == admin || _role == manager || _role == kitchen;

  bool get canViewReports => isManagerOrAbove;
}
