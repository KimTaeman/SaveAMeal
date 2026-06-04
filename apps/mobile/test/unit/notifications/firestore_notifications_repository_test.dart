import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/notifications/data/repositories/firestore_notifications_repository.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FirestoreNotificationsRepository repo;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = FirestoreNotificationsRepository(fakeDb);
  });

  Future<void> seedNotification(
    String uid,
    String id,
    String type, {
    bool isRead = false,
    String? actionBatchId,
  }) => fakeDb
      .collection('notifications')
      .doc(uid)
      .collection('items')
      .doc(id)
      .set({
        'type': type,
        'title': 'Test title',
        'body': 'Test body',
        'timestamp': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'isRead': isRead,
        'actionBatchId': ?actionBatchId,
      });

  test('watchAll emits notifications for the given uid', () async {
    await seedNotification('user1', 'n1', 'new_batch');
    await seedNotification('user1', 'n2', 'driver_assigned');
    await seedNotification('user2', 'n3', 'new_batch');

    final list = await repo.watchAll('user1').first;
    expect(list.length, 2);
    expect(list.map((n) => n.id), containsAll(['n1', 'n2']));
    expect(list.map((n) => n.id), isNot(contains('n3')));
  });

  test('watchAll maps type strings to NotificationType enum', () async {
    await seedNotification('u', 'a', 'new_batch');
    await seedNotification('u', 'b', 'driver_assigned');
    await seedNotification('u', 'c', 'incoming_delivery');
    await seedNotification('u', 'd', 'delivery_arrived');

    final list = await repo.watchAll('u').first;
    final types = {for (final n in list) n.id: n.type};
    expect(types['a'], NotificationType.newBatch);
    expect(types['b'], NotificationType.driverAssigned);
    expect(types['c'], NotificationType.deliveryArriving);
    expect(types['d'], NotificationType.deliverySuccessful);
  });

  test('markRead sets isRead to true in Firestore', () async {
    await seedNotification('u', 'n1', 'new_batch', isRead: false);

    await repo.markRead('u', 'n1');

    final doc = await fakeDb
        .collection('notifications')
        .doc('u')
        .collection('items')
        .doc('n1')
        .get();
    expect(doc.data()?['isRead'], isTrue);
  });

  test('markAllRead sets all items to isRead true', () async {
    await seedNotification('u', 'n1', 'new_batch', isRead: false);
    await seedNotification('u', 'n2', 'driver_assigned', isRead: false);
    await seedNotification('u', 'n3', 'delivery_arrived', isRead: true);

    await repo.markAllRead('u');

    final qs = await fakeDb
        .collection('notifications')
        .doc('u')
        .collection('items')
        .get();
    for (final doc in qs.docs) {
      expect(doc.data()['isRead'], isTrue);
    }
  });
}
