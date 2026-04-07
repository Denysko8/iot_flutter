import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Сервіс для перевірки підключення до Інтернету
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Стрім для відслідковування змін підключення
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Колбек для сповіщення про зміни підключення
  void Function(bool isConnected)? _onConnectivityChanged;

  /// Перевірити поточний стан підключення до Інтернету
  Future<bool> checkConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return _isConnected(connectivityResult);
    } catch (e) {
      print('ConnectivityService: Помилка при перевірці підключення - $e');
      return false;
    }
  }

  /// Почати відслідковування змін підключення
  void startMonitoring(void Function(bool isConnected) onConnectivityChanged) {
    _onConnectivityChanged = onConnectivityChanged;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = _isConnected(results);
        print('ConnectivityService: Стан підключення змінено - ${isConnected ? "підключено" : "відключено"}');
        _onConnectivityChanged?.call(isConnected);
      },
    );
  }

  /// Зупинити відслідковування змін підключення
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _onConnectivityChanged = null;
  }

  /// Перевірити, чи є підключення на основі результату connectivity
  bool _isConnected(List<ConnectivityResult> results) {
    // Якщо є хоча б одне підключення (WiFi, mobile, ethernet), то вважаємо, що є Інтернет
    return results.any((result) =>
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );
  }

  /// Очистити ресурси
  void dispose() {
    stopMonitoring();
  }
}
