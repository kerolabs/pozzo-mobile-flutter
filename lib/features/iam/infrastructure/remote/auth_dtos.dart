/// Shapes of the IAM endpoints as the backend sends and receives them.
class ProfileDto {
  const ProfileDto({
    required this.accountId,
    required this.phoneNumber,
    required this.displayName,
    required this.photoUrl,
    required this.theme,
    required this.walletNumber,
    required this.backupEmail,
  });

  final String accountId;
  final String phoneNumber;
  final String displayName;
  final String? photoUrl;
  final String theme;
  final String? walletNumber;
  final String? backupEmail;

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      accountId: json['accountId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      theme: json['theme'] as String? ?? 'SYSTEM',
      walletNumber: json['walletNumber'] as String?,
      backupEmail: json['backupEmail'] as String?,
    );
  }
}

/// An open session: the bearer token and the profile.
class AuthenticatedDto {
  const AuthenticatedDto({required this.token, required this.profile});

  final String token;
  final ProfileDto profile;

  factory AuthenticatedDto.fromJson(Map<String, dynamic> json) {
    return AuthenticatedDto(
      token: json['token'] as String,
      profile: ProfileDto.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }
}

/// The answer to a code: a session, or the token to complete the registration.
class VerificationDto {
  const VerificationDto({required this.registrationRequired, required this.session, required this.registrationToken});

  final bool registrationRequired;
  final AuthenticatedDto? session;
  final String? registrationToken;

  factory VerificationDto.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>?;
    return VerificationDto(
      registrationRequired: json['registrationRequired'] as bool? ?? false,
      session: session == null ? null : AuthenticatedDto.fromJson(session),
      registrationToken: json['registrationToken'] as String?,
    );
  }
}

/// A code sent by SMS or email: until when it is valid and when another one can be requested.
class CodeRequestedDto {
  const CodeRequestedDto({required this.expiresAt, required this.resendAvailableAt});

  final DateTime expiresAt;
  final DateTime resendAvailableAt;

  factory CodeRequestedDto.fromJson(Map<String, dynamic> json) {
    return CodeRequestedDto(
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      resendAvailableAt: DateTime.parse(json['resendAvailableAt'] as String),
    );
  }
}
