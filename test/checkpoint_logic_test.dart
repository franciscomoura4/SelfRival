import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  test('Geolocator distance check', () {
    double distance = Geolocator.distanceBetween(38.7223, -9.1393, 38.7224, -9.1394);
    expect(distance, greaterThan(0));
    print('Distance: $distance meters');
  });
}
