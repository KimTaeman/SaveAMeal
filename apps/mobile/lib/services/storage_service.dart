import 'package:firebase_storage/firebase_storage.dart';

/// Wraps Firebase Storage. All methods throw [UnimplementedError] until wired up.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a batch photo from [filePath] and returns the download URL.
  Future<String> uploadBatchPhoto(String batchId, String filePath) =>
      // TODO: implement
      throw UnimplementedError('uploadBatchPhoto not implemented');
}
