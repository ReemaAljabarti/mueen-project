import 'package:flutter_test/flutter_test.dart';

bool isValidSaudiPhone(String phone) {
  final trimmedPhone = phone.trim();
  return RegExp(r'^05\d{8}$').hasMatch(trimmedPhone);
}

bool isValidEmail(String email) {
  final trimmedEmail = email.trim();
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(trimmedEmail);
}

bool hasMinLength(String password) {
  return password.length >= 8;
}

bool hasLowercase(String password) {
  return RegExp(r'[a-z]').hasMatch(password);
}

bool hasUppercase(String password) {
  return RegExp(r'[A-Z]').hasMatch(password);
}

bool hasNumber(String password) {
  return RegExp(r'[0-9]').hasMatch(password);
}

bool hasSpecialChar(String password) {
  return RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=]').hasMatch(password);
}

bool isStrongPassword(String password) {
  return hasMinLength(password) &&
      hasLowercase(password) &&
      hasUppercase(password) &&
      hasNumber(password) &&
      hasSpecialChar(password);
}

bool isConfirmPasswordMatched(String password, String confirmPassword) {
  return confirmPassword.isNotEmpty && password == confirmPassword;
}

bool canSubmitElderBasicInfo({
  required String fullName,
  required String phone,
  required String? gender,
  required String password,
  required String confirmPassword,
}) {
  return fullName.isNotEmpty &&
      phone.isNotEmpty &&
      isValidSaudiPhone(phone) &&
      gender != null &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      isStrongPassword(password) &&
      isConfirmPasswordMatched(password, confirmPassword);
}

bool canSubmitElderHealthInfo({
  required String age,
  String? weight,
}) {
  return age.isNotEmpty;
}

void main() {
  group('UT-01 Saudi phone validation', () {
    test('accepts valid Saudi phone number', () {
      expect(isValidSaudiPhone('0555555555'), true);
    });

    test('rejects phone number that does not start with 05', () {
      expect(isValidSaudiPhone('0155555555'), false);
    });

    test('rejects phone number with less than 10 digits', () {
      expect(isValidSaudiPhone('055555555'), false);
    });

    test('rejects phone number that contains letters', () {
      expect(isValidSaudiPhone('05555abc55'), false);
    });
  });

  group('UT-02 Caregiver email validation', () {
    test('accepts valid email', () {
      expect(isValidEmail('user@example.com'), true);
    });

    test('rejects email without @', () {
      expect(isValidEmail('userexample.com'), false);
    });

    test('rejects email without domain extension', () {
      expect(isValidEmail('user@example'), false);
    });
  });

  group('UT-03 Password strength validation', () {
    test('accepts strong password', () {
      expect(isStrongPassword('Strong@123'), true);
    });

    test('rejects short password', () {
      expect(isStrongPassword('S@1a'), false);
    });

    test('rejects password without uppercase letter', () {
      expect(isStrongPassword('strong@123'), false);
    });

    test('rejects password without lowercase letter', () {
      expect(isStrongPassword('STRONG@123'), false);
    });

    test('rejects password without number', () {
      expect(isStrongPassword('Strong@abc'), false);
    });

    test('rejects password without special character', () {
      expect(isStrongPassword('Strong123'), false);
    });
  });

  group('UT-04 Confirm password validation', () {
    test('accepts matching password and confirm password', () {
      expect(isConfirmPasswordMatched('Strong@123', 'Strong@123'), true);
    });

    test('rejects non-matching confirm password', () {
      expect(isConfirmPasswordMatched('Strong@123', 'Strong@456'), false);
    });

    test('rejects empty confirm password', () {
      expect(isConfirmPasswordMatched('Strong@123', ''), false);
    });
  });

  group('UT-05 Elder basic information submit validation', () {
    test('accepts complete valid elder basic information', () {
      expect(
        canSubmitElderBasicInfo(
          fullName: 'Khaled Ali',
          phone: '0555555555',
          gender: 'male',
          password: 'Strong@123',
          confirmPassword: 'Strong@123',
        ),
        true,
      );
    });

    test('rejects empty full name', () {
      expect(
        canSubmitElderBasicInfo(
          fullName: '',
          phone: '0555555555',
          gender: 'male',
          password: 'Strong@123',
          confirmPassword: 'Strong@123',
        ),
        false,
      );
    });

    test('rejects missing gender', () {
      expect(
        canSubmitElderBasicInfo(
          fullName: 'Khaled Ali',
          phone: '0555555555',
          gender: null,
          password: 'Strong@123',
          confirmPassword: 'Strong@123',
        ),
        false,
      );
    });

    test('rejects invalid phone number', () {
      expect(
        canSubmitElderBasicInfo(
          fullName: 'Khaled Ali',
          phone: '0155555555',
          gender: 'male',
          password: 'Strong@123',
          confirmPassword: 'Strong@123',
        ),
        false,
      );
    });

    test('rejects weak password', () {
      expect(
        canSubmitElderBasicInfo(
          fullName: 'Khaled Ali',
          phone: '0555555555',
          gender: 'male',
          password: 'weakpass',
          confirmPassword: 'weakpass',
        ),
        false,
      );
    });

    test('rejects non-matching confirm password', () {
      expect(
        canSubmitElderBasicInfo(
          fullName: 'Khaled Ali',
          phone: '0555555555',
          gender: 'male',
          password: 'Strong@123',
          confirmPassword: 'Strong@456',
        ),
        false,
      );
    });
  });

  group('UT-06 Elder health information submit validation', () {
    test('accepts health information when age exists', () {
      expect(
        canSubmitElderHealthInfo(
          age: '70',
          weight: '80',
        ),
        true,
      );
    });

    test('rejects health information when age is empty', () {
      expect(
        canSubmitElderHealthInfo(
          age: '',
          weight: '80',
        ),
        false,
      );
    });

    test('accepts health information when weight is empty because weight is optional', () {
      expect(
        canSubmitElderHealthInfo(
          age: '70',
          weight: '',
        ),
        true,
      );
    });
  });
}