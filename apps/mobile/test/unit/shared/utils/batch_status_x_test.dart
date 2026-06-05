import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/shared/domain/entities/batch_status.dart';
import 'package:saveameal/shared/utils/batch_status_x.dart';

void main() {
  group('BatchStatusX.label', () {
    test('open returns Pending', () {
      expect(BatchStatus.open.label, 'Pending');
    });

    test('claimed returns Claimed', () {
      expect(BatchStatus.claimed.label, 'Claimed');
    });

    test('pickedUp returns Collected', () {
      expect(BatchStatus.pickedUp.label, 'Collected');
    });

    test('delivered returns Delivered', () {
      expect(BatchStatus.delivered.label, 'Delivered');
    });

    test('closed returns Completed', () {
      expect(BatchStatus.closed.label, 'Completed');
    });

    test('cancelled returns Cancelled', () {
      expect(BatchStatus.cancelled.label, 'Cancelled');
    });

    test('all 6 values are covered without throwing', () {
      for (final status in BatchStatus.values) {
        expect(() => status.label, returnsNormally);
      }
    });
  });

  group('BatchStatusX.isActive', () {
    test('open is active', () => expect(BatchStatus.open.isActive, isTrue));
    test(
      'claimed is active',
      () => expect(BatchStatus.claimed.isActive, isTrue),
    );
    test(
      'pickedUp is active',
      () => expect(BatchStatus.pickedUp.isActive, isTrue),
    );
    test(
      'delivered is not active',
      () => expect(BatchStatus.delivered.isActive, isFalse),
    );
    test(
      'closed is not active',
      () => expect(BatchStatus.closed.isActive, isFalse),
    );
    test(
      'cancelled is not active',
      () => expect(BatchStatus.cancelled.isActive, isFalse),
    );
  });

  group('BatchStatusX.isDone', () {
    test(
      'delivered is done',
      () => expect(BatchStatus.delivered.isDone, isTrue),
    );
    test('closed is done', () => expect(BatchStatus.closed.isDone, isTrue));
    test('open is not done', () => expect(BatchStatus.open.isDone, isFalse));
    test(
      'claimed is not done',
      () => expect(BatchStatus.claimed.isDone, isFalse),
    );
    test(
      'pickedUp is not done',
      () => expect(BatchStatus.pickedUp.isDone, isFalse),
    );
    test(
      'cancelled is not done',
      () => expect(BatchStatus.cancelled.isDone, isFalse),
    );
  });

  group('isActive and isDone are mutually exclusive', () {
    test('no status can be both active and done', () {
      for (final status in BatchStatus.values) {
        expect(
          status.isActive && status.isDone,
          isFalse,
          reason: '${status.name} must not be both active and done',
        );
      }
    });
  });
}
