import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/core/models/batch_item_model.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart'
    show BatchStatus;
import 'package:saveameal/features/beneficiary/data/models/intake_request_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';

void main() {
  final expiry = DateTime(2026, 12, 31);

  BatchModel makeBatch({
    List<BatchItemModel> items = const [],
    String? donorName,
    String status = 'pickedUp',
    String? driverId,
    String? volunteerName,
    int? estimatedArrivalMinutes,
  }) => BatchModel(
    id: 'b_001',
    donorId: 'donor_001',
    donorName: donorName,
    pickupAddress: '123 Test St',
    status: BatchStatus.values.firstWhere((s) => s.name == status),
    driverId: driverId,
    volunteerName: volunteerName,
    estimatedArrivalMinutes: estimatedArrivalMinutes,
    beneficiaryId: 'ben_001',
    items: items,
  );

  BatchItemModel makeItem(String name, String category, double weight) =>
      BatchItemModel(
        name: name,
        category: category,
        weightKg: weight,
        expiryTime: expiry,
      );

  group('batchModelToDetailDomain mapper', () {
    test('maps each BatchItemModel to IntakeItem correctly', () {
      final batch = makeBatch(
        items: [
          makeItem('Rice', 'grain', 2.0),
          makeItem('Chicken', 'meat', 3.5),
        ],
      );

      final detail = batchModelToDetailDomain(batch);

      expect(detail.items.length, 2);
      expect(detail.items[0].name, 'Rice');
      expect(detail.items[0].category, 'grain');
      expect(detail.items[0].weightKg, 2.0);
      expect(detail.items[1].name, 'Chicken');
      expect(detail.items[1].category, 'meat');
      expect(detail.items[1].weightKg, 3.5);
    });

    test('empty items list maps to empty List<IntakeItem>', () {
      final batch = makeBatch(items: []);
      final detail = batchModelToDetailDomain(batch);

      expect(detail.items, isEmpty);
    });

    test('donorName is populated from batch.donorName', () {
      final batch = makeBatch(donorName: 'Central Bakery');
      final detail = batchModelToDetailDomain(batch);

      expect(detail.donorName, 'Central Bakery');
    });

    test('donorName is null when batch.donorName is null', () {
      final batch = makeBatch(donorName: null);
      final detail = batchModelToDetailDomain(batch);

      expect(detail.donorName, isNull);
    });

    test('portions equals items.length', () {
      final items = [
        makeItem('A', 'cat', 1.0),
        makeItem('B', 'cat', 1.0),
        makeItem('C', 'cat', 1.0),
      ];
      final batch = makeBatch(items: items);
      final detail = batchModelToDetailDomain(batch);

      expect(detail.portions, items.length);
    });

    test('weightKg equals sum of item weights', () {
      final items = [
        makeItem('A', 'cat', 1.5),
        makeItem('B', 'cat', 2.5),
        makeItem('C', 'cat', 3.0),
      ];
      final batch = makeBatch(items: items);
      final detail = batchModelToDetailDomain(batch);

      const expectedWeight = 1.5 + 2.5 + 3.0;
      expect(detail.weightKg, closeTo(expectedWeight, 0.001));
    });

    test('volunteerId is populated from batch.driverId', () {
      final batch = makeBatch(driverId: 'driver_42');
      final detail = batchModelToDetailDomain(batch);

      expect(detail.volunteerId, 'driver_42');
    });

    test('estimatedArrivalMinutes is passed through from batch', () {
      final batch = makeBatch(estimatedArrivalMinutes: 18);
      final detail = batchModelToDetailDomain(batch);

      expect(detail.estimatedArrivalMinutes, 18);
    });

    test('estimatedArrivalMinutes is null when batch field is null', () {
      final batch = makeBatch();
      final detail = batchModelToDetailDomain(batch);

      expect(detail.estimatedArrivalMinutes, isNull);
    });

    test('status maps correctly from BatchStatus to IntakeStatus', () {
      final cases = {
        'open': IntakeStatus.open,
        'claimed': IntakeStatus.dispatched,
        'pickedUp': IntakeStatus.dispatched,
        'delivered': IntakeStatus.delivered,
        'closed': IntakeStatus.closed,
        'cancelled': IntakeStatus.cancelled,
      };

      for (final entry in cases.entries) {
        final batch = makeBatch(status: entry.key);
        final detail = batchModelToDetailDomain(batch);
        expect(
          detail.status,
          entry.value,
          reason: 'BatchStatus.${entry.key} should map to ${entry.value}',
        );
      }
    });
  });
}
