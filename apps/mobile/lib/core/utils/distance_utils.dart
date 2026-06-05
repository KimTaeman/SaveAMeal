// Pure Dart — zero Flutter imports.
import 'dart:math';

/// Returns the great-circle distance in kilometres between two geographic
/// coordinates using the Haversine formula.
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * pi / 180.0;

/// Returns the estimated travel time in whole minutes from the driver's position
/// to [destLat]/[destLng].
///
/// The straight-line Haversine distance is inflated by [roadFactor] (default
/// 1.4 — typical urban detour ratio) and divided by [avgSpeedKmh] (default
/// 30 km/h — conservative Bangkok urban average). The result is ceiling-rounded
/// so the displayed ETA is always the pessimistic (safer) value. Returns at
/// least 1 minute so the UI never shows "0 min".
int etaMinutes(
  double driverLat,
  double driverLng,
  double destLat,
  double destLng, {
  double avgSpeedKmh = 30.0,
  double roadFactor = 1.4,
}) {
  final distKm = haversineKm(driverLat, driverLng, destLat, destLng);
  final travelHours = (distKm * roadFactor) / avgSpeedKmh;
  final minutes = (travelHours * 60).ceil();
  return minutes < 1 ? 1 : minutes;
}
