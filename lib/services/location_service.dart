import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services disabled. (Emulator: Extended Controls → Location → Set location)');
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) throw Exception('Location permission denied.');
    if (perm == LocationPermission.deniedForever) throw Exception('Location permission denied forever.');

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
