import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadBatchPhoto(
    String batchId,
    String itemIndex,
    File photo,
  ) async {
    final ref = _storage.ref().child('batches/$batchId/items/$itemIndex.jpg');
    await ref.putFile(photo);
    return ref.getDownloadURL();
  }

  Future<String> uploadPickupPhoto(String batchId, XFile photo) async {
    final ref = _storage.ref().child('batch_photos/$batchId/pickup.jpg');
    await ref.putData(await photo.readAsBytes());
    return ref.getDownloadURL();
  }
}
