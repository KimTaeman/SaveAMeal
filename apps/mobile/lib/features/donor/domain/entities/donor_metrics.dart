// Pure Dart entity — no Flutter or backend imports.
class DonorMetrics {
  const DonorMetrics({
    required this.donorId,
    required this.totalKg,
    required this.totalMeals,
    required this.totalCO2e,
    required this.totalDeliveries,
  });

  final String donorId;
  final double totalKg;
  final int totalMeals;
  final double totalCO2e;
  final int totalDeliveries;

  static const empty = DonorMetrics(
    donorId: '',
    totalKg: 0.0,
    totalMeals: 0,
    totalCO2e: 0.0,
    totalDeliveries: 0,
  );
}
