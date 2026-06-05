// Pure Dart entity — no Flutter or backend imports.
// Shared across donor and beneficiary features to avoid cross-feature
// domain coupling.
enum FoodCategory {
  bakery,
  produce,
  dairy,
  meat,
  beverages,
  other;

  /// Parses a raw string (e.g. from Firestore) into a [FoodCategory].
  /// Falls back to [FoodCategory.other] for unrecognised values.
  static FoodCategory fromString(String value) => FoodCategory.values.firstWhere(
    (e) => e.name == value,
    orElse: () => FoodCategory.other,
  );
}
