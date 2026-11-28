import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

class CodeState {
  const CodeState({
    required this.phone,
    this.code = '',
    this.secondsToResend = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final String phone;
  final String code;
  final int secondsToResend;
  final bool isLoading;
  final String? errorMessage;

  bool get canVerify => code.length == verificationCodeLength && !isLoading;
  bool get canResend => secondsToResend <= 0 && !isLoading;

  CodeState copyWith({
    String? code,
    int? secondsToResend,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CodeState(
      phone: phone,
      code: code ?? this.code,
      secondsToResend: secondsToResend ?? this.secondsToResend,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
