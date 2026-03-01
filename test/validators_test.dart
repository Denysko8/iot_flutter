import 'package:flutter_test/flutter_test.dart';
import 'package:iot_flutter/domain/validators/user_validator.dart';
import 'package:iot_flutter/models/user.dart';

void main() {
  group('UserValidator Tests', () {
    final validator = UserValidatorImpl();

    group('validateName', () {
      test('returns error for empty name', () {
        final result = validator.validateName('');
        expect(result, isNotNull);
        expect(result, equals('Ім\'я не може бути порожнім'));
      });

      test('returns error for name too short', () {
        final result = validator.validateName('A');
        expect(result, isNotNull);
      });

      test('returns error for name too long', () {
        final result = validator.validateName('A' * 101);
        expect(result, isNotNull);
      });

      test('returns error for name with digits', () {
        final result = validator.validateName('John123');
        expect(result, isNotNull);
        expect(result, contains('цифри'));
      });

      test('accepts valid names', () {
        expect(validator.validateName('John Doe'), isNull);
        expect(validator.validateName('Mary-Jane'), isNull);
        expect(validator.validateName("O'Connor"), isNull);
      });

      test('rejects special characters', () {
        final result = validator.validateName('John@Doe');
        expect(result, isNotNull);
      });
    });

    group('validateEmail', () {
      test('returns error for empty email', () {
        final result = validator.validateEmail('');
        expect(result, isNotNull);
      });

      test('returns error for email without @', () {
        final result = validator.validateEmail('johngmail.com');
        expect(result, isNotNull);
      });

      test('returns error for email without domain', () {
        final result = validator.validateEmail('john@');
        expect(result, isNotNull);
      });

      test('accepts valid emails', () {
        expect(validator.validateEmail('john@example.com'), isNull);
        expect(validator.validateEmail('john.doe@example.co.uk'), isNull);
        expect(validator.validateEmail('john+tag@example.com'), isNull);
      });
    });

    group('validatePassword', () {
      test('returns error for empty password', () {
        final result = validator.validatePassword('');
        expect(result, isNotNull);
      });

      test('returns error for password too short', () {
        final result = validator.validatePassword('123');
        expect(result, isNotNull);
      });

      test('returns error for password too long', () {
        final result = validator.validatePassword('a' * 129);
        expect(result, isNotNull);
      });

      test('accepts valid passwords', () {
        expect(validator.validatePassword('123456'), isNull);
        expect(validator.validatePassword('SecurePass123!'), isNull);
        expect(validator.validatePassword('a' * 128), isNull);
      });
    });

    group('validatePasswordConfirmation', () {
      test('returns error for mismatched passwords', () {
        final result = validator.validatePasswordConfirmation(
          'password123',
          'password456',
        );
        expect(result, isNotNull);
        expect(result, contains('не збігаються'));
      });

      test('accepts matching passwords', () {
        final result = validator.validatePasswordConfirmation(
          'password123',
          'password123',
        );
        expect(result, isNull);
      });
    });
  });

  group('User Model Tests', () {
    test('creates user with correct data', () {
      const user = User(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'secure123',
      );

      expect(user.name, equals('John Doe'));
      expect(user.email, equals('john@example.com'));
      expect(user.password, equals('secure123'));
    });

    test('converts user to map', () {
      const user = User(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'secure123',
      );

      final map = user.toMap();
      expect(map['name'], equals('John Doe'));
      expect(map['email'], equals('john@example.com'));
      expect(map['password'], equals('secure123'));
    });

    test('creates user from map', () {
      final map = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'password': 'secure123',
      };

      final user = User.fromMap(map);
      expect(user.name, equals('John Doe'));
      expect(user.email, equals('john@example.com'));
      expect(user.password, equals('secure123'));
    });

    test('copyWith creates new user with updated fields', () {
      const user = User(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'secure123',
      );

      final updatedUser = user.copyWith(
        name: 'Jane Doe',
        email: 'jane@example.com',
      );

      expect(updatedUser.name, equals('Jane Doe'));
      expect(updatedUser.email, equals('jane@example.com'));
      expect(updatedUser.password, equals('secure123'));
    });
  });
}
