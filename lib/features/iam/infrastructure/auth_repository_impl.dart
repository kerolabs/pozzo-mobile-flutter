import 'dart:typed_data';

import 'package:pozzo/features/iam/domain/auth_repository.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/infrastructure/local/session_manager.dart';
import 'package:pozzo/features/iam/infrastructure/mappers/profile_mapper.dart';
import 'package:pozzo/features/iam/infrastructure/remote/auth_api.dart';
import 'package:pozzo/features/iam/infrastructure/remote/auth_dtos.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.api, required this.session});

  final AuthApi api;
  final SessionManager session;

  // The backend answers the phone in E.164; the app keeps the nine digits it sends back to verify.
  CodeRequest _codeRequest(String phoneNumber, CodeRequestedDto dto) =>
      CodeRequest(phoneNumber: phoneNumber, expiresAt: dto.expiresAt, resendAvailableAt: dto.resendAvailableAt);

  /// Keeps on the phone what is shown without a request: name, theme and photo.
  Future<Profile> _keep(ProfileDto dto) async {
    await session.updateProfile(dto.displayName, dto.theme, dto.photoUrl);
    return dto.toDomain();
  }

  Future<Profile> _open(AuthenticatedDto dto) async {
    await session.save(dto.token, dto.profile.displayName, dto.profile.theme);
    return _keep(dto.profile);
  }

  @override
  Future<CodeRequest> requestCode(String phoneNumber) async =>
      _codeRequest(phoneNumber, await api.requestCode(phoneNumber));

  @override
  Future<Verification> verifyCode(String phoneNumber, String code) async {
    final dto = await api.verifyCode(phoneNumber, code);
    final authenticated = dto.session;
    if (dto.registrationRequired || authenticated == null) {
      return RegistrationRequired(phoneNumber: phoneNumber, registrationToken: dto.registrationToken ?? '');
    }
    return SignedIn(await _open(authenticated));
  }

  @override
  Future<Profile> completeRegistration(String registrationToken, String displayName, bool termsAccepted) async =>
      _open(await api.register(registrationToken, displayName, termsAccepted));

  @override
  Future<Profile> getProfile() async => _keep(await api.getProfile());

  @override
  Future<Profile> updateProfile(Profile Function(Profile current) change) async {
    // The backend replaces the whole profile, so the fields that do not change are sent back as they are.
    final updated = change(await getProfile());
    return _keep(await api.updateProfile(updated.toRequest()));
  }

  @override
  Future<Profile> changePhoto(Uint8List jpeg) async => _keep(await api.changePhoto(jpeg));

  @override
  Future<Profile> removePhoto() async => _keep(await api.removePhoto());

  @override
  Future<void> signOut() async {
    try {
      await api.signOut();
    } finally {
      // The session is closed on the phone even if the backend cannot be reached.
      await session.clear();
    }
  }

  @override
  Future<RecoveryCodeRequest> requestRecoveryCode(String email) async {
    final dto = await api.requestRecoveryCode(email);
    return RecoveryCodeRequest(email: email, expiresAt: dto.expiresAt, resendAvailableAt: dto.resendAvailableAt);
  }

  @override
  Future<String> verifyRecoveryCode(String email, String code) => api.verifyRecoveryCode(email, code);

  @override
  Future<CodeRequest> requestRecoveryPhoneCode(String recoveryToken, String phoneNumber) async =>
      _codeRequest(phoneNumber, await api.requestRecoveryPhoneCode(recoveryToken, phoneNumber));

  @override
  Future<Profile> recoverAccount(String recoveryToken, String phoneNumber, String code) async =>
      _open(await api.recoverAccount(recoveryToken, phoneNumber, code));

  @override
  Future<CodeRequest> requestPhoneChangeCode(String phoneNumber) async =>
      _codeRequest(phoneNumber, await api.requestPhoneChangeCode(phoneNumber));

  @override
  Future<Profile> changePhoneNumber(String phoneNumber, String code) async =>
      _keep(await api.changePhoneNumber(phoneNumber, code));
}
