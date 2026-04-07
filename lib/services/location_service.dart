// ignore_for_file: avoid_print

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Сервіс для роботи з геолокацією
class LocationService {
  /// Перевірити чи дозволені дозволи на геолокацію
  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Перевірка чи увімкнена служба геолокації
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Отримати поточні координати
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Помилка отримання позиції: $e');
      return null;
    }
  }

  /// Отримати назву міста за координатами
  Future<String?> getCityName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return place.locality ?? place.administrativeArea ?? 'Unknown';
      }
      return null;
    } catch (e) {
      print('Помилка отримання назви міста: $e');
      return null;
    }
  }

  /// Отримати координати за назвою міста
  Future<Location?> getCoordinatesFromCity(String cityName) async {
    try {
      final locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      print('Помилка отримання координат: $e');
      return null;
    }
  }
}
