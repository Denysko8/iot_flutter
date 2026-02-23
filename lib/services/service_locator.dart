import 'package:iot_flutter/data/repositories/user_repository.dart';
import 'package:iot_flutter/data/repositories/user_repository_impl.dart';
import 'package:iot_flutter/domain/usecases/user_usecase.dart';
import 'package:iot_flutter/domain/validators/user_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late SharedPreferences _prefs;
  late UserRepository _userRepository;
  late UserValidator _userValidator;
  late UserUseCase _userUseCase;

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  /// Ініціалізація всіх залежностей
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _userRepository = UserRepositoryImpl(_prefs);
    _userValidator = UserValidatorImpl();
    _userUseCase = UserUseCase(
      userRepository: _userRepository,
      userValidator: _userValidator,
    );
  }

  // Getters для отримання залежностей
  SharedPreferences get prefs => _prefs;
  UserRepository get userRepository => _userRepository;
  UserValidator get userValidator => _userValidator;
  UserUseCase get userUseCase => _userUseCase;
}
