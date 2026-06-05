import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/core/constants/firestore_constants.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _items(String uid) => _db
      .collection(FirestoreConstants.notifications)
      .doc(uid)
      .collection(FirestoreConstants.notificationItems);

  @override
  Stream<List<AppNotification>> watchAll(String uid) => _items(uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((qs) => qs.docs.map(_fromDoc).toList());

  @override
  Future<void> markRead(String uid, String id) =>
      _items(uid).doc(id).update({'isRead': true});

  @override
  Future<void> markAllRead(String uid) async {
    final qs = await _items(uid).where('isRead', isEqualTo: false).get();
    if (qs.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in qs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  AppNotification _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppNotification(
      id: doc.id,
      type: _typeFrom(data['type'] as String? ?? ''),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      actionLabel: data['actionLabel'] as String?,
      actionBatchId: data['actionBatchId'] as String?,
    );
  }

  NotificationType _typeFrom(String type) => switch (type) {
    'new_batch' => NotificationType.newBatch,
    'driver_assigned' => NotificationType.driverAssigned,
    'incoming_delivery' => NotificationType.deliveryArriving,
    'delivery_arrived' => NotificationType.deliverySuccessful,
    _ => NotificationType.newBatch,
  };
}
