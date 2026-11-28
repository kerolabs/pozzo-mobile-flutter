import 'dart:typed_data';

import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/features/iam/domain/auth_repository.dart';
import 'package:pozzo/features/iam/domain/profile.dart';

class RequestCodeUseCase {
  const RequestCodeUseCase({required this.repository});

  final AuthRepository repository;

  Future<CodeRequest> execute(String phoneNumber) => repository.requestCode(phoneNumber);
}

class VerifyCodeUseCase {
  const VerifyCodeUseCase({required this.repository});

  final AuthRepository repository;

  Future<Verification> execute(String phoneNumber, String code) => repository.verifyCode(phoneNumber, code);
}

class CompleteRegistrationUseCase {
  const CompleteRegistrationUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(String registrationToken, String displayName, bool termsAccepted) =>
      repository.completeRegistration(registrationToken, displayName.trim(), termsAccepted);
}

class GetProfileUseCase {
  const GetProfileUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute() => repository.getProfile();
}

class UpdateDisplayNameUseCase {
  const UpdateDisplayNameUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(String displayName) =>
      repository.updateProfile((profile) => profile.copyWith(displayName: displayName.trim()));
}

class UpdateThemeUseCase {
  const UpdateThemeUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(ThemePreference theme) =>
      repository.updateProfile((profile) => profile.copyWith(theme: theme.code));
}

/// The Yape or Plin number: nine digits starting with 9, or empty to remove it.
class UpdateWalletNumberUseCase {
  const UpdateWalletNumberUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(String digits) {
    final number = digits.replaceAll(RegExp(r'\D'), '');
    if (number.isNotEmpty && !PhoneNumbers.isValid(number)) {
      throw const AppException('El número debe tener 9 dígitos y empezar con 9.');
    }
    return repository.updateProfile(
      (profile) => number.isEmpty ? profile.copyWith(clearWallet: true) : profile.copyWith(walletNumber: number),
    );
  }
}

/// The backup email, or empty to remove it.
class UpdateBackupEmailUseCase {
  const UpdateBackupEmailUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(String email) {
    final value = email.trim();
    if (value.isNotEmpty && !isEmail(value)) throw const AppException('Ingresa un correo válido.');
    return repository.updateProfile(
      (profile) => value.isEmpty ? profile.copyWith(clearEmail: true) : profile.copyWith(backupEmail: value),
    );
  }
}

class ChangeProfilePhotoUseCase {
  const ChangeProfilePhotoUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(Uint8List jpeg) {
    if (jpeg.isEmpty) throw const AppException('No pudimos leer esa imagen. Prueba con otra.');
    return repository.changePhoto(jpeg);
  }
}

class RemoveProfilePhotoUseCase {
  const RemoveProfilePhotoUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute() => repository.removePhoto();
}

class SignOutUseCase {
  const SignOutUseCase({required this.repository});

  final AuthRepository repository;

  Future<void> execute() => repository.signOut();
}

class RequestRecoveryCodeUseCase {
  const RequestRecoveryCodeUseCase({required this.repository});

  final AuthRepository repository;

  Future<RecoveryCodeRequest> execute(String email) => repository.requestRecoveryCode(email.trim().toLowerCase());
}

class VerifyRecoveryCodeUseCase {
  const VerifyRecoveryCodeUseCase({required this.repository});

  final AuthRepository repository;

  Future<String> execute(String email, String code) =>
      repository.verifyRecoveryCode(email.trim().toLowerCase(), code);
}

class RequestRecoveryPhoneCodeUseCase {
  const RequestRecoveryPhoneCodeUseCase({required this.repository});

  final AuthRepository repository;

  Future<CodeRequest> execute(String recoveryToken, String phoneNumber) =>
      repository.requestRecoveryPhoneCode(recoveryToken, phoneNumber);
}

class RecoverAccountUseCase {
  const RecoverAccountUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(String recoveryToken, String phoneNumber, String code) =>
      repository.recoverAccount(recoveryToken, phoneNumber, code);
}

class RequestPhoneChangeCodeUseCase {
  const RequestPhoneChangeCodeUseCase({required this.repository});

  final AuthRepository repository;

  Future<CodeRequest> execute(String phoneNumber) => repository.requestPhoneChangeCode(phoneNumber);
}

class ChangePhoneNumberUseCase {
  const ChangePhoneNumberUseCase({required this.repository});

  final AuthRepository repository;

  Future<Profile> execute(String phoneNumber, String code) => repository.changePhoneNumber(phoneNumber, code);
}
