import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:iot_flutter/domain/repositories/i_smart_window_repository.dart';

/// Реалізація MQTT репозиторію для управління розумним вікном
class MqttWindowRepository implements ISmartWindowRepository {
  late MqttServerClient _client;
  final String brokerAddress;
  final int brokerPort;

  static const String _manualPositionTopic = 'smart_window/manual/position';

  // Wakey topics
  static const String _wakeyStateTopic = 'smart_window/auto/wakey/state';
  static const String _wakeyModeTopic = 'smart_window/auto/wakey/mode';
  static const String _wakeyTimeTopic = 'smart_window/auto/wakey/time';
  static const String _wakeyMinutesBeforeTopic =
      'smart_window/auto/wakey/minutes_before';
  static const String _wakeyOpenPercentTopic =
      'smart_window/auto/wakey/open_percent';

  // Temperature topics
  static const String _tempControlStateTopic = 'smart_window/auto/temp/state';
  static const String _tempThresholdTopic = 'smart_window/auto/temp/threshold';
  static const String _tempClosureTopic = 'smart_window/auto/temp/closure';

  // Weather topics
  static const String _weatherControlStateTopic =
      'smart_window/auto/weather/state';
  static const String _weatherConditionsTopic =
      'smart_window/auto/weather/conditions';
  static const String _weatherOpenPercentTopic =
      'smart_window/auto/weather/open_percent';

  // Save command topic
  static const String _saveAutoSettingsTopic = 'smart_window/auto/save';

  // Location topic
  static const String _locationTopic = 'smart_window/location';

  // Feedback topics
  static const String _feedbackPositionTopic = 'smart_window/feedback/position';
  static const String _feedbackStatusTopic = 'smart_window/feedback/status';
  static const String _feedbackErrorTopic = 'smart_window/feedback/error';
  static const String _feedbackSavedTopic = 'smart_window/feedback/saved';

  // Feedback for auto settings
  static const String _feedbackWakeyEnabledTopic =
      'smart_window/feedback/wakey/enabled';
  static const String _feedbackWakeyModeTopic =
      'smart_window/feedback/wakey/mode';
  static const String _feedbackWakeyTimeTopic =
      'smart_window/feedback/wakey/time';
  static const String _feedbackWakeyMinutesTopic =
      'smart_window/feedback/wakey/minutes';

  static const String _feedbackTempEnabledTopic =
      'smart_window/feedback/temp/enabled';
  static const String _feedbackTempThresholdTopic =
      'smart_window/feedback/temp/threshold';
  static const String _feedbackTempClosureTopic =
      'smart_window/feedback/temp/closure';

  static const String _feedbackWeatherEnabledTopic =
      'smart_window/feedback/weather/enabled';
  static const String _feedbackWeatherConditionsTopic =
      'smart_window/feedback/weather/conditions';
  static const String _feedbackWeatherOpenTopic =
      'smart_window/feedback/weather/open';

  void Function(String topic, String message)? _feedbackCallback;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;

  MqttWindowRepository({required this.brokerAddress, this.brokerPort = 1883}) {
    _initializeClient();
  }

