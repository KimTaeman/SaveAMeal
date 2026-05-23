import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/donor/data/datasources/donor_remote_datasource.dart';
import 'package:saveameal/features/donor/data/repositories/donor_repository_impl.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/create_batch_usecase.dart';
import 'package:saveameal/features/donor/domain/usecases/get_donor_metrics_usecase.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_active_batches_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'donor_provider.g.dart';

@riverpod
DonorRemoteDatasource donorRemoteDatasource(Ref ref) =>
    DonorRemoteDatasourceImpl(ref.watch(firestoreServiceProvider));

@riverpod
DonorRepository donorRepository(Ref ref) =>
    DonorRepositoryImpl(ref.watch(donorRemoteDatasourceProvider));

@riverpod
WatchActiveBatchesUsecase watchActiveBatchesUsecase(Ref ref) =>
    WatchActiveBatchesUsecase(ref.watch(donorRepositoryProvider));

@riverpod
GetDonorMetricsUsecase getDonorMetricsUsecase(Ref ref) =>
    GetDonorMetricsUsecase(ref.watch(donorRepositoryProvider));

@riverpod
CreateBatchUsecase createBatchUsecase(Ref ref) =>
    CreateBatchUsecase(ref.watch(donorRepositoryProvider));

@riverpod
Stream<List<Batch>> activeBatches(Ref ref, String donorId) =>
    ref.watch(watchActiveBatchesUsecaseProvider).call(donorId);

@riverpod
Stream<DonorMetrics> donorMetrics(Ref ref, String donorId) =>
    ref.watch(getDonorMetricsUsecaseProvider).call(donorId);
