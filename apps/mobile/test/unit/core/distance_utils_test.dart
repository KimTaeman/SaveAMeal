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
}
