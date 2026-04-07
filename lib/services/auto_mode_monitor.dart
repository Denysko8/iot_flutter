// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'dart:async';

import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/services/service_locator.dart';
import 'package:iot_flutter/services/time_service.dart';
import 'package:iot_flutter/services/weather_service.dart';

/// Сервіс для автоматичного моніторингу погоди та часу
class AutoModeMonitor {
  final WeatherService _weatherService;
  final TimeService _timeService;

  Timer? _weatherCheckTimer;
  Timer? _timeCheckTimer;

  WeatherData? _lastWeatherData;
  DateTime? _lastWeatherCheck;

  // Callbacks
  void Function(int position)? onPositionChange;
  void Function(String message)? onStatusUpdate;

  AutoModeMonitor()
    : _weatherService = ServiceLocator().weatherService,
      _timeService = ServiceLocator().timeService;

  /// Запустити моніторинг автоматичних режимів
  void startMonitoring({
    required AutoModeSettings settings,
    required double? latitude,
    required double? longitude,
  }) {
    stopMonitoring();

    // Перевірка погоди кожні 15 хвилин
    if (settings.weatherControlEnabled &&
        latitude != null &&
        longitude != null) {
      _checkWeather(settings, latitude, longitude);
      _weatherCheckTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => _checkWeather(settings, latitude, longitude),
      );
    }

    // Перевірка температури кожні 10 хвилин
    if (settings.temperatureControlEnabled &&
        latitude != null &&
        longitude != null) {
      _checkTemperature(settings, latitude, longitude);
      _timeCheckTimer = Timer.periodic(
        const Duration(minutes: 10),
        (_) => _checkTemperature(settings, latitude, longitude),
      );
    }

    // Перевірка часу для wakey режиму кожну хвилину
    if (settings.wakeySensors) {
      _checkWakeyTime(settings, latitude, longitude);
      Timer.periodic(
        const Duration(minutes: 1),
        (_) => _checkWakeyTime(settings, latitude, longitude),
      );
    }
  }

  /// Зупинити моніторинг
  void stopMonitoring() {
    _weatherCheckTimer?.cancel();
    _timeCheckTimer?.cancel();
    _weatherCheckTimer = null;
    _timeCheckTimer = null;
  }

  /// Перевірити погоду та визначити чи потрібно закрити вікно
  Future<void> _checkWeather(
    AutoModeSettings settings,
    double latitude,
    double longitude,
  ) async {
    try {
      final weather = await _weatherService.getCurrentWeather(
        latitude,
        longitude,
      );
      if (weather == null) return;

      _lastWeatherData = weather;
      _lastWeatherCheck = DateTime.now();

      // Перевірити чи є небезпечні погодні умови
      final hasHazard = _weatherService.hasHazardousConditions(
        weather,
        settings.selectedWeathers,
      );

      if (hasHazard) {
        // Закрити вікно до вказаного відсотка
        final targetPosition = settings.weatherClosurePercent.round();
        onPositionChange?.call(targetPosition);

        final conditions = weather.conditions.join(', ');
        onStatusUpdate?.call(
          'Погода: $conditions. Закриття до $targetPosition%',
        );
      }
    } catch (e) {
      print('Помилка перевірки погоди: $e');
    }
  }

  /// Перевірити температуру та визначити чи потрібно закрити вікно
  Future<void> _checkTemperature(
    AutoModeSettings settings,
    double latitude,
    double longitude,
  ) async {
    try {
      final weather = await _weatherService.getCurrentWeather(
        latitude,
        longitude,
      );
      if (weather == null) return;

      if (weather.temperature > settings.temperatureThreshold) {
        // Закрити вікно до вказаного відсотка
        final targetPosition = settings.temperatureClosurePercent.round();
        onPositionChange?.call(targetPosition);

        onStatusUpdate?.call(
          'Температура ${weather.temperature.toStringAsFixed(1)}°C > ${settings.temperatureThreshold}°C. '
          'Закриття до $targetPosition%',
        );
      }
    } catch (e) {
      print('Помилка перевірки температури: $e');
    }
  }

  /// Перевірити чи настав час для wakey режиму
  void _checkWakeyTime(
    AutoModeSettings settings,
    double? latitude,
    double? longitude,
  ) {
    if (!settings.wakeySensors) return;

    final customTime =
        settings.wakeAtSunriseTime
            ? null
            : DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              settings.wakeTime.hour,
              settings.wakeTime.minute,
            );

    final isTime = _timeService.isTimeForWakey(
      atDawnMode: settings.wakeAtSunriseTime,
      customTime: customTime,
      minutesBefore: settings.wakeMinutesBefore,
      latitude: latitude,
      longitude: longitude,
    );

    if (isTime) {
      // Відкрити вікно на 100%
      onPositionChange?.call(100);
      onStatusUpdate?.call('Wakey: Відкриття вікна');
    }
  }

  /// Отримати останні дані про погоду
  WeatherData? get lastWeatherData => _lastWeatherData;

  /// Отримати час останньої перевірки погоди
  DateTime? get lastWeatherCheck => _lastWeatherCheck;

  /// Очистити ресурси
  void dispose() {
    stopMonitoring();
  }
}
