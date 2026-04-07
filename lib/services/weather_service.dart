import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервіс для отримання даних про погоду з OpenWeatherMap API
class WeatherService {
  static const String _apiKey =
      'e5ccefc2d5dbe8656d8531be07d232de'; // Замініть на ваш API ключ
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Отримати поточну погоду за координатами
  Future<WeatherData?> getCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return WeatherData.fromJson(data);
      } else {
        print('Помилка API погоди: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Помилка отримання погоди: $e');
      return null;
    }
  }

  /// Отримати час світанку для координат з OpenWeatherMap API
  Future<DateTime?> getSunriseTime(double latitude, double longitude) async {
    try {
      final weather = await getCurrentWeather(latitude, longitude);
      return weather?.sunrise;
    } catch (e) {
      print('Помилка отримання часу світанку: $e');
      return null;
    }
  }

  /// Отримати прогноз погоди на найближчі години
  Future<List<WeatherData>> getHourlyForecast(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&cnt=8',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = data['list'] as List;
        return list
            .map((item) => WeatherData.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('Помилка API прогнозу: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Помилка отримання прогнозу: $e');
      return [];
    }
  }

  /// Перевірити чи є небезпечні погодні умови
  bool hasHazardousConditions(
    WeatherData weather,
    Set<String> monitoredConditions,
  ) {
    for (final condition in weather.conditions) {
      if (monitoredConditions.contains(condition.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

/// Клас даних про погоду
class WeatherData {
  final double temperature;
  final List<String> conditions;
  final String description;
  final double humidity;
  final DateTime timestamp;
  final DateTime? sunrise;

  WeatherData({
    required this.temperature,
    required this.conditions,
    required this.description,
    required this.humidity,
    required this.timestamp,
    this.sunrise,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final sys =
        json['sys'] is Map<String, dynamic>
            ? json['sys'] as Map<String, dynamic>
            : null;

    // Отримуємо всі можливі погодні умови
    final conditions = <String>[];
    final mainCondition = weather['main'] as String;
    conditions.add(mainCondition.toLowerCase());

    // Додаткові умови на основі ID
    final weatherId = weather['id'] as int;
    if (weatherId >= 200 && weatherId < 300) {
      conditions.add('thunderstorm');
    } else if (weatherId >= 300 && weatherId < 600) {
      conditions.add('rain');
    } else if (weatherId >= 800 && weatherId < 900) {
      if (weatherId == 801 || weatherId == 802) {
        conditions.add('clouds');
      }
    }

    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      conditions: conditions,
      description: weather['description'] as String,
      humidity: (main['humidity'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
      sunrise:
          (sys != null && sys['sunrise'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(
                (sys['sunrise'] as int) * 1000,
                isUtc: true,
              ).toLocal()
              : null,
    );
  }
}
