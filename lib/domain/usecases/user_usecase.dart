import 'package:iot_flutter/data/repositories/user_repository.dart';
import 'package:iot_flutter/domain/validators/user_validator.dart';
import 'package:iot_flutter/models/user.dart';

/// Результат операції реєстрації
class RegistrationResult {
  final bool success;
  final String? errorMessage;

  const RegistrationResult({
    required this.success,
    this.errorMessage,
  });

  factory RegistrationResult.success() {
    return const RegistrationResult(success: true);
  }

  factory RegistrationResult.failure(String message) {
    return RegistrationResult(success: false, errorMessage: message);
  }
}

/// Результат операції логування
class LoginResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const LoginResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory LoginResult.success(User user) {
    return LoginResult(success: true, user: user);
  }

  factory LoginResult.failure(String message) {
    return LoginResult(success: false, errorMessage: message);
  }
}

/// Бізнес-логіка для операцій користувача
class UserUseCase {
  final UserRepository _userRepository;
  final UserValidator _userValidator;

  UserUseCase({
    required UserRepository userRepository,
    required UserValidator userValidator,
  })  : _userRepository = userRepository,
        _userValidator = userValidator;

  // Getter для доступу до репозиторію
  UserRepository get userRepository => _userRepository;

  /// Реєструє нового користувача
  Future<RegistrationResult> registerUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    // Валідуємо ім'я
    final nameError = _userValidator.validateName(name);
    if (nameError != null) {
      return RegistrationResult.failure(nameError);
    }

    // Валідуємо email
    final emailError = _userValidator.validateEmail(email);
    if (emailError != null) {
      return RegistrationResult.failure(emailError);
    }

    // Валідуємо паролі
    final passwordError = _userValidator.validatePasswordConfirmation(
      password,
      passwordConfirmation,
    );
    if (passwordError != null) {
      return RegistrationResult.failure(passwordError);
    }

    // Перевіряємо чи користувач вже існує
    final exists = await _userRepository.userExists(email);
    if (exists) {
      return RegistrationResult.failure(
        'Користувач з таким email вже зареєстрований',
      );
    }

    // Реєструємо користувача
    final user = User(name: name, email: email, password: password);
    final registered = await _userRepository.registerUser(user);

    if (!registered) {
      return RegistrationResult.failure('Помилка при реєстрації');
    }

    return RegistrationResult.success();
  }

  /// Логує користувача в систему
  Future<LoginResult> loginUser({
    required String email,
    required String password,
  }) async {
    // Валідуємо email
    final emailError = _userValidator.validateEmail(email);
    if (emailError != null) {
      return LoginResult.failure(emailError);
    }

    // Отримуємо користувача
    final user = await _userRepository.getUserByEmail(email);
    if (user == null) {
      return LoginResult.failure('Користувач не знайдений');
    }

    // Перевіряємо пароль
    if (user.password != password) {
      return LoginResult.failure('Невірний пароль');
    }

    // Встановлюємо поточного користувача
    await _userRepository.setCurrentUser(user);
    return LoginResult.success(user);
  }

  /// Отримує поточного авторизованого користувача
  Future<User?> getCurrentUser() async {
    return await _userRepository.getCurrentUser();
  }

  /// Оновлює дані користувача
  Future<RegistrationResult> updateUser({
    required String currentEmail,
    required String name,
    required String email,
  }) async {
    // Валідуємо ім'я
    final nameError = _userValidator.validateName(name);
    if (nameError != null) {
      return RegistrationResult.failure(nameError);
    }

    // Валідуємо email
    final emailError = _userValidator.validateEmail(email);
    if (emailError != null) {
      return RegistrationResult.failure(emailError);
    }

    // Отримуємо поточного користувача
    final currentUser = await _userRepository.getUserByEmail(currentEmail);
    if (currentUser == null) {
      return RegistrationResult.failure('Користувач не знайдений');
    }

    // Якщо email змінився, перевіряємо що він не занятий іншим користувачем
    if (email != currentEmail) {
      final newEmailExists = await _userRepository.userExists(email);
      if (newEmailExists) {
        return RegistrationResult.failure(
          'Email вже використовується іншим користувачем',
        );
      }

      // Видаляємо старого користувача та створюємо нового
      await _userRepository.deleteUser(currentEmail);
      final updatedUser = User(
        name: name,
        email: email,
        password: currentUser.password,
      );
      final registered = await _userRepository.registerUser(updatedUser);
      if (!registered) {
        return RegistrationResult.failure('Помилка при оновленні користувача');
      }
      await _userRepository.setCurrentUser(updatedUser);
    } else {
      // Просто оновлюємо дані
      final updatedUser = User(
        name: name,
        email: email,
        password: currentUser.password,
      );
      final updated = await _userRepository.updateUser(updatedUser);
      if (!updated) {
        return RegistrationResult.failure('Помилка при оновленні користувача');
      }
      await _userRepository.setCurrentUser(updatedUser);
    }

    return RegistrationResult.success();
  }

  /// Видаляє користувача
  Future<bool> deleteUser(String email) async {
    return await _userRepository.deleteUser(email);
  }

  /// Виходить з системи
  Future<void> logout() async {
    await _userRepository.logout();
  }
}
