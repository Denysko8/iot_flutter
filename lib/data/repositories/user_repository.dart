import 'package:iot_flutter/models/user.dart';

/// Абстрактний репозиторій для роботи з користувачами
abstract class UserRepository {
  /// Реєструє нового користувача
  /// Повертає true якщо успішно, false якщо користувач вже існує
  Future<bool> registerUser(User user);

  /// Перевіряє чи користувач з таким email вже існує
  Future<bool> userExists(String email);

  /// Отримує користувача за email
  /// Повертає User якщо знайдений, null якщо ні
  Future<User?> getUserByEmail(String email);

  /// Оновлює дані користувача
  /// Повертає true якщо успішно, false інакше
  Future<bool> updateUser(User user);

  /// Видаляє користувача за email
  /// Повертає true якщо успішно, false інакше
  Future<bool> deleteUser(String email);

  /// Отримує поточного авторизованого користувача
  /// Повертає User якщо є активна сесія, null якщо ні
  Future<User?> getCurrentUser();

  /// Встановлює поточного користувача (логування)
  Future<void> setCurrentUser(User? user);

  /// Виходить з системи (видаляє активну сесію)
  Future<void> logout();

  /// Отримує всіх користувачів (для адміністративних цілей)
  Future<List<User>> getAllUsers();
}
