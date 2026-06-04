// Pure Dart — zero Flutter or backend imports.

class IntakeItem {
  const IntakeItem({
    required this.name,
    required this.category,
    required this.weightKg,
  });

  final String name;
  final String category;
  final double weightKg;
}
