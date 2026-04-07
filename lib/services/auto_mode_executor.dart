// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'dart:async';
import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/services/service_locator.dart';

/// Сервіс для виконання автоматичних режимів через MQTT команди до ESP8266
class AutoModeExecutor {
  Timer? _wakeyTimer;
  Timer? _checkTimer;
  DateTime? _lastWakeyExecution;
  DateTime? _cachedSunriseDate;
  DateTime? _cachedSunriseTime;
  AutoModeSettings? _wakeySettings;

  bool _isRunning = false;

  /// Синхронізувати фоновий Wakey планувальник без збереження налаштувань
  void syncWakeyBackground(AutoModeSettings settings) {
    _isRunning = true;

    if (!settings.wakeySensors) {
      _wakeyTimer?.cancel();
      _wakeyTimer = null;
      print('AutoModeExecutor: Wakey вимкнено, фоновий таймер зупинено');
      return;
    }

    _startWakeyScheduler(settings);
  }

  /// Запустити виконання автоматичних режимів
  Future<void> executeAutoModes(AutoModeSettings settings) async {
    _isRunning = true;

    print('AutoModeExecutor: Запуск автоматичних режимів через MQTT');

    // Зупинити попередні таймери
    _wakeyTimer?.cancel();
    _checkTimer?.cancel();
    _lastWakeyExecution = null;

    // 1. Wakey - запуск/синхронізація перевірки за часовим вікном
    syncWakeyBackground(settings);

    // 2. Temperature & Weather - відправити команду виконання на ESP8266
    if (settings.temperatureControlEnabled || settings.weatherControlEnabled) {
      await _sendTempWeatherExecuteCommand(settings);
    }
  }

  /// Запустити перевірку Wakey кожну хвилину
  void _startWakeyScheduler(AutoModeSettings settings) {
    _wakeySettings = settings;
    _wakeyTimer?.cancel();
    _checkAndExecuteWakey(settings);
    _wakeyTimer = Timer.periodic(const Duration(minutes: 1), _handleWakeyTick);
  }

  void _handleWakeyTick(Timer _) {
    final settings = _wakeySettings;
    if (settings == null) {
      return;
    }
    _checkAndExecuteWakey(settings);
  }

