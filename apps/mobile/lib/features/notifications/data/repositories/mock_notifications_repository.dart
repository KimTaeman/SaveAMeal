import 'dart:async';

import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    _items = [
      AppNotification(
        id: '1',
        type: NotificationType.deliveryArriving,
        title: 'Driver Arriving Soon',
        body: 'Nattapong is 5 minutes away with your delivery.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        type: NotificationType.matchConfirmed,
        title: 'Match Confirmed! Batch #8492 is assigned to Haven Shelter.',
        body: 'Driver on the way.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      AppNotification(
        id: '3',
        type: NotificationType.deliverySuccessful,
        title: 'Delivery Successful! Haven Shelter received your bakery batch.',
        body: 'You saved 37.5kg of CO2!',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        type: NotificationType.deliverySuccessful,
        title: 'Delivery Successful',
        body: '38 portions of bakery goods were dropped off by Nattapong.',
        timestamp: yesterday.copyWith(hour: 14, minute: 45),
        isRead: true,
        actionLabel: 'View Receipt',
        actionBatchId: '8832',
      ),
      AppNotification(
        id: '5',
        type: NotificationType.batchCompleted,
        title: 'Batch #8411 Completed.',
        body: 'Your batch has been completed successfully.',
        timestamp: yesterday.copyWith(hour: 10, minute: 0),
        isRead: true,
      ),
    ];
    _controller.add(List.unmodifiable(_items));
  }

  late List<AppNotification> _items;
  final _controller = StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchAll(String uid) => _controller.stream;

  @override
  Future<void> markRead(String uid, String id) async {
    _items = _items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> markAllRead(String uid) async {
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    _controller.add(List.unmodifiable(_items));
  }
}
