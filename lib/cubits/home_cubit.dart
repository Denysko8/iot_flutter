// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/domain/repositories/i_smart_window_repository.dart';
import 'package:iot_flutter/domain/usecases/user_usecase.dart';
import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/models/cloud_sync_state.dart';
import 'package:iot_flutter/services/auto_mode_executor.dart';
import 'package:iot_flutter/services/connectivity_service.dart';
import 'package:iot_flutter/services/mock_api_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeState {
  final double sliderValue;
  final bool isAutoMode;
  final AutoModeSettings autoSettings;
  final bool isConnectedToInternet;
  final bool isConnectedToMqtt;
  final CloudSyncState? cloudState;
  final bool isCloudLoading;
  final String? infoMessage;
  final String? errorMessage;

  HomeState({
    this.sliderValue = 50,
    this.isAutoMode = false,
    AutoModeSettings? autoSettings,
    this.isConnectedToInternet = true,
    this.isConnectedToMqtt = false,
    this.cloudState,
    this.isCloudLoading = false,
    this.infoMessage,
    this.errorMessage,
  }) : autoSettings = autoSettings ?? AutoModeSettings();

  HomeState copyWith({
    double? sliderValue,
    bool? isAutoMode,
    AutoModeSettings? autoSettings,
    bool? isConnectedToInternet,
    bool? isConnectedToMqtt,
    CloudSyncState? cloudState,
    bool? isCloudLoading,
    String? infoMessage,
    String? errorMessage,
    bool clearInfo = false,
    bool clearError = false,
  }) {
    return HomeState(
      sliderValue: sliderValue ?? this.sliderValue,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      autoSettings: autoSettings ?? this.autoSettings,
      isConnectedToInternet:
          isConnectedToInternet ?? this.isConnectedToInternet,
      isConnectedToMqtt: isConnectedToMqtt ?? this.isConnectedToMqtt,
      cloudState: cloudState ?? this.cloudState,
      isCloudLoading: isCloudLoading ?? this.isCloudLoading,
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  final SharedPreferences _prefs;
  final ISmartWindowRepository _mqttRepo;
  final ConnectivityService _connectivityService;
  final AutoModeExecutor _autoModeExecutor;
  final UserUseCase _userUseCase;
  final MockApiStorageService _mockApiStorageService;

  HomeCubit({
    required SharedPreferences prefs,
    required ISmartWindowRepository mqttRepo,
    required ConnectivityService connectivityService,
    required AutoModeExecutor autoModeExecutor,
    required UserUseCase userUseCase,
    required MockApiStorageService mockApiStorageService,
  }) : _prefs = prefs,
       _mqttRepo = mqttRepo,
       _connectivityService = connectivityService,
       _autoModeExecutor = autoModeExecutor,
       _userUseCase = userUseCase,
       _mockApiStorageService = mockApiStorageService,
       super(HomeState());

  Future<void> init() async {
    _loadLastKnownPosition();
    await _connectToMqtt();

    final hasConnection = await _connectivityService.checkConnection();
    emit(state.copyWith(isConnectedToInternet: hasConnection));

    _connectivityService.startMonitoring((isConnected) {
      emit(state.copyWith(isConnectedToInternet: isConnected));
      if (isConnected) {
        _connectToMqtt();
      }
    });

    _restoreAutoModeExecutor();
    await loadCloudState();
  }

  Future<void> loadCloudState() async {
    emit(state.copyWith(isCloudLoading: true, clearError: true));
    final user = await _userUseCase.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(isCloudLoading: false));
      return;
    }

    final cloudState = await _mockApiStorageService.fetchLatestState(
      user.email,
    );
    emit(state.copyWith(isCloudLoading: false, cloudState: cloudState));
  }

  Future<void> _connectToMqtt() async {
    try {
      final connected = await _mqttRepo.connect();
      emit(state.copyWith(isConnectedToMqtt: connected));

      if (connected) {
        _mqttRepo.subscribeToFeedback(_handleEspFeedback);
        await _mqttRepo.publishMessage('smart_window/request/state', 'sync');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isConnectedToMqtt: false,
          errorMessage: 'Помилка підключення до MQTT: $e',
        ),
      );
    }
  }

  void _loadLastKnownPosition() {
    final lastPosition = _prefs.getInt('last_window_position');
    if (lastPosition == null) return;

    final valid = lastPosition.clamp(0, 100).toDouble();
    emit(state.copyWith(sliderValue: valid));
  }

  Future<void> _saveLastKnownPosition(int position) async {
    final validPosition = position.clamp(0, 100);
    await _prefs.setInt('last_window_position', validPosition);
  }

  Future<void> _saveAutoSettingsToPrefs(AutoModeSettings settings) async {
    await _prefs.setBool(
      'auto_wake_before_sunrise',
      settings.wakeBeforeSunrise,
    );
    await _prefs.setBool(
      'auto_wake_at_sunrise_time',
      settings.wakeAtSunriseTime,
    );
    await _prefs.setInt('auto_wake_time_hour', settings.wakeTime.hour);
    await _prefs.setInt('auto_wake_time_minute', settings.wakeTime.minute);
    await _prefs.setInt('auto_wake_minutes_before', settings.wakeMinutesBefore);
    await _prefs.setDouble(
      'auto_wakey_open_percent',
      settings.wakeyOpenPercent,
    );
    await _prefs.setBool(
      'auto_temp_enabled',
      settings.temperatureControlEnabled,
    );
    await _prefs.setDouble(
      'auto_temp_threshold',
      settings.temperatureThreshold,
    );
    await _prefs.setDouble(
      'auto_temp_closure_percent',
      settings.temperatureClosurePercent,
    );
    await _prefs.setBool(
      'auto_weather_enabled',
      settings.weatherControlEnabled,
    );
    await _prefs.setString(
      'auto_selected_weathers',
      settings.selectedWeathers.join(','),
    );
    await _prefs.setDouble(
      'auto_weather_closure_percent',
      settings.weatherClosurePercent,
    );
    await _prefs.setBool('auto_settings_saved', true);
  }

  AutoModeSettings? _loadAutoSettingsFromPrefs() {
    if (_prefs.getBool('auto_settings_saved') != true) return null;

    final hour = _prefs.getInt('auto_wake_time_hour') ?? 7;
    final minute = _prefs.getInt('auto_wake_time_minute') ?? 0;
    final weathersStr = _prefs.getString('auto_selected_weathers') ?? '';

    return AutoModeSettings(
      wakeBeforeSunrise: _prefs.getBool('auto_wake_before_sunrise') ?? false,
      wakeAtSunriseTime: _prefs.getBool('auto_wake_at_sunrise_time') ?? true,
      wakeTime: TimeOfDay(hour: hour, minute: minute),
      wakeMinutesBefore: _prefs.getInt('auto_wake_minutes_before') ?? 0,
      wakeyOpenPercent: _prefs.getDouble('auto_wakey_open_percent') ?? 100.0,
      temperatureControlEnabled: _prefs.getBool('auto_temp_enabled') ?? false,
      temperatureThreshold: _prefs.getDouble('auto_temp_threshold') ?? 22.0,
      temperatureClosurePercent:
          _prefs.getDouble('auto_temp_closure_percent') ?? 50.0,
      weatherControlEnabled: _prefs.getBool('auto_weather_enabled') ?? false,
      selectedWeathers:
          weathersStr.isEmpty ? <String>{} : weathersStr.split(',').toSet(),
      weatherClosurePercent:
          _prefs.getDouble('auto_weather_closure_percent') ?? 50.0,
    );
  }

  void _restoreAutoModeExecutor() {
    final savedSettings = _loadAutoSettingsFromPrefs();
    if (savedSettings == null) return;

    emit(state.copyWith(autoSettings: savedSettings));

    if (savedSettings.wakeySensors) {
      _autoModeExecutor.syncWakeyBackground(savedSettings);
    }
  }

  void manualPositionChanging(double value) {
    emit(state.copyWith(sliderValue: value));
  }

  Future<void> manualPositionChangeEnd(double value) async {
    if (!state.isConnectedToMqtt) {
      emit(state.copyWith(errorMessage: 'Немає підключення до MQTT брокера'));
      return;
    }

    try {
      await _mqttRepo.sendManualPosition(value.round());
      await _saveLastKnownPosition(value.round());
      emit(state.copyWith(sliderValue: value));
      await _syncCurrentState();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Помилка надсилання команди: $e'));
    }
  }

  void autoModeChanged(AutoModeSettings settings) {
    emit(state.copyWith(autoSettings: settings));
  }

  Future<void> toggleMode() async {
    emit(state.copyWith(isAutoMode: !state.isAutoMode));
    await _syncCurrentState();
  }

  Future<void> saveAutoSettings() async {
    if (!state.isConnectedToMqtt) {
      emit(state.copyWith(errorMessage: 'Немає підключення до MQTT брокера'));
      return;
    }

    try {
      final savedSettings = _cloneAutoSettings(state.autoSettings);
      await _sendAutoSettingsToEsp(savedSettings);
      await _mqttRepo.sendSaveAutoSettings();
      await _saveAutoSettingsToPrefs(savedSettings);
      await _autoModeExecutor.executeAutoModes(savedSettings);
      emit(state.copyWith(autoSettings: savedSettings));
      await _syncCurrentState(settings: savedSettings);
      emit(state.copyWith(infoMessage: 'Налаштування збережено'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Помилка збереження налаштувань: $e'));
    }
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
    await _mqttRepo.sendWakeyState(settings.wakeySensors);

    if (settings.wakeySensors) {
      await _mqttRepo.sendWakeyMode(settings.wakeAtSunriseTime);
      await _mqttRepo.sendWakeyOpenPercent(settings.wakeyOpenPercent.round());

      if (!settings.wakeAtSunriseTime && settings.wakeBeforeSunrise) {
        final timeString =
            '${settings.wakeTime.hour.toString().padLeft(2, '0')}:'
            '${settings.wakeTime.minute.toString().padLeft(2, '0')}';
        await _mqttRepo.sendWakeyTime(timeString);
        await _mqttRepo.sendWakeyMinutesBefore(settings.wakeMinutesBefore);
      } else if (settings.wakeAtSunriseTime) {
        await _mqttRepo.sendWakeyTime('null');
        await _mqttRepo.sendWakeyMinutesBefore(settings.wakeMinutesBefore);
      }
    }

    await _mqttRepo.sendTempControlState(settings.temperatureControlEnabled);
    if (settings.temperatureControlEnabled) {
      await _mqttRepo.sendTempThreshold(settings.temperatureThreshold);
      await _mqttRepo.sendTempClosurePercent(
        settings.temperatureClosurePercent.round(),
      );
    }

    await _mqttRepo.sendWeatherControlState(settings.weatherControlEnabled);
    if (settings.weatherControlEnabled) {
      await _mqttRepo.sendSelectedWeatherConditions(settings.selectedWeathers);
      await _mqttRepo.sendWeatherOpenPercent(
        settings.weatherClosurePercent.round(),
      );
    }
  }

  Map<String, String> _buildMqttTopicsSnapshot(AutoModeSettings settings) {
    final selectedWeathers = settings.selectedWeathers.join(',');
    final wakeTime =
        '${settings.wakeTime.hour.toString().padLeft(2, '0')}:'
        '${settings.wakeTime.minute.toString().padLeft(2, '0')}';

    return <String, String>{
      'smart_window/manual/position': state.sliderValue.round().toString(),
      'smart_window/auto/wakey/state': settings.wakeySensors ? 'on' : 'off',
      'smart_window/auto/wakey/mode':
          settings.wakeAtSunriseTime ? 'at_dawn' : 'custom',
      'smart_window/auto/wakey/time':
          settings.wakeAtSunriseTime ? 'null' : wakeTime,
      'smart_window/auto/wakey/minutes_before':
          settings.wakeMinutesBefore.toString(),
      'smart_window/auto/wakey/open_percent':
          settings.wakeyOpenPercent.round().toString(),
      'smart_window/auto/temp/state':
          settings.temperatureControlEnabled ? 'on' : 'off',
      'smart_window/auto/temp/threshold':
          settings.temperatureThreshold.toString(),
      'smart_window/auto/temp/closure':
          settings.temperatureClosurePercent.round().toString(),
      'smart_window/auto/weather/state':
          settings.weatherControlEnabled ? 'on' : 'off',
      'smart_window/auto/weather/conditions': selectedWeathers,
      'smart_window/auto/weather/open_percent':
          settings.weatherClosurePercent.round().toString(),
      'smart_window/auto/save': 'save',
    };
  }

  Future<void> _syncCurrentState({AutoModeSettings? settings}) async {
    final user = await _userUseCase.getCurrentUser();
    if (user == null) return;

    final activeSettings = settings ?? state.autoSettings;
    final snapshot = CloudSyncState(
      user: user,
      isAutoMode: state.isAutoMode,
      manualPosition: state.sliderValue.round().clamp(0, 100),
      autoSettings: activeSettings,
      mqttBrokerIp: _prefs.getString('mqtt_broker_ip') ?? '192.168.0.102',
      mqttTopics: _buildMqttTopicsSnapshot(activeSettings),
      updatedAt: DateTime.now(),
    );

    await _mockApiStorageService.syncState(snapshot);
    await loadCloudState();
  }

  void _handleEspFeedback(String topic, String message) {
    final updatedSettings = _cloneAutoSettings(state.autoSettings);
    var slider = state.sliderValue;

    if (topic == 'smart_window/feedback/position') {
      final position = (int.tryParse(message) ?? 0).clamp(0, 100);
      slider = position.toDouble();
      _saveLastKnownPosition(position);
    } else if (topic == 'smart_window/feedback/saved') {
      emit(state.copyWith(infoMessage: 'Налаштування збережено'));
      return;
    } else if (topic == 'smart_window/feedback/wakey/enabled') {
      updatedSettings.wakeBeforeSunrise = (message == 'on');
    } else if (topic == 'smart_window/feedback/wakey/mode') {
      updatedSettings.wakeAtSunriseTime = (message == 'at_dawn');
    } else if (topic == 'smart_window/feedback/wakey/time') {
      if (message.isNotEmpty && message.contains(':')) {
        final parts = message.split(':');
        if (parts.length == 2) {
          updatedSettings.wakeTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    } else if (topic == 'smart_window/feedback/wakey/minutes') {
      updatedSettings.wakeMinutesBefore = (int.tryParse(message) ?? 0).clamp(
        0,
        60,
      );
    } else if (topic == 'smart_window/feedback/wakey/open') {
      updatedSettings.wakeyOpenPercent = (double.tryParse(message) ?? 100.0)
          .clamp(0.0, 100.0);
    } else if (topic == 'smart_window/feedback/temp/enabled') {
      updatedSettings.temperatureControlEnabled = (message == 'on');
    } else if (topic == 'smart_window/feedback/temp/threshold') {
      updatedSettings.temperatureThreshold = (double.tryParse(message) ?? 25.0)
          .clamp(15.0, 40.0);
    } else if (topic == 'smart_window/feedback/temp/closure') {
      updatedSettings.temperatureClosurePercent =
          (double.tryParse(message) ?? 0.0).clamp(0.0, 100.0);
    } else if (topic == 'smart_window/feedback/weather/enabled') {
      updatedSettings.weatherControlEnabled = (message == 'on');
    } else if (topic == 'smart_window/feedback/weather/conditions') {
      updatedSettings.selectedWeathers =
          message.isNotEmpty ? message.split(',').toSet() : <String>{};
    } else if (topic == 'smart_window/feedback/weather/open') {
      updatedSettings.weatherClosurePercent = (double.tryParse(message) ?? 0.0)
          .clamp(0.0, 100.0);
    }

    emit(state.copyWith(sliderValue: slider, autoSettings: updatedSettings));
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearInfo: true));
  }

  @override
  Future<void> close() async {
    _connectivityService.stopMonitoring();
    _autoModeExecutor.stop();
    _mqttRepo.unsubscribeFromFeedback();
    await _mqttRepo.disconnect();
    return super.close();
  }
}
