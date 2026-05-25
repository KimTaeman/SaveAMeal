class BatchAlreadyClaimedException implements Exception {
  const BatchAlreadyClaimedException();
  @override
  String toString() =>
      'BatchAlreadyClaimedException: batch was already claimed';
}
