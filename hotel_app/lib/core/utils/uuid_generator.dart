import 'package:uuid/uuid.dart';

/// Every record created offline gets one of these the moment it's saved
/// locally - before any network call happens. It's what makes sync
/// idempotent: the backend upserts by this uuid, so re-sending the same
/// record (a retried request, a duplicate tap on "Sync") can only ever
/// update the same row, never create a second one.
class UuidGenerator {
  UuidGenerator._();

  static const Uuid _uuid = Uuid();

  static String generate() => _uuid.v4();

  static bool isValid(String? value) {
    if (value == null || value.isEmpty) return false;
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return regex.hasMatch(value);
  }
}
