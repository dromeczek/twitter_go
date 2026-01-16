import 'package:geolocator/geolocator.dart';

class AppLocation {
  final double lat;
  final double lng;
  const AppLocation(this.lat, this.lng);
}

class LocationService {
  // fallback do demo (Rynek Główny, Kraków)
  static const AppLocation fallback = AppLocation(50.06465, 19.94498);

  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<AppLocation> getCurrent() async {
    final ok = await ensurePermission();
    if (!ok) return fallback;

    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return AppLocation(p.latitude, p.longitude);
  }
}
