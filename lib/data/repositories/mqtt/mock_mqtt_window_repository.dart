import 'package:iot_flutter/domain/repositories/i_smart_window_repository.dart';

/// Mock реалізація MQTT репозиторію для веб-платформи
/// MQTT не підтримується на вебі, тому це заглушка
class MockMqttWindowRepository implements ISmartWindowRepository {
  final String brokerAddress;
  final int brokerPort;
  bool _isConnected = false;

  MockMqttWindowRepository({
    required this.brokerAddress,
    this.brokerPort = 1883,
  });

  @override
  Future<bool> connect() async {
    print('MQTT Mock: Веб-платформа не підтримує MQTT підключення');
    _isConnected = false;
    return false;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    print('MQTT Mock: Від\'єднано (mock)');
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> sendManualPosition(int position) async {
    print('MQTT Mock: Надіслано позицію $position (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWakeyState(bool enabled) async {
    print('MQTT Mock: Надіслано wakey стан ${enabled ? "on" : "off"} (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWakeyMode(bool atDawn) async {
    print('MQTT Mock: Надіслано wakey режим ${atDawn ? "at_dawn" : "custom"} (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWakeyTime(String time) async {
    print('MQTT Mock: Надіслано час будильника $time (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWakeyMinutesBefore(int minutes) async {
    print('MQTT Mock: Надіслано хвилини перед пробудженням $minutes (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWakeyOpenPercent(int percent) async {
    print('MQTT Mock: Надіслано wakey відсоток відкриття $percent (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendTempControlState(bool enabled) async {
    print('MQTT Mock: Надіслано temp control стан ${enabled ? "on" : "off"} (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendTempThreshold(double threshold) async {
    print('MQTT Mock: Надіслано температурний поріг $threshold (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendTempClosurePercent(int percent) async {
    print('MQTT Mock: Надіслано відсоток закриття $percent (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWeatherControlState(bool enabled) async {
    print('MQTT Mock: Надіслано weather control стан ${enabled ? "on" : "off"} (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWeatherCondition(String condition) async {
    print('MQTT Mock: Надіслано погодні умови $condition (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendWeatherOpenPercent(int percent) async {
    print('MQTT Mock: Надіслано відсоток відкриття $percent (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendSelectedWeatherConditions(Set<String> conditions) async {
    print('MQTT Mock: Надіслано вибрані умови ${conditions.join(",")} (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendSaveAutoSettings() async {
    print('MQTT Mock: Надіслано команду збереження (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> sendLocation(double latitude, double longitude) async {
    print('MQTT Mock: Надіслано координати $latitude,$longitude (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  Future<void> publishMessage(String topic, String message) async {
    print('MQTT Mock: Опубліковано в $topic: $message (не реально)');
    throw UnsupportedError('MQTT не підтримується на веб-платформі');
  }

  @override
  void subscribeToFeedback(void Function(String topic, String message) callback) {
    print('MQTT Mock: Підписка на зворотний зв\'язок (не реально)');
    // Нічого не робимо на вебі
  }

  @override
  void unsubscribeFromFeedback() {
    print('MQTT Mock: Скасовано підписку (не реально)');
    // Нічого не робимо на вебі
  }
}
