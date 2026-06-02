class BatchAlreadyClaimedException implements Exception {
  const BatchAlreadyClaimedException();
  @override
  String toString() =>
      'BatchAlreadyClaimedException: batch was already claimed';
}

class BatchNotFoundException implements Exception {
  const BatchNotFoundException(this.batchId);
  final String batchId;
  @override
  String toString() => 'BatchNotFoundException: batch $batchId not found';
}
