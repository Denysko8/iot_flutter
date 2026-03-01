import 'dart:convert';

import 'package:iot_flutter/data/repositories/user_repository.dart';
import 'package:iot_flutter/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Реалізація репозиторію користувачів з використанням SharedPreferences
class UserRepositoryImpl implements UserRepository {
  final SharedPreferences _preferences;

  // Константи для ключів SharedPreferences
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  UserRepositoryImpl(this._preferences);

  /// Отримує усіх користувачів із локального сховища
  Map<String, User> _getAllUsersMap() {
    final String? usersJson = _preferences.getString(_usersKey);
    if (usersJson == null) {
      return {};
    }

    try {
      final Map<String, dynamic> decodedData =
          jsonDecode(usersJson) as Map<String, dynamic>;
      return decodedData.map(
        (email, userData) => MapEntry(
          email,
          User.fromMap(userData as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      return {};
    }
  }

  /// Зберігає всіх користувачів у локальне сховище
  Future<void> _saveAllUsers(Map<String, User> users) async {
    final usersMap = users.map(
      (email, user) => MapEntry(email, user.toMap()),
    );
    await _preferences.setString(_usersKey, jsonEncode(usersMap));
  }

  @override
  Future<bool> registerUser(User user) async {
    final users = _getAllUsersMap();

    // Перевіряємо що користувач вже не існує
    if (users.containsKey(user.email)) {
      return false;
    }

    users[user.email] = user;
    await _saveAllUsers(users);
    return true;
  }

  @override
  Future<bool> userExists(String email) async {
    final users = _getAllUsersMap();
    return users.containsKey(email);
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    final users = _getAllUsersMap();
    return users[email];
  }

  @override
  Future<bool> updateUser(User user) async {
    final users = _getAllUsersMap();

    // Перевіряємо що користувач існує
    if (!users.containsKey(user.email)) {
      return false;
    }

    users[user.email] = user;
    await _saveAllUsers(users);

    // Оновлюємо поточного користувача якщо це він
    final currentUser = await getCurrentUser();
    if (currentUser?.email == user.email) {
      await setCurrentUser(user);
    }

    return true;
  }

  @override
  Future<bool> deleteUser(String email) async {
    final users = _getAllUsersMap();

    if (!users.containsKey(email)) {
      return false;
    }

    users.remove(email);
    await _saveAllUsers(users);

    // Виходимо якщо видалили поточного користувача
    final currentUser = await getCurrentUser();
    if (currentUser?.email == email) {
      await logout();
    }

    return true;
  }

  @override
  Future<User?> getCurrentUser() async {
    final String? currentUserJson = _preferences.getString(_currentUserKey);
    if (currentUserJson == null) {
      return null;
    }

    try {
      final Map<String, dynamic> decodedData =
          jsonDecode(currentUserJson) as Map<String, dynamic>;
      return User.fromMap(decodedData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setCurrentUser(User? user) async {
    if (user == null) {
      await _preferences.remove(_currentUserKey);
    } else {
      await _preferences.setString(_currentUserKey, jsonEncode(user.toMap()));
    }
  }

  @override
  Future<void> logout() async {
    await setCurrentUser(null);
  }

  @override
  Future<List<User>> getAllUsers() async {
    final users = _getAllUsersMap();
    return users.values.toList();
  }
}
