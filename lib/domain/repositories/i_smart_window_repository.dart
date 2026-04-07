// ignore_for_file: lines_longer_than_80_chars

/// Абстрактний інтерфейс репозиторію для управління розумним вікном
abstract class ISmartWindowRepository {
  /// Підключення до MQTT брокера
  Future<bool> connect();

  /// Від'єднання від MQTT брокера
  Future<void> disconnect();

  /// Перевірка стану підключення
  bool get isConnected;

  /// Надіслати команду для ручного встановлення позиції вікна
  /// [position] - позиція вікна (0-100)
  Future<void> sendManualPosition(int position);

  /// Надіслати команду для увімкнення/вимкнення wakey стану
  /// [enabled] - true для "on", false для "off"
  Future<void> sendWakeyState(bool enabled);

  /// Надіслати режим wakey (at_dawn або custom)
  /// [atDawn] - true якщо "At dawn", false якщо custom time
  Future<void> sendWakeyMode(bool atDawn);

  /// Надіслати час будильника (тільки якщо не At dawn)
  /// [time] - час у форматі "HH:MM"
  Future<void> sendWakeyTime(String time);

  /// Надіслати хвилини перед пробудженням
  /// [minutes] - кількість хвилин
  Future<void> sendWakeyMinutesBefore(int minutes);

  /// Надіслати відсоток відкриття для wakey режиму
  /// [percent] - відсоток відкриття (0-100)
  Future<void> sendWakeyOpenPercent(int percent);

  /// Надіслати стан temperature control (on/off)
  /// [enabled] - true для "on", false для "off"
  Future<void> sendTempControlState(bool enabled);

  /// Надіслати поріг температури для автоматичного режиму
  /// [threshold] - температурний поріг
  Future<void> sendTempThreshold(double threshold);

  /// Надіслати відсоток закриття для температурного контролю
  /// [percent] - відсоток закриття (0-100)
  Future<void> sendTempClosurePercent(int percent);

  /// Надіслати стан weather control (on/off)
  /// [enabled] - true для "on", false для "off"
  Future<void> sendWeatherControlState(bool enabled);

  /// Надіслати стан погодних умов
  /// [condition] - погодні умови (наприклад, "sunny", "rainy", "cloudy")
  Future<void> sendWeatherCondition(String condition);

  /// Надіслати відсоток відкриття для погодного контролю
  /// [percent] - відсоток відкриття (0-100)
  Future<void> sendWeatherOpenPercent(int percent);

  /// Надіслати вибрані погодні умови
  /// [conditions] - набір вибраних умов (rain, thunderstorm, clouds)
  Future<void> sendSelectedWeatherConditions(Set<String> conditions);

  /// Надіслати команду для збереження автоматичних налаштувань в EEPROM ESP8266
  Future<void> sendSaveAutoSettings();

  /// Надіслати координати локації для отримання погоди
  /// [latitude] - широта
  /// [longitude] - довгота
  Future<void> sendLocation(double latitude, double longitude);

  /// Опублікувати повідомлення в довільний MQTT топік
  /// [topic] - назва топіку
  /// [message] - повідомлення
  Future<void> publishMessage(String topic, String message);

  /// Підписатися на зворотний зв'язок від ESP8266
  /// [callback] - функція зворотного виклику для отримання повідомлень
  void subscribeToFeedback(
    void Function(String topic, String message) callback,
  );

  /// Скасувати підписку на зворотний зв'язок
  void unsubscribeFromFeedback();
}
