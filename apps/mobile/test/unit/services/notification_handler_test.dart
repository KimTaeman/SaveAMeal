import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/services/notification_handler.dart';

void main() {
  group('NotificationHandler.routeForType', () {
    test('new_batch → /driver', () {
      expect(NotificationHandler.routeForType('new_batch'), '/driver');
    });

    test('driver_assigned → /donor', () {
      expect(NotificationHandler.routeForType('driver_assigned'), '/donor');
    });

    test('incoming_delivery → /beneficiary', () {
      expect(
        NotificationHandler.routeForType('incoming_delivery'),
        '/beneficiary',
      );
    });

    test('delivery_arrived → /beneficiary', () {
      expect(
        NotificationHandler.routeForType('delivery_arrived'),
        '/beneficiary',
      );
    });

    test('unknown type → null', () {
      expect(NotificationHandler.routeForType('something_else'), isNull);
    });

    test('null → null', () {
      expect(NotificationHandler.routeForType(null), isNull);
    });
  });
}