  /// Перевірити вікно Wakey і виконати одноразово в межах вікна
  Future<void> _checkAndExecuteWakey(AutoModeSettings settings) async {
    if (!_isRunning) {
      return;
    }

    try {
      final now = DateTime.now();
      final targetDateTime = await _resolveWakeyTargetDateTime(settings, now);
      if (targetDateTime == null) {
        print(
          'AutoModeExecutor: Wakey target time відсутній, перевірку пропущено',
        );
        return;
      }

      final minutesBefore = settings.wakeMinutesBefore.clamp(0, 60);
      final windowStart = targetDateTime.subtract(
        Duration(minutes: minutesBefore),
      );
      final windowEnd = targetDateTime;

      print('═══════════════════════════════════════════════');
      print('AutoModeExecutor: WAKEY CHECK');
      print('═══════════════════════════════════════════════');
      print(
        '🕐 Зараз: '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      print(
        '🎯 Цільовий час: '
        '${targetDateTime.hour.toString().padLeft(2, '0')}:${targetDateTime.minute.toString().padLeft(2, '0')}',
      );
      print(
        '⏱️ Вікно запуску: '
        '${windowStart.hour.toString().padLeft(2, '0')}:${windowStart.minute.toString().padLeft(2, '0')} '
        '- '
        '${windowEnd.hour.toString().padLeft(2, '0')}:${windowEnd.minute.toString().padLeft(2, '0')}',
      );
      print(
        '⚙️ Режим Wakey: ${settings.wakeAtSunriseTime ? "at_dawn" : "custom"}, '
        'open=${settings.wakeyOpenPercent.round()}%, minutesBefore=$minutesBefore',
      );

      if (_isSameDay(_lastWakeyExecution, now)) {
        print('ℹ️ Wakey вже виконаний сьогодні, повтор не потрібен');
        print('═══════════════════════════════════════════════');
        return;
      }

      final nowTruncated = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      );
      final startTruncated = DateTime(
        windowStart.year,
        windowStart.month,
        windowStart.day,
        windowStart.hour,
        windowStart.minute,
      );
      final endTruncated = DateTime(
        windowEnd.year,
        windowEnd.month,
        windowEnd.day,
        windowEnd.hour,
        windowEnd.minute,
      );

      final isWithinWindow =
          (nowTruncated.isAtSameMomentAs(startTruncated) ||
              nowTruncated.isAfter(startTruncated)) &&
          (nowTruncated.isAtSameMomentAs(endTruncated) ||
              nowTruncated.isBefore(endTruncated));

      if (!isWithinWindow) {
        print('ℹ️ Поточний час поза вікном запуску, очікування...');
        print('═══════════════════════════════════════════════');
        return;
      }

      final position = settings.wakeyOpenPercent.round().clamp(0, 100);
      await _sendWakeyExecuteCommand(
        settings: settings,
        triggerTime: now,
        targetDateTime: targetDateTime,
        position: position,
      );
      _lastWakeyExecution = now;

      print(
        '✅ AutoModeExecutor: Wakey спрацював о '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '(вікно ${windowStart.hour.toString().padLeft(2, '0')}:${windowStart.minute.toString().padLeft(2, '0')} '
        '- ${windowEnd.hour.toString().padLeft(2, '0')}:${windowEnd.minute.toString().padLeft(2, '0')}) -> $position%',
      );
      print('═══════════════════════════════════════════════');
    } catch (e) {
      print('AutoModeExecutor: Помилка перевірки Wakey - $e');
      print('═══════════════════════════════════════════════');
    }
  }

  Future<void> _sendWakeyExecuteCommand({
    required AutoModeSettings settings,
    required DateTime triggerTime,
    required DateTime targetDateTime,
    required int position,
  }) async {
    final mqttRepo = ServiceLocator().smartWindowRepository;
    final targetTimeString =
        '${targetDateTime.hour.toString().padLeft(2, '0')}:${targetDateTime.minute.toString().padLeft(2, '0')}';
    final mode = settings.wakeAtSunriseTime ? 'at_dawn' : 'custom';
    final executePayload = '$targetTimeString,$position,$mode';

    await mqttRepo.publishMessage('smart_window/execute/wakey', executePayload);

    print('🚀 WAKEY EXECUTE TOPIC: smart_window/execute/wakey');
    print('📤 WAKEY EXECUTE PAYLOAD: $executePayload');
    print(
      '🕐 Trigger time: '
      '${triggerTime.hour.toString().padLeft(2, '0')}:${triggerTime.minute.toString().padLeft(2, '0')}',
    );
  }

