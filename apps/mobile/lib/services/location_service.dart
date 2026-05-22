import 'package:geolocator/geolocator.dart';

/// Wraps geolocator. All methods throw [UnimplementedError] until wired up.
class LocationService {
  // TODO: handle permissions before calling geolocator methods

  /// Returns the device's current position.
  Future<Position> getCurrentPosition() =>
      // TODO: implement
      throw UnimplementedError('getCurrentPosition not implemented');

  /// Streams continuous position updates from the device.
  Stream<Position> getPositionStream() =>
      // TODO: implement
      throw UnimplementedError('getPositionStream not implemented');
}
