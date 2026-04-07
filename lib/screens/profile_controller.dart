import 'package:iot_flutter/domain/usecases/user_usecase.dart';
import 'package:iot_flutter/models/user.dart';
import 'package:iot_flutter/services/location_service.dart';
import 'package:iot_flutter/services/service_locator.dart';

/// Контролер для управління профілем користувача
class ProfileController {
  User? currentUser;
  bool isLoading = true;
  bool isEditing = false;
  String? errorMessage;
  String? successMessage;
  bool isLoadingLocation = false;

  late UserUseCase _userUseCase;
  late LocationService _locationService;

  ProfileController() {
    _userUseCase = ServiceLocator().userUseCase;
    _locationService = ServiceLocator().locationService;
  }

  /// Завантажує поточного користувача
  Future<void> loadUser() async {
    try {
      currentUser = await _userUseCase.getCurrentUser();
      isLoading = false;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Помилка при завантаженні профілю';
    }
  }

  /// Перемикає режим редагування
  void toggleEditMode() {
    isEditing = !isEditing;
    errorMessage = null;
    successMessage = null;
  }

  /// Зберігає зміни профілю
  Future<bool> saveChanges(String newName, String newEmail) async {
    if (currentUser == null) return false;

    errorMessage = null;
    successMessage = null;

    final result = await _userUseCase.updateUser(
      currentEmail: currentUser!.email,
      name: newName.trim(),
      email: newEmail.trim(),
    );

    if (result.success) {
      successMessage = 'Профіль успішно оновлено';
      isEditing = false;
      currentUser = User(
        name: newName.trim(),
        email: newEmail.trim(),
        password: currentUser!.password,
        city: currentUser!.city,
        latitude: currentUser!.latitude,
        longitude: currentUser!.longitude,
      );
      await ServiceLocator().mockApiStorageService.syncUser(currentUser!);
      return true;
    } else {
      errorMessage = result.errorMessage;
      return false;
    }
  }

  /// Отримати поточну локацію користувача
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final hasInternet =
          await ServiceLocator().connectivityService.checkConnection();
      if (!hasInternet) {
        errorMessage = 'Відсутнє підключення до Інтернету';
        return null;
      }

      isLoadingLocation = true;
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        errorMessage = 'Не вдалося отримати локацію. Перевірте дозволи.';
        isLoadingLocation = false;
        return null;
      }

      final city = await _locationService.getCityName(
        position.latitude,
        position.longitude,
      );

      isLoadingLocation = false;
      return {
        'city': city ?? 'Unknown',
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      errorMessage = 'Помилка отримання локації: $e';
      isLoadingLocation = false;
      return null;
    }
  }

  /// Встановити локацію вручну за назвою міста
  Future<Map<String, dynamic>?> setLocationByCity(String cityName) async {
    try {
      final hasInternet =
          await ServiceLocator().connectivityService.checkConnection();
      if (!hasInternet) {
        errorMessage = 'Відсутнє підключення до Інтернету';
        return null;
      }

      isLoadingLocation = true;
      final location = await _locationService.getCoordinatesFromCity(cityName);

      if (location == null) {
        errorMessage = 'Не вдалося знайти місто "$cityName"';
        isLoadingLocation = false;
        return null;
      }

      isLoadingLocation = false;
      return {
        'city': cityName,
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    } catch (e) {
      errorMessage = 'Помилка пошуку міста: $e';
      isLoadingLocation = false;
      return null;
    }
  }

  /// Зберегти локацію в профіль користувача
  Future<bool> saveLocation(
    String city,
    double latitude,
    double longitude,
  ) async {
    if (currentUser == null) return false;

    try {
      // Оновлюємо користувача з новою локацією
      final updatedUser = currentUser!.copyWith(
        city: city,
        latitude: latitude,
        longitude: longitude,
      );

      // Зберігаємо в репозиторій
      await _userUseCase.userRepository.updateUser(updatedUser);
      await _userUseCase.userRepository.setCurrentUser(updatedUser);
      await ServiceLocator().mockApiStorageService.syncUser(updatedUser);

      currentUser = updatedUser;
      successMessage = 'Локацію збережено: $city';
      return true;
    } catch (e) {
      errorMessage = 'Помилка збереження локації: $e';
      return false;
    }
  }

  /// Видаляє акаунт користувача
  Future<bool> deleteAccount() async {
    if (currentUser == null) return false;

    try {
      return await _userUseCase.deleteUser(currentUser!.email);
    } catch (e) {
      errorMessage = 'Помилка при видаленні акаунту';
      return false;
    }
  }

  /// Виходить з системи
  Future<void> logout() async {
    try {
      await _userUseCase.logout();
    } catch (e) {
      errorMessage = 'Помилка при виході з системи';
    }
  }

  /// Очищує сповіщення про успіх
  void clearSuccessMessage() {
    successMessage = null;
  }

  /// Очищує сповіщення про помилку
  void clearErrorMessage() {
    errorMessage = null;
  }
}
