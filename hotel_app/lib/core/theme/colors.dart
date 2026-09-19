import 'package:flutter/material.dart';

/// Central color palette, including the status colors used across rooms,
/// bookings, food orders, service requests, and the sync badge - keeping
/// these in one place means a "CONFIRMED" chip and the dashboard's room
/// grid always agree on what color means what.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E5F74);
  static const Color primaryDark = Color(0xFF133A4A);
  static const Color secondary = Color(0xFFF2A65A);
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE0A800);
  static const Color textPrimary = Color(0xFF1B1F23);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // Room status
  static const Color roomAvailable = Color(0xFF2E9E5B);
  static const Color roomReserved = Color(0xFFE0A800);
  static const Color roomOccupied = Color(0xFFD64545);
  static const Color roomDirty = Color(0xFF8B5E3C);
  static const Color roomCleaning = Color(0xFF3B82F6);
  static const Color roomMaintenance = Color(0xFF6B7280);

  // Booking status
  static const Color bookingPending = Color(0xFFE0A800);
  static const Color bookingConfirmed = Color(0xFF3B82F6);
  static const Color bookingCheckedIn = Color(0xFF2E9E5B);
  static const Color bookingCheckedOut = Color(0xFF6B7280);
  static const Color bookingCancelled = Color(0xFFD64545);

  // Sync badge
  static const Color syncOffline = Color(0xFF9CA3AF);
  static const Color syncPending = Color(0xFFE0A800);
  static const Color syncSynced = Color(0xFF2E9E5B);
  static const Color syncFailed = Color(0xFFD64545);

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return roomAvailable;
      case 'RESERVED':
        return roomReserved;
      case 'OCCUPIED':
        return roomOccupied;
      case 'DIRTY':
        return roomDirty;
      case 'CLEANING':
        return roomCleaning;
      case 'MAINTENANCE':
      case 'OUT_OF_SERVICE':
        return roomMaintenance;
      case 'PENDING':
      case 'REQUESTED':
      case 'NEW':
        return bookingPending;
      case 'CONFIRMED':
      case 'ACCEPTED':
      case 'PREPARING':
      case 'IN_PROGRESS':
        return bookingConfirmed;
      case 'CHECKED_IN':
      case 'READY':
      case 'DELIVERED':
      case 'COMPLETED':
      case 'PAID':
      case 'FIXED':
        return bookingCheckedIn;
      case 'CHECKED_OUT':
        return bookingCheckedOut;
      case 'CANCELLED':
      case 'NO_SHOW':
      case 'UNPAID':
        return bookingCancelled;
      default:
        return textSecondary;
    }
  }
}
