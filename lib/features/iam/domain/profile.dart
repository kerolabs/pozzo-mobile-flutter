/// The member signed in: the name the group sees, the phone, the visual theme and the contact data only
/// the member sees, the Yape or Plin number (nine digits) and a backup email.
class Profile {
  const Profile({
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

  String get firstName => displayName.trim().split(' ').first;

  /// A copy with some fields changed. The nullable ones are cleared with `clearWallet` and `clearEmail`.
  Profile copyWith({
    String? displayName,
    String? theme,
    String? walletNumber,
    String? backupEmail,
    bool clearWallet = false,
    bool clearEmail = false,
  }) {
    return Profile(
      accountId: accountId,
      phoneNumber: phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl,
      theme: theme ?? this.theme,
      walletNumber: clearWallet ? null : walletNumber ?? this.walletNumber,
      backupEmail: clearEmail ? null : backupEmail ?? this.backupEmail,
    );
  }
}

/// I2: how the app looks; system follows the phone.
enum ThemePreference {
  system('SYSTEM', 'Usar el del sistema'),
  light('LIGHT', 'Claro'),
  dark('DARK', 'Oscuro');

  const ThemePreference(this.code, this.label);

  /// The value the backend keeps.
  final String code;
  final String label;

  static ThemePreference of(String? value) =>
      ThemePreference.values.firstWhere((theme) => theme.code == value, orElse: () => ThemePreference.system);
}

/// A code sent by SMS: until when it is valid and from when another one can be requested.
class CodeRequest {
  const CodeRequest({required this.phoneNumber, required this.expiresAt, required this.resendAvailableAt});

  final String phoneNumber;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
}

/// A recovery code was requested for a backup email; it only arrives if an account has that email.
class RecoveryCodeRequest {
  const RecoveryCodeRequest({required this.email, required this.expiresAt, required this.resendAvailableAt});

  final String email;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
}

/// What happens after a correct code: a registered number opens a session; a new one must complete
/// the registration with the token it received.
sealed class Verification {
  const Verification();
}

class SignedIn extends Verification {
  const SignedIn(this.profile);

  final Profile profile;
}

class RegistrationRequired extends Verification {
  const RegistrationRequired({required this.phoneNumber, required this.registrationToken});

  final String phoneNumber;
  final String registrationToken;
}

/// A Peruvian mobile number: nine digits starting with 9.
class PhoneNumbers {
  const PhoneNumbers._();

  static bool isValid(String digits) => RegExp(r'^9\d{8}$').hasMatch(digits);

  /// Keeps only the digits, at most nine; a pasted "+51" prefix is dropped.
  static String clean(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9 && digits.startsWith('51')) digits = digits.substring(2);
    return digits.length > 9 ? digits.substring(0, 9) : digits;
  }

  /// The nine local digits of a number in any format: "+51999000123" as "999000123".
  static String local(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }

  /// "999000123" as "999 000 123".
  static String grouped(String digits) {
    final parts = <String>[];
    for (var i = 0; i < digits.length; i += 3) {
      parts.add(digits.substring(i, i + 3 > digits.length ? digits.length : i + 3));
    }
    return parts.join(' ');
  }

  /// "+51999000123" or "999000123" as "+51 999 000 123".
  static String display(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('51') && digits.length > 9) digits = digits.substring(2);
    if (digits.length > 9) digits = digits.substring(digits.length - 9);
    return '+51 ${grouped(digits)}';
  }
}

/// True for something that looks like an email; the backend checks it again.
bool isEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
