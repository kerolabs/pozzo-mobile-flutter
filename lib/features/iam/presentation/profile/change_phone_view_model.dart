import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

class ChangePhoneState {
  const ChangePhoneState({
    this.phone = '',
    this.code = '',
    this.codeSent = false,
    this.secondsToResend = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final String phone;
  final String code;
  final bool codeSent;
  final int secondsToResend;
  final bool isLoading;
  final String? errorMessage;

  bool get canSend => PhoneNumbers.isValid(phone) && !isLoading;
  bool get canVerify => code.length == verificationCodeLength && !isLoading;
  bool get canResend => secondsToResend <= 0 && !isLoading;

  ChangePhoneState copyWith({
    String? phone,
    String? code,
    bool? codeSent,
    int? secondsToResend,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePhoneState(
      phone: phone ?? this.phone,
      code: code ?? this.code,
      codeSent: codeSent ?? this.codeSent,
      secondsToResend: secondsToResend ?? this.secondsToResend,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// I3: changes the number of the account with an SMS code to the new one.
class ChangePhoneViewModel extends ViewModel<ChangePhoneState> {
  ChangePhoneViewModel({required this.requestPhoneChangeCode, required this.changePhoneNumber})
      : super(const ChangePhoneState()) {
    _countdown = ResendCountdown((seconds) => emit(state.copyWith(secondsToResend: seconds)));
  }

  final RequestPhoneChangeCodeUseCase requestPhoneChangeCode;
  final ChangePhoneNumberUseCase changePhoneNumber;
  late final ResendCountdown _countdown;

  /// Called by the page once the number changed.
  void Function()? onChanged;

  void onPhoneChanged(String value) => emit(state.copyWith(phone: PhoneNumbers.clean(value), clearError: true));

  void onCodeChanged(String value) {
    emit(state.copyWith(code: value, clearError: true));
    if (value.length == verificationCodeLength) verify();
  }

  Future<void> sendCode() async {
    if (!state.canSend && !state.codeSent) return;
    emit(state.copyWith(isLoading: true, code: '', clearError: true));
    try {
      final request = await requestPhoneChangeCode.execute(state.phone);
      _countdown.start(request.resendAvailableAt);
      emit(state.copyWith(isLoading: false, codeSent: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  Future<void> verify() async {
    if (!state.canVerify) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await changePhoneNumber.execute(state.phone, state.code);
      emit(state.copyWith(isLoading: false));
      onChanged?.call();
    } catch (error) {
      emit(state.copyWith(isLoading: false, code: '', errorMessage: userMessageOf(error)));
    }
  }

  /// Goes back to the number; false when the page itself must close.
  bool back() {
    if (!state.codeSent) return false;
    emit(state.copyWith(codeSent: false, code: '', clearError: true));
    return true;
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }
}
