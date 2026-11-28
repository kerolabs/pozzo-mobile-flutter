import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/code_state.dart';
import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

/// A3: the member writes the six digits received by SMS.
class CodeViewModel extends ViewModel<CodeState> {
  CodeViewModel({required this.verifyCode, required this.requestCode, required CodeRequest request})
      : super(CodeState(phone: request.phoneNumber)) {
    _countdown = ResendCountdown((seconds) => emit(state.copyWith(secondsToResend: seconds)));
    _countdown.start(request.resendAvailableAt);
  }

  final VerifyCodeUseCase verifyCode;
  final RequestCodeUseCase requestCode;
  late final ResendCountdown _countdown;

  /// Called by the page with the result of a complete code.
  void Function(Verification verification)? onVerified;

  void onCodeChanged(String value) {
    emit(state.copyWith(code: value, clearError: true));
    if (value.length == verificationCodeLength) verify();
  }

  Future<void> verify() async {
    if (!state.canVerify) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await verifyCode.execute(state.phone, state.code);
      emit(state.copyWith(isLoading: false));
      onVerified?.call(result);
    } catch (error) {
      emit(state.copyWith(isLoading: false, code: '', errorMessage: userMessageOf(error)));
    }
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    emit(state.copyWith(isLoading: true, code: '', clearError: true));
    try {
      final request = await requestCode.execute(state.phone);
      emit(state.copyWith(isLoading: false));
      _countdown.start(request.resendAvailableAt);
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }
}
