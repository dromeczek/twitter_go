import 'dart:math';

double _deg2rad(double deg) => deg * (pi / 180.0);

/// Dystans w metrach między dwoma punktami (Haversine)
double distanceMeters({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const R = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) *
          cos(_deg2rad(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}