  Future<DateTime?> _resolveWakeyTargetDateTime(
    AutoModeSettings settings,
    DateTime now,
  ) async {
    print('═══════════════════════════════════════════════');
    print('AutoModeExecutor: WAKEY SUNRISE LOOKUP');
    print('═══════════════════════════════════════════════');

    final userUseCase = ServiceLocator().userUseCase;
    final currentUser = await userUseCase.getCurrentUser();
    DateTime? sunrise;

    if (currentUser != null &&
        currentUser.latitude != null &&
        currentUser.longitude != null) {
      final cityLabel =
          (currentUser.city != null && currentUser.city!.trim().isNotEmpty)
              ? currentUser.city!
              : 'обране місто';

      print('📍 Місто для sunrise: $cityLabel');
      print(
        '📍 Координати для sunrise: '
        '${currentUser.latitude}, ${currentUser.longitude}',
      );
      print('🌐 Запит sunrise до OpenWeatherMap API...');

      sunrise = await _getSunriseFromApi(
        now,
        currentUser.latitude!,
        currentUser.longitude!,
        cityName: currentUser.city,
      );

      if (sunrise != null) {
        print(
          '🌅 AutoModeExecutor: API sunrise для $cityLabel: '
          '${sunrise.hour.toString().padLeft(2, '0')}:${sunrise.minute.toString().padLeft(2, '0')}',
        );
      } else {
        print(
          '❌ AutoModeExecutor: Не вдалося отримати світанок з API для логування',
        );
      }
    } else {
      print('ℹ️ Немає координат користувача для отримання sunrise');
    }

    if (settings.wakeAtSunriseTime) {
      if (sunrise == null) {
        print('⚠️ Режим At dawn: скасовано, бо відсутній час світанку');
        print('═══════════════════════════════════════════════');
        return null;
      }
      print('⚙️ Режим Wakey: At dawn. Використовуємо sunrise.');
      print('═══════════════════════════════════════════════');
      return DateTime(
        now.year,
        now.month,
        now.day,
        sunrise.hour,
        sunrise.minute,
      );
    }

    print(
      '⚙️ Режим Wakey: Custom. '
      'Час із налаштувань: '
      '${settings.wakeTime.hour.toString().padLeft(2, '0')}:${settings.wakeTime.minute.toString().padLeft(2, '0')}',
    );
    print('═══════════════════════════════════════════════');

    return DateTime(
      now.year,
      now.month,
      now.day,
      settings.wakeTime.hour,
      settings.wakeTime.minute,
    );
  }

  Future<DateTime?> _getSunriseFromApi(
    DateTime now,
    double latitude,
    double longitude, {
    String? cityName,
  }) async {
    if (_cachedSunriseDate != null &&
        _cachedSunriseDate!.year == now.year &&
        _cachedSunriseDate!.month == now.month &&
        _cachedSunriseDate!.day == now.day &&
        _cachedSunriseTime != null) {
      final cityLabel =
          (cityName != null && cityName.trim().isNotEmpty)
              ? cityName
              : 'обране місто';
      print(
        '♻️ AutoModeExecutor: sunrise з кешу для $cityLabel: '
        '${_cachedSunriseTime!.hour.toString().padLeft(2, '0')}:${_cachedSunriseTime!.minute.toString().padLeft(2, '0')}',
      );
      return _cachedSunriseTime;
    }

    final weatherService = ServiceLocator().weatherService;
    final sunrise = await weatherService.getSunriseTime(latitude, longitude);

    if (sunrise != null) {
      _cachedSunriseDate = DateTime(now.year, now.month, now.day);
      _cachedSunriseTime = sunrise;
      final cityLabel =
          (cityName != null && cityName.trim().isNotEmpty)
              ? cityName
              : 'обране місто';
      print(
        '✅ AutoModeExecutor: Отримано sunrise з API для $cityLabel: '
        '${sunrise.hour.toString().padLeft(2, '0')}:${sunrise.minute.toString().padLeft(2, '0')}',
      );
    } else {
      print('❌ AutoModeExecutor: API не повернув sunrise');
    }

    return sunrise;
  }

