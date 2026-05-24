import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  test('Geolocator distance test', () {
    // Lisbon coordinates used for test
    double distance = Geolocator.distanceBetween(38.7223, -9.1393, 38.7224, -9.1394);
    expect(distance, greaterThan(0));
  });
}
