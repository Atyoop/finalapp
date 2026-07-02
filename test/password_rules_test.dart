import 'package:flutter_test/flutter_test.dart';

import 'package:final88/widgets/password_requirements.dart';

void main() {
  group('PasswordRules', () {
    test('requires at least 8 characters', () {
      expect(PasswordRules.hasMinLength('Abcde12'), isFalse);
      expect(PasswordRules.hasMinLength('Abcdef12'), isTrue);
    });

    test('requires at least 2 numbers', () {
      expect(PasswordRules.hasMinNumbers('Abcdefg1'), isFalse);
      expect(PasswordRules.hasMinNumbers('Abcdef12'), isTrue);
    });

    test('requires at least 1 uppercase letter', () {
      expect(PasswordRules.hasUppercase('abcdef12'), isFalse);
      expect(PasswordRules.hasUppercase('Abcdef12'), isTrue);
    });

    test('accepts only a password satisfying every requirement', () {
      expect(PasswordRules.isValid('abcdef12'), isFalse);
      expect(PasswordRules.isValid('Abcdef12'), isTrue);
    });
  });
}
