// Pure Dart entity — no Flutter or backend imports.

class IncomingBatch {
  const IncomingBatch({
    required this.batchId,
    required this.donorId,
    required this.description,
    required this.weightKg,
    required this.portions,
    this.driverId,
    this.estimatedArrival,
  });

  final String batchId;
  final String donorId;
  final String description;
  final double weightKg;
  final int portions;
  final String? driverId;
  final DateTime? estimatedArrival;

  // TODO: expand fields as beneficiary requirements are defined
}
