# IoT Flutter - Smart Blinds Control App

Мобільний додаток для управління розумними жалюзями з локальною реєстрацією користувачів, валідацією даних та управлінням профілем.

## 🌟 Особливості

- ✅ **Локальна реєстрація** - дані зберігаються в SharedPreferences
- ✅ **Валідація даних** - ім'я, email, пароль
- ✅ **Логування користувача** - з перевіркою пароля
- ✅ **Управління профілем** - редагування, видалення, вихід
- ✅ **Clean Architecture** - чіткий розподіл на рівні
- ✅ **Абстрактні інтерфейси** - легко розширювати та тестувати
- ✅ **Мінімум глобального стану** - тільки final та const
- ✅ **Service Locator** - управління залежностями

## 📁 Структура проекту

```
lib/
├── data/           # Рівень даних (SharedPreferences)
├── domain/         # Бізнес-логіка (UserUseCase, Validators)
├── screens/        # UI екрани (Login, Register, Profile, Home)
├── widgets/        # Переиспользуються компоненти
├── models/         # Моделі даних
├── services/       # Service Locator
└── main.dart       # Точка входу
```

## 🚀 Швидкий старт

```bash
# Установити залежності
flutter pub get

# Запустити app
flutter run

# Запустити тести
flutter test
```

## 📚 Документація

- **[QUICKSTART.md](QUICKSTART.md)** - Швидкий старт за 1 хвилину
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Детальна архітектура
- **[USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)** - Приклади коду
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Реалізовано/не реалізовано

## 🔐 Користувацький потік

### Реєстрація
1. Користувач заповнює форму (ім'я, email, пароль)
2. Система валідує дані
3. Дані зберігаються в SharedPreferences
4. Користувач автоматично логується
5. Переведення на HomeScreen

### Логування
1. Користувач вводить email та пароль
2. Система перевіряє дані в SharedPreferences
3. Установлюється активна сесія
4. Переведення на HomeScreen

### Управління профілем
1. Натисніть на іконку профілю в AppBar
2. Натисніть редагування для зміни даних
3. Збережіть зміни (з валідацією)
4. Видаліть акаунт або виконайте вихід

## 🎯 Валідація

| Поле | Правила |
|------|---------|
| Ім'я | Мін 2, макс 100 символів; без цифр |
| Email | Коректний формат (user@domain.com) |
| Пароль | Мін 6, макс 128 символів |
| Підтвердження | Мають збігатися |

## 🔄 Архітектура

### Data Layer
- `UserRepository` - абстрактний інтерфейс
- `UserRepositoryImpl` - реалізація з SharedPreferences

### Domain Layer
- `UserValidator` - валідація даних
- `UserUseCase` - бізнес-логіка операцій користувача

### Presentation Layer
- `LoginScreen` - екран логування
- `RegisterScreen` - екран реєстрації
- `ProfileScreen` - управління профілем
- `HomeScreen` - головна сторінка

## 🧪 Тестування

```bash
# Запустити all tests
flutter test

# Запустити конкретний файл
flutter test test/validators_test.dart

# З покриттям
flutter test --coverage
```

## 🔧 Розширення

Архітектура дозволяє легко додавати нові функції:

```dart
// 1. Додайте метод в UserRepository
abstract class UserRepository {
  Future<bool> myNewFeature(String param);
}

// 2. Реалізуйте в UserRepositoryImpl
@override
Future<bool> myNewFeature(String param) async {
  // реалізація
}

// 3. Додайте в UserUseCase
Future<RegistrationResult> myNewFeature(String param) async {
  // логіка
}

// 4. Використайте в UI
final result = await userUseCase.myNewFeature(param);
```

## 🚀 Міграція на API

Коли потрібно перейти з SharedPreferences на API:

1. Створіть `UserRepositoryApiImpl` implements `UserRepository`
2. Реалізуйте всі методи з HTTP запитами
3. Оновіть `ServiceLocator`
4. ✨ Всі UI екрани залишаться незмінними!

## ⚠️ Важливо

Це проект для **навчальних цілей**. Для production потрібно:

- ❌ Хешувати паролі (використовувати bcrypt)
- ❌ Шифрувати чутливі дані (flutter_secure_storage)
- ❌ Використовувати HTTPS
- ❌ Валідувати на бекенді
- ❌ Додати таймаут сесії
- ❌ Реалізувати 2FA

## 📦 Залежності

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.5.3

dev_dependencies:
  flutter_test:
    sdk: flutter
```

## 📝 Приклади

### Реєстрація
```dart
final userUseCase = ServiceLocator().userUseCase;
final result = await userUseCase.registerUser(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'password123',
  passwordConfirmation: 'password123',
);
```

### Логування
```dart
final result = await userUseCase.loginUser(
  email: 'john@example.com',
  password: 'password123',
);
if (result.success) {
  print('Welcome ${result.user!.name}');
}
```

### Отримання поточного користувача
```dart
final currentUser = await userUseCase.getCurrentUser();
```

## 🎓 Навчальні матеріали

- Clean Architecture в Flutter
- SOLID принципи
- Dependency Injection
- Unit Testing
- Validation Best Practices

## 👨‍💻 Технічні деталі

- **Language**: Dart 3.7+
- **Framework**: Flutter 3.7+
- **Architecture**: Clean Architecture
- **State Management**: StatefulWidget
- **Storage**: SharedPreferences
- **Pattern**: Repository, UseCase, Validator

## 📄 Ліцензія

MIT License

## 🤝 Сприяння

Проект відкритий для внесків та покращень!

---

**Версія:** 1.0.0  
**Дата**: 2024-02-24  
**Статус**: ✅ Готово до розроблення
