import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/domain/usecases/user_usecase.dart';
import 'package:iot_flutter/models/user.dart';
import 'package:iot_flutter/services/connectivity_service.dart';
import 'package:iot_flutter/services/location_service.dart';
import 'package:iot_flutter/services/mock_api_storage_service.dart';

class ProfileState {
  final User? currentUser;
  final bool isLoading;
  final bool isEditing;
  final bool isLoadingLocation;
  final String? errorMessage;
  final String? successMessage;
  final bool accountDeleted;
  final bool loggedOut;

  const ProfileState({
    this.currentUser,
    this.isLoading = true,
    this.isEditing = false,
    this.isLoadingLocation = false,
    this.errorMessage,
    this.successMessage,
    this.accountDeleted = false,
    this.loggedOut = false,
  });

  ProfileState copyWith({
    User? currentUser,
    bool? isLoading,
    bool? isEditing,
    bool? isLoadingLocation,
    String? errorMessage,
    String? successMessage,
    bool? accountDeleted,
    bool? loggedOut,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      accountDeleted: accountDeleted ?? this.accountDeleted,
      loggedOut: loggedOut ?? this.loggedOut,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  final UserUseCase _userUseCase;
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  final MockApiStorageService _mockApiStorageService;

  ProfileCubit({
    required UserUseCase userUseCase,
    required LocationService locationService,
    required ConnectivityService connectivityService,
    required MockApiStorageService mockApiStorageService,
  }) : _userUseCase = userUseCase,
       _locationService = locationService,
       _connectivityService = connectivityService,
       _mockApiStorageService = mockApiStorageService,
       super(const ProfileState());

  Future<void> loadUser() async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    try {
      final user = await _userUseCase.getCurrentUser();
      emit(state.copyWith(currentUser: user, isLoading: false));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Помилка при завантаженні профілю',
        ),
      );
    }
  }

  void toggleEditMode() {
    emit(
      state.copyWith(
        isEditing: !state.isEditing,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  Future<bool> saveChanges(String newName, String newEmail) async {
    final currentUser = state.currentUser;
    if (currentUser == null) return false;

    final result = await _userUseCase.updateUser(
      currentEmail: currentUser.email,
      name: newName.trim(),
      email: newEmail.trim(),
    );

    if (!result.success) {
      emit(
        state.copyWith(errorMessage: result.errorMessage, clearSuccess: true),
      );
      return false;
    }

    final updatedUser = User(
      name: newName.trim(),
      email: newEmail.trim(),
      password: currentUser.password,
      city: currentUser.city,
      latitude: currentUser.latitude,
      longitude: currentUser.longitude,
    );

    await _mockApiStorageService.syncUser(updatedUser);

    emit(
      state.copyWith(
        currentUser: updatedUser,
        isEditing: false,
        successMessage: 'Профіль успішно оновлено',
        clearError: true,
      ),
    );
    return true;
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    final hasInternet = await _connectivityService.checkConnection();
    if (!hasInternet) {
      emit(state.copyWith(errorMessage: 'Відсутнє підключення до Інтернету'));
      return null;
    }

    emit(state.copyWith(isLoadingLocation: true, clearError: true));

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        emit(
          state.copyWith(
            isLoadingLocation: false,
            errorMessage: 'Не вдалося отримати локацію. Перевірте дозволи.',
          ),
        );
        return null;
      }

      final city = await _locationService.getCityName(
        position.latitude,
        position.longitude,
      );

      emit(state.copyWith(isLoadingLocation: false));
      return {
        'city': city ?? 'Unknown',
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingLocation: false,
          errorMessage: 'Помилка отримання локації: $e',
        ),
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> setLocationByCity(String cityName) async {
    final hasInternet = await _connectivityService.checkConnection();
    if (!hasInternet) {
      emit(state.copyWith(errorMessage: 'Відсутнє підключення до Інтернету'));
      return null;
    }

    emit(state.copyWith(isLoadingLocation: true, clearError: true));

    try {
      final location = await _locationService.getCoordinatesFromCity(cityName);
      if (location == null) {
        emit(
          state.copyWith(
            isLoadingLocation: false,
            errorMessage: 'Не вдалося знайти місто "$cityName"',
          ),
        );
        return null;
      }

      emit(state.copyWith(isLoadingLocation: false));
      return {
        'city': cityName,
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingLocation: false,
          errorMessage: 'Помилка пошуку міста: $e',
        ),
      );
      return null;
    }
  }

  Future<bool> saveLocation(
    String city,
    double latitude,
    double longitude,
  ) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      final updatedUser = currentUser.copyWith(
        city: city,
        latitude: latitude,
        longitude: longitude,
      );

      await _userUseCase.userRepository.updateUser(updatedUser);
      await _userUseCase.userRepository.setCurrentUser(updatedUser);
      await _mockApiStorageService.syncUser(updatedUser);

      emit(
        state.copyWith(
          currentUser: updatedUser,
          successMessage: 'Локацію збережено: $city',
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Помилка збереження локації: $e'));
      return false;
    }
  }

  Future<void> deleteAccount() async {
    final currentUser = state.currentUser;
    if (currentUser == null) return;

    try {
      final success = await _userUseCase.deleteUser(currentUser.email);
      if (success) {
        emit(state.copyWith(accountDeleted: true));
      } else {
        emit(state.copyWith(errorMessage: 'Помилка при видаленні акаунту'));
      }
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Помилка при видаленні акаунту'));
    }
  }

  Future<void> logout() async {
    try {
      await _userUseCase.logout();
      emit(state.copyWith(loggedOut: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Помилка при виході з системи'));
    }
  }

  void clearSuccessMessage() {
    emit(state.copyWith(clearSuccess: true));
  }

  void clearErrorMessage() {
    emit(state.copyWith(clearError: true));
  }

  void clearNavigationFlags() {
    emit(state.copyWith(accountDeleted: false, loggedOut: false));
  }
}
