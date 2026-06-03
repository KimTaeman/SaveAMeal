import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';

abstract class DriverProfileRepository {
  /// Fetches the driver profile from the remote datasource.
  /// Throws on network failure.
  Future<DriverProfile> getProfile(String uid);

  /// Persists all editable fields to the remote datasource and updates the
  /// local Hive cache.
  Future<void> updateProfile(DriverProfile profile);

  /// Uploads a local image file to Firebase Storage and returns the download
  /// URL. Does NOT write the URL back to Firestore — caller must follow up
  /// with [updateProfile].
  Future<String> uploadAvatar(String uid, String localFilePath);

  /// Returns the last-cached profile from Hive, or null if cache is empty.
  /// Never throws.
  Future<DriverProfile?> getCachedProfile(String uid);
}
