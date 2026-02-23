import 'package:iot_flutter/domain/usecases/user_usecase.dart';
import 'package:iot_flutter/models/user.dart';
import 'package:iot_flutter/services/service_locator.dart';

/// Контролер для управління профілем користувача
class ProfileController {
  User? currentUser;
  bool isLoading = true;
  bool isEditing = false;
  String? errorMessage;
  String? successMessage;

  late UserUseCase _userUseCase;

  ProfileController() {
    _userUseCase = ServiceLocator().userUseCase;
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
      );
      return true;
    } else {
      errorMessage = result.errorMessage;
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
}
