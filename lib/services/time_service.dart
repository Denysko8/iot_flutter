// ignore_for_file: lines_longer_than_80_chars, avoid_redundant_argument_values

import 'package:intl/intl.dart';

/// Сервіс для роботи з часом та розрахунку світанку
class TimeService {
  /// Отримати поточний час у форматі HH:mm
  String getCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  /// Отримати поточний DateTime
  DateTime getCurrentDateTime() {
    return DateTime.now();
  }

  /// Розрахувати час світанку для заданої дати та координат
  /// Використовує спрощену формулу для розрахунку часу світанку
  DateTime calculateSunrise(DateTime date, double latitude, double longitude) {
    // Спрощений розрахунок світанку
    // Для більш точного розрахунку можна використати бібліотеку sunrise_sunset_calc

    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final latRad = latitude * (3.14159 / 180);

    // Розрахунок declination (схилення сонця)
    final declination = 0.4095 * (3.14159 / 180) * (dayOfYear - 81).toDouble();

    // Розрахунок годинного кута світанку
    final cosHourAngle =
        ((-0.01454).toDouble() - (latRad * declination)) /
        ((1 - latRad * latRad) * (1 - declination * declination));

    var hourAngle = 0.0;
    if (cosHourAngle.abs() <= 1) {
      hourAngle = (180 / 3.14159) * (cosHourAngle);
    }

    // Розрахунок локального часу світанку
    final solarNoon = 12 - (longitude / 15);
    final sunriseTime = solarNoon - (hourAngle / 15);

    // Конвертація у години та хвилини
    final hour = sunriseTime.floor();
    final minute = ((sunriseTime - hour) * 60).floor();

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Розрахувати час для відкриття вікна перед світанком
  /// [sunrise] - час світанку
  /// [minutesBefore] - скільки хвилин до світанку відкривати вікно
  DateTime calculateWakeyTime(DateTime sunrise, int minutesBefore) {
    return sunrise.subtract(Duration(minutes: minutesBefore));
  }

  /// Перевірити чи настав час для wakey режиму
  bool isTimeForWakey({
    required bool atDawnMode,
    required DateTime? customTime,
    required int minutesBefore,
    required double? latitude,
    required double? longitude,
  }) {
    final now = DateTime.now();
    DateTime targetTime;

    if (atDawnMode) {
      if (latitude == null || longitude == null) {
        return false;
      }
      final sunrise = calculateSunrise(now, latitude, longitude);
      targetTime = calculateWakeyTime(sunrise, minutesBefore);
    } else {
      if (customTime == null) {
        return false;
      }
      targetTime = DateTime(
        now.year,
        now.month,
        now.day,
        customTime.hour,
        customTime.minute,
      ).subtract(Duration(minutes: minutesBefore));
    }

    // Перевірка чи поточний час у межах 5 хвилин від цільового часу
    final difference = now.difference(targetTime).abs();
    return difference.inMinutes <= 5;
  }

  /// Форматувати TimeOfDay у String
  String formatTimeOfDay(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Парсити рядок часу у години та хвилини
  Map<String, int> parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return {'hour': int.parse(parts[0]), 'minute': int.parse(parts[1])};
  }
}
