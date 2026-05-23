// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class GetDonorMetricsUsecase {
  const GetDonorMetricsUsecase(this._repository);

  final DonorRepository _repository;

  Stream<DonorMetrics> call(String donorId) =>
      _repository.watchMetrics(donorId);
}
