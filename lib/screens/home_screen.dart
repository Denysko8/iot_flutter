// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/screens/profile_screen.dart';
import 'package:iot_flutter/services/service_locator.dart';
import 'package:iot_flutter/widgets/auto_mode_controls.dart';
import 'package:iot_flutter/widgets/manual_mode_controls.dart';
import 'package:iot_flutter/widgets/mode_toggle_button.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _sliderValue = 50;
  bool _isAutoMode = false;
  AutoModeSettings _autoSettings = AutoModeSettings();
  bool _isConnectedToInternet = true;
  bool _isConnectedToMqtt = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // На веб-платформі показуємо попередження
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWebPlatformWarning();
      });
    }
    _loadLastKnownPosition();
    _initializeConnections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreAutoModeExecutor();
    });
  }

  @override
  void dispose() {
    // Зупинити моніторинг підключення та від'єднатися від MQTT
    final connectivityService = ServiceLocator().connectivityService;
    connectivityService.stopMonitoring();

    // Зупинити автоматичні режими
    final autoModeExecutor = ServiceLocator().autoModeExecutor;
    autoModeExecutor.stop();

    final mqttRepo = ServiceLocator().smartWindowRepository;
    mqttRepo.unsubscribeFromFeedback();
    mqttRepo.disconnect();

    super.dispose();
  }

  Future<void> _initializeConnections() async {
    // Перевірка та підключення до MQTT
    await _connectToMqtt();

    // Початкова перевірка підключення до Інтернету
    final connectivityService = ServiceLocator().connectivityService;
    final hasConnection = await connectivityService.checkConnection();
    setState(() {
      _isConnectedToInternet = hasConnection;
    });

    // Почати моніторинг підключення
    connectivityService.startMonitoring((isConnected) {
      setState(() {
        _isConnectedToInternet = isConnected;
      });

      if (!isConnected) {
        _showConnectivityWarning('Втрачено з\'єднання з Інтернетом');
      } else {
        _showConnectivityInfo('З\'єднання з Інтернетом відновлено');
        // Спробувати перепідключитися до MQTT
        _connectToMqtt();
      }
    });
  }

  Future<void> _connectToMqtt() async {
    final mqttRepo = ServiceLocator().smartWindowRepository;

    try {
      final connected = await mqttRepo.connect();
      setState(() {
        _isConnectedToMqtt = connected;
      });

      if (connected) {
        // Підписатися на зворотний зв'язок від ESP8266
        mqttRepo.subscribeToFeedback((topic, message) {
          print('ESP8266 feedback - $topic: $message');
          _handleEspFeedback(topic, message);
        });

        // Запросити у ESP8266 останній збережений стан після входу/перезапуску додатку
        await mqttRepo.publishMessage('smart_window/request/state', 'sync');
        print('HomeScreen: Запрошено синхронізацію стану з ESP8266');
      }
    } catch (e) {
      print('Помилка підключення до MQTT: $e');
      setState(() {
        _isConnectedToMqtt = false;
      });
    }
  }

  void _loadLastKnownPosition() {
    final lastPosition = ServiceLocator().prefs.getInt('last_window_position');
    if (lastPosition == null) {
      return;
    }

    final validPosition = lastPosition.clamp(0, 100);
    setState(() {
      _sliderValue = validPosition.toDouble();
    });
  }

  Future<void> _saveLastKnownPosition(int position) async {
    final validPosition = position.clamp(0, 100);
    await ServiceLocator().prefs.setInt('last_window_position', validPosition);
  }

  Future<void> _saveAutoSettingsToPrefs(AutoModeSettings settings) async {
    final prefs = ServiceLocator().prefs;
    await prefs.setBool('auto_wake_before_sunrise', settings.wakeBeforeSunrise);
    await prefs.setBool(
      'auto_wake_at_sunrise_time',
      settings.wakeAtSunriseTime,
    );
    await prefs.setInt('auto_wake_time_hour', settings.wakeTime.hour);
    await prefs.setInt('auto_wake_time_minute', settings.wakeTime.minute);
    await prefs.setInt('auto_wake_minutes_before', settings.wakeMinutesBefore);
    await prefs.setDouble('auto_wakey_open_percent', settings.wakeyOpenPercent);
    await prefs.setBool(
      'auto_temp_enabled',
      settings.temperatureControlEnabled,
    );
    await prefs.setDouble('auto_temp_threshold', settings.temperatureThreshold);
    await prefs.setDouble(
      'auto_temp_closure_percent',
      settings.temperatureClosurePercent,
    );
    await prefs.setBool('auto_weather_enabled', settings.weatherControlEnabled);
    await prefs.setString(
      'auto_selected_weathers',
      settings.selectedWeathers.join(','),
    );
    await prefs.setDouble(
      'auto_weather_closure_percent',
      settings.weatherClosurePercent,
    );
    await prefs.setBool('auto_settings_saved', true);
  }

  AutoModeSettings? _loadAutoSettingsFromPrefs() {
    final prefs = ServiceLocator().prefs;
    if (prefs.getBool('auto_settings_saved') != true) return null;

    final hour = prefs.getInt('auto_wake_time_hour') ?? 7;
    final minute = prefs.getInt('auto_wake_time_minute') ?? 0;
    final weathersStr = prefs.getString('auto_selected_weathers') ?? '';

    return AutoModeSettings(
      wakeBeforeSunrise: prefs.getBool('auto_wake_before_sunrise') ?? false,
      wakeAtSunriseTime: prefs.getBool('auto_wake_at_sunrise_time') ?? true,
      wakeTime: TimeOfDay(hour: hour, minute: minute),
      wakeMinutesBefore: prefs.getInt('auto_wake_minutes_before') ?? 0,
      wakeyOpenPercent: prefs.getDouble('auto_wakey_open_percent') ?? 100.0,
      temperatureControlEnabled: prefs.getBool('auto_temp_enabled') ?? false,
      temperatureThreshold: prefs.getDouble('auto_temp_threshold') ?? 22.0,
      temperatureClosurePercent:
          prefs.getDouble('auto_temp_closure_percent') ?? 50.0,
      weatherControlEnabled: prefs.getBool('auto_weather_enabled') ?? false,
      selectedWeathers:
          weathersStr.isEmpty ? <String>{} : weathersStr.split(',').toSet(),
      weatherClosurePercent:
          prefs.getDouble('auto_weather_closure_percent') ?? 50.0,
    );
  }

  void _restoreAutoModeExecutor() {
    final savedSettings = _loadAutoSettingsFromPrefs();
    if (savedSettings == null) return;

    setState(() {
      _autoSettings = savedSettings;
    });

    if (savedSettings.wakeySensors) {
      final autoModeExecutor = ServiceLocator().autoModeExecutor;
      autoModeExecutor.syncWakeyBackground(savedSettings);
      print('HomeScreen: Wakey фоновий таймер відновлено після перезапуску');
    }
  }

  void _handleEspFeedback(String topic, String message) {
    // Обробка зворотного зв'язку від ESP8266
    if (topic == 'smart_window/feedback/position') {
      final position = int.tryParse(message) ?? 0;
      // Валідація: 0-100%
      final validPosition = position.clamp(0, 100);
      setState(() {
        _sliderValue = validPosition.toDouble();
      });
      _saveLastKnownPosition(validPosition);
      print('Отримано збережену позицію з ESP8266: $validPosition%');
    } else if (topic == 'smart_window/feedback/saved') {
      // Підтвердження збереження
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Налаштування збережено'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (topic.startsWith('smart_window/feedback/wakey/')) {
      _handleWakeyFeedback(topic, message);
    } else if (topic.startsWith('smart_window/feedback/temp/')) {
      _handleTempFeedback(topic, message);
    } else if (topic.startsWith('smart_window/feedback/weather/')) {
      _handleWeatherFeedback(topic, message);
    }
  }

  void _handleWakeyFeedback(String topic, String message) {
    setState(() {
      if (topic == 'smart_window/feedback/wakey/enabled') {
        _autoSettings.wakeBeforeSunrise = (message == 'on');
      } else if (topic == 'smart_window/feedback/wakey/mode') {
        _autoSettings.wakeAtSunriseTime = (message == 'at_dawn');
      } else if (topic == 'smart_window/feedback/wakey/time') {
        if (message.isNotEmpty && message.contains(':')) {
          final parts = message.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            _autoSettings.wakeTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      } else if (topic == 'smart_window/feedback/wakey/minutes') {
        final minutes = int.tryParse(message) ?? 0;
        // Валідація: 0-60 хвилин
        _autoSettings.wakeMinutesBefore = minutes.clamp(0, 60);
      } else if (topic == 'smart_window/feedback/wakey/open') {
        final openPercent = double.tryParse(message) ?? 100.0;
        // Валідація: 0-100%
        _autoSettings.wakeyOpenPercent = openPercent.clamp(0.0, 100.0);
      }
    });
  }

  void _handleTempFeedback(String topic, String message) {
    setState(() {
      if (topic == 'smart_window/feedback/temp/enabled') {
        _autoSettings.temperatureControlEnabled = (message == 'on');
      } else if (topic == 'smart_window/feedback/temp/threshold') {
        final threshold = double.tryParse(message) ?? 25.0;
        // Валідація: 15-40 градусів
        _autoSettings.temperatureThreshold = threshold.clamp(15.0, 40.0);
      } else if (topic == 'smart_window/feedback/temp/closure') {
        final closure = double.tryParse(message) ?? 0.0;
        // Валідація: 0-100%
        _autoSettings.temperatureClosurePercent = closure.clamp(0.0, 100.0);
      }
    });
  }

  void _handleWeatherFeedback(String topic, String message) {
    setState(() {
      if (topic == 'smart_window/feedback/weather/enabled') {
        _autoSettings.weatherControlEnabled = (message == 'on');
      } else if (topic == 'smart_window/feedback/weather/conditions') {
        if (message.isNotEmpty) {
          _autoSettings.selectedWeathers = message.split(',').toSet();
        }
      } else if (topic == 'smart_window/feedback/weather/open') {
        final open = double.tryParse(message) ?? 0.0;
        // Валідація: 0-100%
        _autoSettings.weatherClosurePercent = open.clamp(0.0, 100.0);
      }
    });
  }

  void _showConnectivityWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showConnectivityInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWebPlatformWarning() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Веб-версія'),
              ],
            ),
            content: const Text(
              'MQTT функціонал не підтримується у веб-версії додатка.\n\n'
              'Для повного функціоналу використовуйте мобільну версію (Android/iOS).\n\n'
              'У веб-версії доступні тільки базові функції UI.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Зрозуміло'),
              ),
            ],
          ),
    );
  }

  void _showMqttFeedback(String topic, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ESP8266: $message'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleManualPositionChanging(double value) {
    // Тільки оновлюємо UI без надсилання команди
    setState(() {
      _sliderValue = value;
    });
  }

  Future<void> _handleManualPositionChangeEnd(double value) async {
    // Надсилаємо команду тільки після відпускання повзунка
    if (_isConnectedToMqtt) {
      try {
        final mqttRepo = ServiceLocator().smartWindowRepository;
        await mqttRepo.sendManualPosition(value.round());
        await _saveLastKnownPosition(value.round());
        print('HomeScreen: Manual position sent: ${value.round()}%');
      } catch (e) {
        _showError('Помилка надсилання команди: $e');
      }
    } else {
      _showError('Немає підключення до MQTT брокера');
    }
  }

  Future<void> _handleAutoModeChange(AutoModeSettings settings) async {
    // Лише локальне оновлення UI. Відправка налаштувань і запуск таймера - тільки через Save Settings.
    setState(() {
      _autoSettings = settings;
    });
  }

  AutoModeSettings _cloneAutoSettings(AutoModeSettings settings) {
    return AutoModeSettings(
      wakeBeforeSunrise: settings.wakeBeforeSunrise,
      wakeAtSunriseTime: settings.wakeAtSunriseTime,
      wakeTime: settings.wakeTime,
      wakeMinutesBefore: settings.wakeMinutesBefore,
      wakeyOpenPercent: settings.wakeyOpenPercent,
      temperatureControlEnabled: settings.temperatureControlEnabled,
      temperatureThreshold: settings.temperatureThreshold,
      temperatureClosurePercent: settings.temperatureClosurePercent,
      weatherControlEnabled: settings.weatherControlEnabled,
      selectedWeathers: Set<String>.from(settings.selectedWeathers),
      weatherClosurePercent: settings.weatherClosurePercent,
    );
  }

  Future<void> _sendAutoSettingsToEsp(AutoModeSettings settings) async {
    final mqttRepo = ServiceLocator().smartWindowRepository;

    // 1. Wakey sensors
    await mqttRepo.sendWakeyState(settings.wakeySensors);
    print(
      'HomeScreen: Відправлено wakey стан: ${settings.wakeySensors ? "on" : "off"}',
    );

    if (settings.wakeySensors) {
      await mqttRepo.sendWakeyMode(settings.wakeAtSunriseTime);
      print(
        'HomeScreen: Відправлено wakey режим: ${settings.wakeAtSunriseTime ? "at_dawn" : "custom"}',
      );

      final wakeyOpenPercent = settings.wakeyOpenPercent.round();
      await mqttRepo.sendWakeyOpenPercent(wakeyOpenPercent);
      print(
        'HomeScreen: Відправлено wakey відсоток відкриття: $wakeyOpenPercent',
      );

      if (!settings.wakeAtSunriseTime && settings.wakeBeforeSunrise) {
        final timeString =
            '${settings.wakeTime.hour.toString().padLeft(2, '0')}:${settings.wakeTime.minute.toString().padLeft(2, '0')}';
        await mqttRepo.sendWakeyTime(timeString);
        await mqttRepo.sendWakeyMinutesBefore(settings.wakeMinutesBefore);
        print('HomeScreen: Відправлено час будильника: $timeString');
        print(
          'HomeScreen: Відправлено хвилини перед пробудженням: ${settings.wakeMinutesBefore}',
        );
      } else if (settings.wakeAtSunriseTime) {
        await mqttRepo.sendWakeyTime('null');
        await mqttRepo.sendWakeyMinutesBefore(settings.wakeMinutesBefore);
        print(
          'HomeScreen: At dawn режим, час = null, хвилини = ${settings.wakeMinutesBefore}',
        );
      }
    }

    // 2. Temperature control
    await mqttRepo.sendTempControlState(settings.temperatureControlEnabled);
    print(
      'HomeScreen: Відправлено temperature control стан: ${settings.temperatureControlEnabled ? "on" : "off"}',
    );

    if (settings.temperatureControlEnabled) {
      await mqttRepo.sendTempThreshold(settings.temperatureThreshold);
      final closurePercent = settings.temperatureClosurePercent.round();
      await mqttRepo.sendTempClosurePercent(closurePercent);
      print(
        'HomeScreen: Відправлено температурний поріг: ${settings.temperatureThreshold}',
      );
      print('HomeScreen: Відправлено відсоток закриття: $closurePercent');
    }

    // 3. Weather control
    await mqttRepo.sendWeatherControlState(settings.weatherControlEnabled);
    print(
      'HomeScreen: Відправлено weather control стан: ${settings.weatherControlEnabled ? "on" : "off"}',
    );

    if (settings.weatherControlEnabled) {
      await mqttRepo.sendSelectedWeatherConditions(settings.selectedWeathers);
      final openPercent = settings.weatherClosurePercent.round();
      await mqttRepo.sendWeatherOpenPercent(openPercent);
      print(
        'HomeScreen: Відправлено вибрані погодні умови: ${settings.selectedWeathers.join(", ")}',
      );
      print('HomeScreen: Відправлено відсоток відкриття: $openPercent');
    }
  }

  bool _compareSets<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2);
  }

  Future<void> _handleSaveAutoSettings() async {
    if (!_isConnectedToMqtt) {
      if (!kIsWeb) {
        _showError('Немає підключення до MQTT брокера');
      }
      return;
    }

    try {
      final savedSettings = _cloneAutoSettings(_autoSettings);
      final mqttRepo = ServiceLocator().smartWindowRepository;

      // Спочатку відправити всі актуальні налаштування на ESP.
      await _sendAutoSettingsToEsp(savedSettings);

      // Потім команда збереження в EEPROM на ESP.
      await mqttRepo.sendSaveAutoSettings();
      print('HomeScreen: Відправлено команду збереження налаштувань');

      // Зберегти налаштування локально для відновлення після перезапуску.
      await _saveAutoSettingsToPrefs(savedSettings);
      print('HomeScreen: Налаштування збережено в SharedPreferences');

      // Запустити локальний фоновий таймер з тими самими збереженими налаштуваннями.
      final autoModeExecutor = ServiceLocator().autoModeExecutor;
      await autoModeExecutor.executeAutoModes(savedSettings);
      print('HomeScreen: Автоматичні режими запущено');
    } catch (e) {
      _showError('Помилка збереження налаштувань: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isAutoMode = !_isAutoMode;
    });
    print('HomeScreen: Режим змінено на ${_isAutoMode ? "Auto" : "Manual"}');
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Blinds Control'),
        actions: [
          // Індикатор підключення до Інтернету
          Icon(
            _isConnectedToInternet ? Icons.wifi : Icons.wifi_off,
            color: _isConnectedToInternet ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          // Індикатор підключення до MQTT
          Icon(
            _isConnectedToMqtt ? Icons.cloud_done : Icons.cloud_off,
            color: _isConnectedToMqtt ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.window,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                // Статус підключення
                if (!_isConnectedToInternet || !_isConnectedToMqtt)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            !_isConnectedToInternet
                                ? 'Немає з\'єднання з Інтернетом'
                                : 'Немає з\'єднання з MQTT брокером',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ModeToggleButton(
                  isAutoMode: _isAutoMode,
                  onToggle: _toggleMode,
                ),
                const SizedBox(height: 24),
                if (!_isAutoMode)
                  ManualModeControls(
                    sliderValue: _sliderValue,
                    onSliderChanged: _handleManualPositionChanging,
                    onSliderChangeEnd: _handleManualPositionChangeEnd,
                  )
                else
                  AutoModeControls(
                    settings: _autoSettings,
                    onChanged: _handleAutoModeChange,
                    onSave: _handleSaveAutoSettings,
                    parentActive: _isAutoMode,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
