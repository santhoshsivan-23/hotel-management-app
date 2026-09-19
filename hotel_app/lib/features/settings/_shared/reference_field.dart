enum ReferenceFieldType { text, number, boolean }

/// Describes one editable field on a generic settings CRUD screen (see
/// reference_crud_screen.dart). Room Types, Amenities, Service Types,
/// Taxes and Payment Methods are all "a handful of fields + active
/// toggle" shaped, so they share one form/list implementation instead of
/// five near-identical hand-written screens.
class ReferenceField {
  const ReferenceField({
    required this.key,
    required this.label,
    this.type = ReferenceFieldType.text,
    this.required = true,
    this.showInList = true,
  });

  final String key;
  final String label;
  final ReferenceFieldType type;
  final bool required;
  final bool showInList;
}
