import 'package:flutter/foundation.dart';
import 'package:pozzo/core/network/api_client.dart';
import 'package:pozzo/features/iam/infrastructure/remote/auth_dtos.dart';

/// Endpoints of Identity & Access, under `/auth` and `/members/me`.
class AuthApi {
  const AuthApi({required this.client});

  final ApiClient client;

  /// The name of this phone in the list of sessions of the account.
  static String get deviceLabel => 'Pozzo Flutter (${defaultTargetPlatform.name})';

  Future<CodeRequestedDto> requestCode(String phoneNumber) async =>
      CodeRequestedDto.fromJson(await client.post('auth/codes', body: {'phoneNumber': phoneNumber}));

  Future<VerificationDto> verifyCode(String phoneNumber, String code) async => VerificationDto.fromJson(
        await client.post(
          'auth/codes/verify',
          body: {'phoneNumber': phoneNumber, 'code': code, 'deviceLabel': deviceLabel},
        ),
      );

  Future<AuthenticatedDto> register(String registrationToken, String displayName, bool termsAccepted) async =>
      AuthenticatedDto.fromJson(
        await client.post(
          'auth/register',
          body: {
            'registrationToken': registrationToken,
            'displayName': displayName,
            'photoUrl': null,
            'termsAccepted': termsAccepted,
            'deviceLabel': deviceLabel,
          },
        ),
      );

  Future<void> signOut() => client.post('auth/sign-out');

  Future<CodeRequestedDto> requestRecoveryCode(String email) async =>
      CodeRequestedDto.fromJson(await client.post('auth/recovery/codes', body: {'email': email}));

  /// Returns the recovery token.
  Future<String> verifyRecoveryCode(String email, String code) async {
    final json = await client.post('auth/recovery/codes/verify', body: {'email': email, 'code': code});
    return json['recoveryToken'] as String;
  }

  Future<CodeRequestedDto> requestRecoveryPhoneCode(String recoveryToken, String phoneNumber) async =>
      CodeRequestedDto.fromJson(
        await client.post(
          'auth/recovery/phone-number/codes',
          body: {'recoveryToken': recoveryToken, 'phoneNumber': phoneNumber},
        ),
      );

  Future<AuthenticatedDto> recoverAccount(String recoveryToken, String phoneNumber, String code) async =>
      AuthenticatedDto.fromJson(
        await client.post(
          'auth/recovery/phone-number',
          body: {'recoveryToken': recoveryToken, 'phoneNumber': phoneNumber, 'code': code, 'deviceLabel': deviceLabel},
        ),
      );

  Future<ProfileDto> getProfile() async => ProfileDto.fromJson(await client.get('members/me/profile'));

  Future<ProfileDto> updateProfile(Map<String, dynamic> profile) async =>
      ProfileDto.fromJson(await client.put('members/me/profile', body: profile));

  Future<ProfileDto> changePhoto(Uint8List jpeg) async => ProfileDto.fromJson(
        await client.multipart('PUT', 'members/me/profile/photo', field: 'photo', bytes: jpeg, filename: 'photo.jpg'),
      );

  Future<ProfileDto> removePhoto() async => ProfileDto.fromJson(await client.delete('members/me/profile/photo'));

  Future<CodeRequestedDto> requestPhoneChangeCode(String phoneNumber) async =>
      CodeRequestedDto.fromJson(await client.post('members/me/phone-number/codes', body: {'phoneNumber': phoneNumber}));

  Future<ProfileDto> changePhoneNumber(String phoneNumber, String code) async => ProfileDto.fromJson(
        await client.put('members/me/phone-number', body: {'phoneNumber': phoneNumber, 'code': code}),
      );
}
