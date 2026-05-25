import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  const DriverRepositoryImpl(this._datasource);

  // ignore: unused_field
  final DriverRemoteDatasource _datasource;

  @override
  Stream<List<BatchSummary>> getOpenBatches() {
    // TODO: implement via _datasource
    throw UnimplementedError('getOpenBatches');
  }

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) {
    // TODO: implement via _datasource
    throw UnimplementedError('getActiveBatch');
  }

  @override
  Future<void> claimBatch(String batchId, String driverId) {
    // TODO: implement via _datasource
    throw UnimplementedError('claimBatch');
  }

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) {
    // TODO: implement via _datasource
    throw UnimplementedError('confirmPickup');
  }

  @override
  Future<void> confirmDelivery(String batchId, String? notes) {
    // TODO: implement via _datasource
    throw UnimplementedError('confirmDelivery');
  }

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) {
    // TODO: implement via _datasource
    throw UnimplementedError('upsertLocation');
  }

  @override
  Stream<int> watchPoints(String uid) {
    // TODO: implement via _datasource
    throw UnimplementedError('watchPoints');
  }
}
