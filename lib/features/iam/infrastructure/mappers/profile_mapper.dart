import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/infrastructure/remote/auth_dtos.dart';

extension ProfileDtoMapper on ProfileDto {
  Profile toDomain() {
    return Profile(
      accountId: accountId,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoUrl: photoUrl,
      theme: theme,
      walletNumber: walletNumber,
      backupEmail: backupEmail,
    );
  }
}

extension ProfileMapper on Profile {
  /// The body of `PUT members/me/profile`: the backend replaces the whole profile.
  Map<String, dynamic> toRequest() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'theme': theme,
      'walletNumber': (walletNumber ?? '').trim().isEmpty ? null : walletNumber,
      'backupEmail': (backupEmail ?? '').trim().isEmpty ? null : backupEmail,
    };
  }
}
