import 'dart:typed_data';

import 'package:pozzo/features/iam/domain/profile.dart';

/// Identity and Access: access with the phone and an SMS code, the profile of the member and the
/// recovery of the account with the backup email.
abstract class AuthRepository {
  /// Sends an SMS code to the nine digits of [phoneNumber].
  Future<CodeRequest> requestCode(String phoneNumber);

  /// Checks the code: a registered number opens a session, a new one must complete the registration.
  Future<Verification> verifyCode(String phoneNumber, String code);

  Future<Profile> completeRegistration(String registrationToken, String displayName, bool termsAccepted);

  Future<Profile> getProfile();

  /// Reads the current profile, applies [change] and saves the result: the backend replaces it whole.
  Future<Profile> updateProfile(Profile Function(Profile current) change);

  /// Uploads a JPEG as the profile photo; the previous one is deleted.
  Future<Profile> changePhoto(Uint8List jpeg);

  Future<Profile> removePhoto();

  /// Closes the session on this phone, even if the backend cannot be reached.
  Future<void> signOut();

  /// Recovery, step 1: a code to the backup email. The answer is the same if no account has it.
  Future<RecoveryCodeRequest> requestRecoveryCode(String email);

  /// Recovery, step 2: returns the token that allows linking a new number.
  Future<String> verifyRecoveryCode(String email, String code);

  /// Recovery, step 3: an SMS code to the new number.
  Future<CodeRequest> requestRecoveryPhoneCode(String recoveryToken, String phoneNumber);

  /// Recovery, step 4: links the new number, closes the sessions of the lost phone and opens one here.
  Future<Profile> recoverAccount(String recoveryToken, String phoneNumber, String code);

  /// Change of number with the session open: an SMS code to the new number.
  Future<CodeRequest> requestPhoneChangeCode(String phoneNumber);

  Future<Profile> changePhoneNumber(String phoneNumber, String code);
}
