import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/domain/usecases/user_usecase.dart';
import 'package:iot_flutter/models/user.dart';
import 'package:iot_flutter/services/connectivity_service.dart';
import 'package:iot_flutter/services/mock_api_storage_service.dart';

enum AuthStatus { initial, loading, success, failure, noInternet }

class AuthState {
  final AuthStatus status;
  final String? message;
  final User? user;

  const AuthState({this.status = AuthStatus.initial, this.message, this.user});

  AuthState copyWith({AuthStatus? status, String? message, User? user}) {
    return AuthState(
      status: status ?? this.status,
      message: message,
      user: user ?? this.user,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final UserUseCase _userUseCase;
  final ConnectivityService _connectivityService;
  final MockApiStorageService _mockApiStorageService;

  AuthCubit({
    required UserUseCase userUseCase,
    required ConnectivityService connectivityService,
    required MockApiStorageService mockApiStorageService,
  }) : _userUseCase = userUseCase,
       _connectivityService = connectivityService,
       _mockApiStorageService = mockApiStorageService,
       super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final hasConnection = await _connectivityService.checkConnection();
    if (!hasConnection) {
      emit(
        state.copyWith(
          status: AuthStatus.noInternet,
          message:
              'Для входу в систему необхідне підключення до Інтернету. '
              'Будь ласка, перевірте з\'єднання.',
        ),
      );
      return;
    }

    final result = await _userUseCase.loginUser(
      email: email.trim(),
      password: password,
    );

    if (!result.success) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: result.errorMessage,
        ),
      );
      return;
    }

    if (result.user != null) {
      await _mockApiStorageService.syncUser(result.user!);
    }

    emit(state.copyWith(status: AuthStatus.success, user: result.user));
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _userUseCase.registerUser(
      name: name.trim(),
      email: email.trim(),
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    if (!result.success) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: result.errorMessage,
        ),
      );
      return;
    }

    final loginResult = await _userUseCase.loginUser(
      email: email.trim(),
      password: password,
    );

    if (!loginResult.success) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: loginResult.errorMessage ?? 'Помилка входу після реєстрації',
        ),
      );
      return;
    }

    if (loginResult.user != null) {
      await _mockApiStorageService.syncUser(loginResult.user!);
    }

    emit(state.copyWith(status: AuthStatus.success, user: loginResult.user));
  }

  void clearMessage() {
    emit(state.copyWith(status: AuthStatus.initial));
  }
}
