import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/core/utils/distance_utils.dart';

void main() {
  group('haversineKm', () {
    test('returns 0.0 for identical coordinates', () {
      final result = haversineKm(13.7563, 100.5018, 13.7563, 100.5018);
      expect(result, closeTo(0.0, 0.001));
    });

    test('returns ~5571 km between Bangkok and London', () {
      // Bangkok: 13.7563° N, 100.5018° E
      // London:  51.5074° N,   0.1278° W
      final result = haversineKm(13.7563, 100.5018, 51.5074, -0.1278);
      expect(result, closeTo(9547.0, 50.0));
    });

    test('returns ~2 km for a short known distance', () {
      // Two points ~2 km apart near Bangkok city centre
      // Starting point: 13.7500, 100.5000
      // ~2 km north:    13.7680, 100.5000
      final result = haversineKm(13.7500, 100.5000, 13.7680, 100.5000);
      expect(result, closeTo(2.0, 0.1));
    });

    test('is symmetric — swap lat/lng gives same distance', () {
      final d1 = haversineKm(13.7563, 100.5018, 18.7961, 98.9625);
      final d2 = haversineKm(18.7961, 98.9625, 13.7563, 100.5018);
      expect(d1, closeTo(d2, 0.001));
    });

    test('handles negative (southern hemisphere) latitudes', () {
      // Sydney: -33.8688° N, 151.2093° E
      // Melbourne: -37.8136° N, 144.9631° E
      final result = haversineKm(-33.8688, 151.2093, -37.8136, 144.9631);
      expect(result, closeTo(714.0, 10.0));
    });

    test('handles antipodal points (max ~20015 km)', () {
      final result = haversineKm(0.0, 0.0, 0.0, 180.0);
      expect(result, closeTo(20015.0, 10.0));
    });
  });

  group('etaMinutes', () {
    test('returns at least 1 minute for identical coordinates', () {
      // Zero distance → zero travel time, but the function guarantees ≥ 1.
      final result = etaMinutes(13.7563, 100.5018, 13.7563, 100.5018);
      expect(result, 1);
    });

    test('calculates correct minutes for a known distance', () {
      // ~2 km apart at 30 km/h with 1.4 road factor:
      // 2 * 1.4 / 30 * 60 = 5.6 → ceiling → 6 minutes.
      final result = etaMinutes(13.7500, 100.5000, 13.7680, 100.5000);
      expect(result, 6);
    });

    test('ceiling-rounds fractional minutes upward', () {
      // 1 km * 1.4 / 30 km/h * 60 = 2.8 min → ceil → 3
      // ~1 km north: 13.7563 + 0.009 ≈ 13.7653
      final result = etaMinutes(13.7563, 100.5018, 13.7653, 100.5018);
      expect(result, greaterThanOrEqualTo(1));
      expect(result, isA<int>());
    });

    test('custom avgSpeedKmh is applied', () {
      // Halving speed doubles the ETA.
      final fast = etaMinutes(
        13.7500,
        100.5000,
        13.7680,
        100.5000,
        avgSpeedKmh: 60.0,
      );
      final slow = etaMinutes(
        13.7500,
        100.5000,
        13.7680,
        100.5000,
        avgSpeedKmh: 30.0,
      );
      expect(slow, greaterThan(fast));
    });

    test('custom roadFactor is applied', () {
      // Higher road factor → longer effective distance → more minutes.
      final straight = etaMinutes(
        13.7500,
        100.5000,
        13.7680,
        100.5000,
        roadFactor: 1.0,
      );
      final detour = etaMinutes(
        13.7500,
        100.5000,
        13.7680,
        100.5000,
        roadFactor: 2.0,
      );
      expect(detour, greaterThan(straight));
    });

    test('returns an int (whole minutes only)', () {
      final result = etaMinutes(13.7563, 100.5018, 18.7961, 98.9625);
      expect(result, isA<int>());
    });
  });
}
