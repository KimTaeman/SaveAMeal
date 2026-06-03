import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_impact_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/data/repositories/firestore_beneficiary_impact_repository.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_beneficiary_impact_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'beneficiary_impact_provider.g.dart';

@riverpod
BeneficiaryImpactRemoteDatasource beneficiaryImpactRemoteDatasource(Ref ref) =>
    BeneficiaryImpactRemoteDatasourceImpl(
      ref.watch(firestoreServiceProvider).db,
    );

@riverpod
BeneficiaryImpactRepository beneficiaryImpactRepository(Ref ref) =>
    FirestoreBeneficiaryImpactRepository(
      ref.watch(beneficiaryImpactRemoteDatasourceProvider),
    );

@riverpod
WatchBeneficiaryImpactUsecase watchBeneficiaryImpactUsecase(Ref ref) =>
    WatchBeneficiaryImpactUsecase(
      ref.watch(beneficiaryImpactRepositoryProvider),
    );

@riverpod
Stream<BeneficiaryImpact> beneficiaryImpact(Ref ref, String beneficiaryId) =>
    ref.watch(watchBeneficiaryImpactUsecaseProvider).call(beneficiaryId);
