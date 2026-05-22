// Pure Dart entity — no Flutter or backend imports.

class Job {
  const Job({
    required this.batchId,
    required this.donorId,
    required this.pickupAddress,
    this.beneficiaryId,
    this.driverId,
  });

  final String batchId;
  final String donorId;
  final String pickupAddress;
  final String? beneficiaryId;
  final String? driverId;

  // TODO: expand fields as driver job requirements are defined
}
