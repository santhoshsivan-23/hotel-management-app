import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/reservations/presentation/screens/reservation_list_screen.dart';
import '../features/rooms/presentation/screens/room_list_screen.dart';
import '../features/guests/presentation/screens/guest_list_screen.dart';
import '../features/checkin_checkout/presentation/screens/checkin_checkout_tabs_screen.dart';
import '../features/food_orders/presentation/screens/order_list_screen.dart';
import '../features/room_services/presentation/screens/service_request_list_screen.dart';
import '../features/payments_billing/presentation/screens/payments_billing_screen.dart';
import '../features/reports/presentation/screens/reports_home_screen.dart';
import '../features/settings/settings_home_screen.dart';
import '../features/settings/room_types/presentation/screens/room_types_screen.dart';
import '../features/settings/amenities/presentation/screens/amenities_screen.dart';
import '../features/settings/service_types/presentation/screens/service_types_screen.dart';
import '../features/settings/tax_charges/presentation/screens/tax_charges_screen.dart';
import '../features/settings/payment_methods/presentation/screens/payment_methods_screen.dart';
import '../features/settings/users_roles/presentation/screens/users_roles_screen.dart';
import '../features/settings/hotel_business_settings/presentation/screens/hotel_business_settings_screen.dart';

/// Route name constants, shared by SidebarNav (which navigates to them)
/// and AppRouter (which maps them to screens). Only top-level, sidebar-
/// reachable destinations get a named route; in-feature navigation
/// (booking details, the new-reservation wizard, edit screens) pushes
/// directly with MaterialPageRoute instead of growing this list forever.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String reservations = '/reservations';
  static const String rooms = '/rooms';
  static const String guests = '/guests';
  static const String checkinCheckout = '/checkin-checkout';
  static const String foodOrders = '/food-orders';
  static const String roomServices = '/room-services';
  static const String paymentsBilling = '/payments-billing';
  static const String reports = '/reports';
  static const String settingsHome = '/settings';
  static const String settingsRoomTypes = '/settings/room-types';
  static const String settingsAmenities = '/settings/amenities';
  static const String settingsServiceTypes = '/settings/service-types';
  static const String settingsTaxCharges = '/settings/tax-charges';
  static const String settingsPaymentMethods = '/settings/payment-methods';
  static const String settingsUsersRoles = '/settings/users-roles';
  static const String settingsHotelBusinessSettings = '/settings/hotel-business-settings';
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builders = <String, WidgetBuilder>{
      AppRoutes.login: (_) => const LoginScreen(),
      AppRoutes.dashboard: (_) => const DashboardScreen(),
      AppRoutes.reservations: (_) => const ReservationListScreen(),
      AppRoutes.rooms: (_) => const RoomListScreen(),
      AppRoutes.guests: (_) => const GuestListScreen(),
      AppRoutes.checkinCheckout: (_) => const CheckinCheckoutTabsScreen(),
      AppRoutes.foodOrders: (_) => const OrderListScreen(),
      AppRoutes.roomServices: (_) => const ServiceRequestListScreen(),
      AppRoutes.paymentsBilling: (_) => const PaymentsBillingScreen(),
      AppRoutes.reports: (_) => const ReportsHomeScreen(),
      AppRoutes.settingsHome: (_) => const SettingsHomeScreen(),
      AppRoutes.settingsRoomTypes: (_) => const RoomTypesScreen(),
      AppRoutes.settingsAmenities: (_) => const AmenitiesScreen(),
      AppRoutes.settingsServiceTypes: (_) => const ServiceTypesScreen(),
      AppRoutes.settingsTaxCharges: (_) => const TaxChargesScreen(),
      AppRoutes.settingsPaymentMethods: (_) => const PaymentMethodsScreen(),
      AppRoutes.settingsUsersRoles: (_) => const UsersRolesScreen(),
      AppRoutes.settingsHotelBusinessSettings: (_) => const HotelBusinessSettingsScreen(),
    };

    final builder = builders[settings.name];
    if (builder == null) {
      return MaterialPageRoute(
        builder: (_) => Scaffold(body: Center(child: Text('Unknown route: ${settings.name}'))),
      );
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
