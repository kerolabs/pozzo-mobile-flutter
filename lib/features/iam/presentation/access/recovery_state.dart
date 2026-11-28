import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

enum RecoveryStep { email, emailCode, phone, phoneCode }

class RecoveryState {
  const RecoveryState({
    this.step = RecoveryStep.email,
    this.email = '',
    this.phone = '',
    this.code = '',
    this.recoveryToken,
    this.secondsToResend = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final RecoveryStep step;
  final String email;
  final String phone;
  final String code;
  final String? recoveryToken;
  final int secondsToResend;
  final bool isLoading;
  final String? errorMessage;

  bool get canSendEmail => isEmail(email) && !isLoading;
  bool get canSendPhone => PhoneNumbers.isValid(phone) && !isLoading;
  bool get canVerify => code.length == verificationCodeLength && !isLoading;
  bool get canResend => secondsToResend <= 0 && !isLoading;

  RecoveryState copyWith({
    RecoveryStep? step,
    String? email,
    String? phone,
    String? code,
    String? recoveryToken,
    int? secondsToResend,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecoveryState(
      step: step ?? this.step,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      code: code ?? this.code,
      recoveryToken: recoveryToken ?? this.recoveryToken,
      secondsToResend: secondsToResend ?? this.secondsToResend,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
