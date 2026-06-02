import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/domain/usecases/get_active_batch_usecase.dart';
import 'package:saveameal/features/driver/domain/usecases/get_open_batches_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'driver_provider.g.dart';

@riverpod
DriverRemoteDatasource driverRemoteDatasource(Ref ref) =>
    DriverRemoteDatasourceImpl(
      ref.watch(firestoreServiceProvider),
      ref.watch(storageServiceProvider),
    );

@riverpod
DriverRepository driverRepository(Ref ref) =>
    DriverRepositoryImpl(ref.watch(driverRemoteDatasourceProvider));

@riverpod
GetOpenBatchesUsecase getOpenBatchesUsecase(Ref ref) =>
    GetOpenBatchesUsecase(ref.watch(driverRepositoryProvider));

@riverpod
GetActiveBatchUsecase getActiveBatchUsecase(Ref ref) =>
    GetActiveBatchUsecase(ref.watch(driverRepositoryProvider));

@riverpod
Stream<List<BatchSummary>> openBatches(Ref ref) =>
    ref.watch(getOpenBatchesUsecaseProvider).call();

@riverpod
Stream<BatchSummary?> activeBatchForDriver(Ref ref, String driverId) =>
    ref.watch(getActiveBatchUsecaseProvider).call(driverId);