  bool _isSameDay(DateTime? first, DateTime second) {
    if (first == null) {
      return false;
    }
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  /// Відправити команду виконання Temperature/Weather на ESP8266
  Future<void> _sendTempWeatherExecuteCommand(AutoModeSettings settings) async {
    try {
      print('═══════════════════════════════════════════════');
      print('AutoModeExecutor: Перевірка Temperature/Weather');
      print('═══════════════════════════════════════════════');

      // Отримати поточного користувача з координатами
      final userUseCase = ServiceLocator().userUseCase;
      final currentUser = await userUseCase.getCurrentUser();

      if (currentUser == null ||
          currentUser.latitude == null ||
          currentUser.longitude == null) {
        print('❌ AutoModeExecutor: Немає координат користувача');
        return;
      }

      print('📍 Місто: ${currentUser.city ?? "Невідоме"}');
      print('📍 Координати: ${currentUser.latitude}, ${currentUser.longitude}');

      // Отримати поточні дані погоди з API
      final weatherService = ServiceLocator().weatherService;
      print('🌐 Запит до OpenWeatherMap API...');

      final weatherData = await weatherService.getCurrentWeather(
        currentUser.latitude!,
        currentUser.longitude!,
      );

      if (weatherData == null) {
        print('❌ AutoModeExecutor: Не вдалося отримати погоду з API');
        return;
      }

      print('✅ Дані з API отримано успішно:');
      print('   🌡️  Температура: ${weatherData.temperature}°C');
      print('   ☁️  Умови: ${weatherData.conditions.join(", ")}');
      print('   💧 Вологість: ${weatherData.humidity}%');
      print('   📝 Опис: ${weatherData.description}');

      final mqttRepo = ServiceLocator().smartWindowRepository;

      // Temperature execute
      if (settings.temperatureControlEnabled) {
        print('');
        print('🌡️  TEMPERATURE CONTROL:');
        print('   Поточна температура: ${weatherData.temperature}°C');
        print('   Встановлений поріг: ${settings.temperatureThreshold}°C');
        print(
          '   Відсоток закриття: ${settings.temperatureClosurePercent.round()}%',
        );

        if (weatherData.temperature >= settings.temperatureThreshold) {
          print(
            '   ✅ Умова виконана! (${weatherData.temperature} >= ${settings.temperatureThreshold})',
          );
          print('   🚀 Відправка команди на ESP8266...');
        } else {
          print(
            '   ❌ Умова НЕ виконана (${weatherData.temperature} < ${settings.temperatureThreshold})',
          );
        }

        final tempExecuteMessage =
            '${weatherData.temperature},${settings.temperatureThreshold},${settings.temperatureClosurePercent.round()}';
        await mqttRepo.publishMessage(
          'smart_window/execute/temperature',
          tempExecuteMessage,
        );
        print('   📤 Відправлено: $tempExecuteMessage');
      }

      // Weather execute
      if (settings.weatherControlEnabled &&
          settings.selectedWeathers.isNotEmpty) {
        print('');
        print('☁️  WEATHER CONTROL:');
        print('   Поточна умова: ${weatherData.conditions.join(", ")}');
        print('   Вибрані умови: ${settings.selectedWeathers.join(", ")}');
        print(
          '   Відсоток відкриття: ${settings.weatherClosurePercent.round()}%',
        );

        // Перевірити збіг
        final currentConditions =
            weatherData.conditions.map((c) => c.toLowerCase()).toSet();
        final selectedConditions =
            settings.selectedWeathers.map((c) => c.toLowerCase()).toSet();
        final hasMatch = currentConditions.any(selectedConditions.contains);

        if (hasMatch) {
          print('   ✅ Умова виконана! Погода співпадає');
          print('   🚀 Відправка команди на ESP8266...');
        } else {
          print('   ❌ Умова НЕ виконана - погода не співпадає');
        }

        final currentCondition =
            weatherData.conditions.isNotEmpty
                ? weatherData.conditions.first
                : 'Clear';
        final weatherExecuteMessage =
            '$currentCondition,${settings.selectedWeathers.join("|")},${settings.weatherClosurePercent.round()}';
        await mqttRepo.publishMessage(
          'smart_window/execute/weather',
          weatherExecuteMessage,
        );
        print('   📤 Відправлено: $weatherExecuteMessage');
      }

      print('═══════════════════════════════════════════════');
    } catch (e) {
      print('❌ AutoModeExecutor: Помилка - $e');
      print('═══════════════════════════════════════════════');
    }
  }

  /// Зупинити всі автоматичні режими
  void stop() {
    _wakeyTimer?.cancel();
    _checkTimer?.cancel();
    _wakeyTimer = null;
    _checkTimer = null;
    _lastWakeyExecution = null;
    _cachedSunriseDate = null;
    _cachedSunriseTime = null;
    _wakeySettings = null;
    _isRunning = false;
    print('AutoModeExecutor: Зупинено');
  }

  bool get isRunning => _isRunning;
}
