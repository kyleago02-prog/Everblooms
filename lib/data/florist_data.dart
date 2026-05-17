// lib/data/florist_data.dart
import 'package:latlong2/latlong.dart';

class FloristLocation {
  final String name;
  final LatLng point;
  const FloristLocation({required this.name, required this.point});
}

class FloristData {
  static const List<FloristLocation> florists = [
    FloristLocation(name: 'Digos City Proper', point: LatLng(6.7621, 125.2891)),
    FloristLocation(name: 'Zone I',            point: LatLng(6.7640, 125.2880)),
    FloristLocation(name: 'Zone II',           point: LatLng(6.7600, 125.2900)),
    FloristLocation(name: 'Zone III',          point: LatLng(6.7650, 125.2920)),
    FloristLocation(name: 'Aplaya',            point: LatLng(6.7580, 125.2820)),
    FloristLocation(name: 'Goma',              point: LatLng(6.7700, 125.2850)),
    FloristLocation(name: 'Igpit',             point: LatLng(6.7550, 125.2950)),
    FloristLocation(name: 'Kapatagan',         point: LatLng(6.7800, 125.2700)),
    FloristLocation(name: 'Matti',             point: LatLng(6.7500, 125.3000)),
    FloristLocation(name: 'San Miguel',        point: LatLng(6.7450, 125.3050)),
    FloristLocation(name: 'Sulop Road',        point: LatLng(6.7700, 125.2950)),
    FloristLocation(name: 'Roxas Street',      point: LatLng(6.7620, 125.2910)),
    FloristLocation(name: 'Quezon Avenue',     point: LatLng(6.7610, 125.2905)),
    FloristLocation(name: 'Rizal Avenue',      point: LatLng(6.7630, 125.2885)),
  ];

  /// Helper to get a FloristLocation by its name (case‑insensitive)
  static FloristLocation? getByName(String name) {
    try {
      return florists.firstWhere(
            (f) => f.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}