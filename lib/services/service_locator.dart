// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iot_flutter/data/repositories/mqtt/mock_mqtt_window_repository.dart';
import 'package:iot_flutter/data/repositories/mqtt/mqtt_window_repository.dart';
import 'package:iot_flutter/data/repositories/user_repository.dart';
import 'package:iot_flutter/data/repositories/user_repository_impl.dart';
import 'package:iot_flutter/domain/repositories/i_smart_window_repository.dart';
import 'package:iot_flutter/domain/usecases/user_usecase.dart';
import 'package:iot_flutter/domain/validators/user_validator.dart';
import 'package:iot_flutter/services/auto_mode_executor.dart';
import 'package:iot_flutter/services/connectivity_service.dart';
import 'package:iot_flutter/services/location_service.dart';
import 'package:iot_flutter/services/mock_api_storage_service.dart';
import 'package:iot_flutter/services/time_service.dart';
import 'package:iot_flutter/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late SharedPreferences _prefs;
  late UserRepository _userRepository;
  late UserValidator _userValidator;
  late UserUseCase _userUseCase;
  late ISmartWindowRepository _smartWindowRepository;
  late ConnectivityService _connectivityService;
  late MockApiStorageService _mockApiStorageService;
  late WeatherService _weatherService;
  late AutoModeExecutor _autoModeExecutor;
  late LocationService _locationService;
  late TimeService _timeService;

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  /// Ініціалізація всіх залежностей
  Future<void> initialize({String? mqttBrokerAddress}) async {
    _prefs = await SharedPreferences.getInstance();
    _userRepository = UserRepositoryImpl(_prefs);
    _userValidator = UserValidatorImpl();
    _userUseCase = UserUseCase(
      userRepository: _userRepository,
      userValidator: _userValidator,
    );

    // Ініціалізація MQTT репозиторію
    // Використовуємо збережену IP адресу або дефолтну
    final brokerIp =
        mqttBrokerAddress ??
        _prefs.getString('mqtt_broker_ip') ??
        '192.168.0.102';

    // На веб-платформі використовуємо mock реалізацію
    if (kIsWeb) {
      _smartWindowRepository = MockMqttWindowRepository(
        brokerAddress: brokerIp,
      );
      print('ServiceLocator: Використовується Mock MQTT для веб-платформи');
    } else {
      _smartWindowRepository = MqttWindowRepository(brokerAddress: brokerIp);
      print('ServiceLocator: Використовується реальний MQTT клієнт');
    }

    // Ініціалізація сервісу підключення
    _connectivityService = ConnectivityService();

    // Сервіс синхронізації з MockAPI + локальний кеш
    _mockApiStorageService = MockApiStorageService(
      prefs: _prefs,
      connectivityService: _connectivityService,
    );

    // Ініціалізація сервісів погоди, локації та часу
    _weatherService = WeatherService();
    _autoModeExecutor = AutoModeExecutor();
    _locationService = LocationService();
    _timeService = TimeService();
  }

  // Getters для отримання залежностей
  SharedPreferences get prefs => _prefs;
  UserRepository get userRepository => _userRepository;
  UserValidator get userValidator => _userValidator;
  UserUseCase get userUseCase => _userUseCase;
  ISmartWindowRepository get smartWindowRepository => _smartWindowRepository;
  ConnectivityService get connectivityService => _connectivityService;
  MockApiStorageService get mockApiStorageService => _mockApiStorageService;
  WeatherService get weatherService => _weatherService;
  AutoModeExecutor get autoModeExecutor => _autoModeExecutor;
  LocationService get locationService => _locationService;
  TimeService get timeService => _timeService;

  /// Зберегти IP адресу MQTT брокера
  Future<void> saveMqttBrokerAddress(String address) async {
    await _prefs.setString('mqtt_broker_ip', address);
  }

  /// Оновити MQTT репозиторій з новою адресою
  void updateMqttRepository(String brokerAddress) {
    if (kIsWeb) {
      _smartWindowRepository = MockMqttWindowRepository(
        brokerAddress: brokerAddress,
      );
    } else {
      _smartWindowRepository = MqttWindowRepository(
        brokerAddress: brokerAddress,
      );
    }
  }
}