  void _initializeClient() {
    _client = MqttServerClient.withPort(
      brokerAddress,
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      brokerPort,
    );
    _client.logging(on: false);
    _client.keepAlivePeriod = 60;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;
    _client.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
        )
        .withWillTopic('smart_window/will')
        .withWillMessage('Flutter client disconnected')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMessage;
  }

  @override
  Future<bool> connect() async {
    try {
      print('MQTT: Підключення до брокера $brokerAddress:$brokerPort...');
      await _client.connect();

      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        print('MQTT: Успішно підключено до брокера');
        _subscribeToAllFeedbackTopics();
        return true;
      } else {
        print('MQTT: Помилка підключення - ${_client.connectionStatus}');
        return false;
      }
    } catch (e) {
      print('MQTT: Помилка - $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _subscription?.cancel();
      _subscription = null;
      _client.disconnect();
      print('MQTT: Від\'єднано від брокера');
    } catch (e) {
      print('MQTT: Помилка при від\'єднанні - $e');
    }
  }

  @override
  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<void> sendManualPosition(int position) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    if (position < 0 || position > 100)
      throw ArgumentError('Позиція має бути в діапазоні 0-100');
    _publishMessage(_manualPositionTopic, position.toString());
    print('MQTT: Надіслано ручну позицію: $position');
  }

  @override
  Future<void> sendWakeyState(bool enabled) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    final state = enabled ? 'on' : 'off';
    _publishMessage(_wakeyStateTopic, state);
    print('MQTT: Надіслано wakey стан: $state');
  }

  @override
  Future<void> sendWakeyMode(bool atDawn) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    final mode = atDawn ? 'at_dawn' : 'custom';
    _publishMessage(_wakeyModeTopic, mode);
    print('MQTT: Надіслано wakey режим: $mode');
  }

  @override
  Future<void> sendWakeyTime(String time) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    _publishMessage(_wakeyTimeTopic, time);
    print('MQTT: Надіслано час будильника: $time');
  }

  @override
  Future<void> sendWakeyMinutesBefore(int minutes) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    _publishMessage(_wakeyMinutesBeforeTopic, minutes.toString());
    print('MQTT: Надіслано хвилини перед пробудженням: $minutes');
  }

  @override
  Future<void> sendWakeyOpenPercent(int percent) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    if (percent < 0 || percent > 100)
      throw ArgumentError('Відсоток має бути в діапазоні 0-100');
    _publishMessage(_wakeyOpenPercentTopic, percent.toString());
    print('MQTT: Надіслано wakey відсоток відкриття: $percent');
  }

  @override
  Future<void> sendTempControlState(bool enabled) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    final state = enabled ? 'on' : 'off';
    _publishMessage(_tempControlStateTopic, state);
    print('MQTT: Надіслано temperature control стан: $state');
  }

  @override
  Future<void> sendTempThreshold(double threshold) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    _publishMessage(_tempThresholdTopic, threshold.toString());
    print('MQTT: Надіслано температурний поріг: $threshold');
  }

  @override
  Future<void> sendTempClosurePercent(int percent) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    if (percent < 0 || percent > 100)
      throw ArgumentError('Відсоток має бути в діапазоні 0-100');
    _publishMessage(_tempClosureTopic, percent.toString());
    print('MQTT: Надіслано відсоток закриття при температурі: $percent');
  }

  @override
  Future<void> sendWeatherControlState(bool enabled) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    final state = enabled ? 'on' : 'off';
    _publishMessage(_weatherControlStateTopic, state);
    print('MQTT: Надіслано weather control стан: $state');
  }

  @override
  Future<void> sendWeatherCondition(String condition) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    _publishMessage(_weatherConditionsTopic, condition);
    print('MQTT: Надіслано погодні умови: $condition');
  }

  @override
  Future<void> sendWeatherOpenPercent(int percent) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    if (percent < 0 || percent > 100)
      throw ArgumentError('Відсоток має бути в діапазоні 0-100');
    _publishMessage(_weatherOpenPercentTopic, percent.toString());
    print('MQTT: Надіслано відсоток відкриття при погоді: $percent');
  }

  @override
  Future<void> sendSelectedWeatherConditions(Set<String> conditions) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    final conditionsString = conditions.join(',');
    _publishMessage(_weatherConditionsTopic, conditionsString);
    print('MQTT: Надіслано вибрані погодні умови: $conditionsString');
  }

  @override
  Future<void> sendSaveAutoSettings() async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    _publishMessage(_saveAutoSettingsTopic, 'save');
    print('MQTT: Надіслано команду збереження автоматичних налаштувань');
  }

  @override
  Future<void> sendLocation(double latitude, double longitude) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    final location = '$latitude,$longitude';
    _publishMessage(_locationTopic, location);
    print('MQTT: Надіслано координати: $location');
  }

  @override
  Future<void> publishMessage(String topic, String message) async {
    if (!isConnected) throw Exception('MQTT: Немає підключення до брокера');
    _publishMessage(topic, message);
  }

  @override
  void subscribeToFeedback(
    void Function(String topic, String message) callback,
  ) {
    _subscription?.cancel();
    _subscription = null;
    _feedbackCallback = callback;
    if (isConnected) {
      _subscribeToAllFeedbackTopics();
      _subscription = _client.updates?.listen((
        List<MqttReceivedMessage<MqttMessage>> messages,
      ) {
        for (final message in messages) {
          final topic = message.topic;
          final payload = MqttPublishPayload.bytesToStringAsString(
            (message.payload as MqttPublishMessage).payload.message,
          );
          print('MQTT: Отримано повідомлення з топіку $topic: $payload');
          if (_feedbackCallback != null) _feedbackCallback!(topic, payload);
        }
      });
    }
  }

  @override
  void unsubscribeFromFeedback() {
    _subscription?.cancel();
    _subscription = null;
    _feedbackCallback = null;
    if (isConnected) {
      _client.unsubscribe(_feedbackPositionTopic);
      _client.unsubscribe(_feedbackStatusTopic);
      _client.unsubscribe(_feedbackErrorTopic);
      print('MQTT: Скасовано підписку на зворотний зв\'язок');
    }
  }

  void _publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _subscribeToAllFeedbackTopics() {
    _client.subscribe(_feedbackPositionTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackStatusTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackErrorTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackSavedTopic, MqttQos.atLeastOnce);

    // Subscribe to wakey feedback
    _client.subscribe(_feedbackWakeyEnabledTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackWakeyModeTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackWakeyTimeTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackWakeyMinutesTopic, MqttQos.atLeastOnce);
    _client.subscribe('smart_window/feedback/wakey/open', MqttQos.atLeastOnce);

    // Subscribe to temperature feedback
    _client.subscribe(_feedbackTempEnabledTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackTempThresholdTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackTempClosureTopic, MqttQos.atLeastOnce);

    // Subscribe to weather feedback
    _client.subscribe(_feedbackWeatherEnabledTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackWeatherConditionsTopic, MqttQos.atLeastOnce);
    _client.subscribe(_feedbackWeatherOpenTopic, MqttQos.atLeastOnce);

    print('MQTT: Підписано на топіки зворотного зв\'язку');
  }

  void _onConnected() => print('MQTT: Колбек підключення виконано');
  void _onDisconnected() => print('MQTT: Колбек від\'єднання виконано');
  void _onSubscribed(String topic) =>
      print('MQTT: Підписка на топік $topic підтверджена');
}
