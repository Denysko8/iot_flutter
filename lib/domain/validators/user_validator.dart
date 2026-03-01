/// Абстрактний інтерфейс для валідації даних користувача
abstract class UserValidator {
  /// Валідує ім'я користувача
  /// Повертає null якщо валідне, інакше повертає повідомлення про помилку
  String? validateName(String name);

  /// Валідує email
  String? validateEmail(String email);

  /// Валідує пароль
  String? validatePassword(String password);

  /// Валідує підтвердження пароля
  String? validatePasswordConfirmation(String password, String confirmation);
}

/// Реалізація валідатора користувача
class UserValidatorImpl implements UserValidator {
  @override
  String? validateName(String name) {
    if (name.isEmpty) {
      return 'Ім\'я не може бути порожнім';
    }
    if (name.length < 2) {
      return 'Ім\'я повинно містити щонайменше 2 символи';
    }
    if (name.length > 100) {
      return 'Ім\'я не повинно перевищувати 100 символів';
    }
    // Перевіряємо що ім'я не містить цифр
    if (RegExp(r'\d').hasMatch(name)) {
      return 'Ім\'я не може містити цифри';
    }
    // Дозволяємо букви, пробіли та дефіси
    if (!RegExp(r"^[a-яіїєґA-Za-z\s\-']*$", unicode: true).hasMatch(name)) {
      return 'Ім\'я може містити тільки букви, пробіли, дефіси та апострофи';
    }
    return null;
  }

  @override
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email не може бути порожнім';
    }
    // Базова валідація email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Введіть коректний email адресу';
    }
    return null;
  }

  @override
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Пароль не може бути порожнім';
    }
    if (password.length < 6) {
      return 'Пароль повинен містити щонайменше 6 символів';
    }
    if (password.length > 128) {
      return 'Пароль не повинен перевищувати 128 символів';
    }
    return null;
  }

  @override
  String? validatePasswordConfirmation(String password, String confirmation) {
    final passwordValidation = validatePassword(password);
    if (passwordValidation != null) {
      return passwordValidation;
    }
    if (password != confirmation) {
      return 'Паролі не збігаються';
    }
    return null;
  }
}
