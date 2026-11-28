import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/recovery_state.dart';
import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

/// A5: recovers the account with the backup email and links a new number, in four steps.
class RecoveryViewModel extends ViewModel<RecoveryState> {
  RecoveryViewModel({
    required this.requestRecoveryCode,
    required this.verifyRecoveryCode,
    required this.requestRecoveryPhoneCode,
    required this.recoverAccount,
  }) : super(const RecoveryState()) {
    _countdown = ResendCountdown((seconds) => emit(state.copyWith(secondsToResend: seconds)));
  }

  final RequestRecoveryCodeUseCase requestRecoveryCode;
  final VerifyRecoveryCodeUseCase verifyRecoveryCode;
  final RequestRecoveryPhoneCodeUseCase requestRecoveryPhoneCode;
  final RecoverAccountUseCase recoverAccount;
  late final ResendCountdown _countdown;

  void onEmailChanged(String value) {
    final email = value.trim();
    emit(state.copyWith(email: email.length > 120 ? email.substring(0, 120) : email, clearError: true));
  }

  void onPhoneChanged(String value) => emit(state.copyWith(phone: PhoneNumbers.clean(value), clearError: true));

  void onCodeChanged(String value) {
    emit(state.copyWith(code: value, clearError: true));
    if (value.length == verificationCodeLength) verify();
  }

  Future<void> sendEmailCode() async {
    if (!state.canSendEmail) return;
    await _step(() async {
      final request = await requestRecoveryCode.execute(state.email);
      _countdown.start(request.resendAvailableAt);
      emit(state.copyWith(step: RecoveryStep.emailCode, code: ''));
    });
  }

  Future<void> sendPhoneCode() async {
    final token = state.recoveryToken;
    if (token == null) return;
    if (!state.canSendPhone) {
      emit(state.copyWith(errorMessage: 'Ingresa un celular de nueve dígitos que empiece con 9.'));
      return;
    }
    await _step(() async {
      final request = await requestRecoveryPhoneCode.execute(token, state.phone);
      _countdown.start(request.resendAvailableAt);
      emit(state.copyWith(step: RecoveryStep.phoneCode, code: ''));
    });
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    if (state.step == RecoveryStep.emailCode) await sendEmailCode();
    if (state.step == RecoveryStep.phoneCode) await sendPhoneCode();
  }

  Future<void> verify() async {
    if (!state.canVerify) return;
    switch (state.step) {
      case RecoveryStep.emailCode:
        await _step(clearCodeOnError: true, () async {
          final token = await verifyRecoveryCode.execute(state.email, state.code);
          _countdown.cancel();
          emit(state.copyWith(step: RecoveryStep.phone, recoveryToken: token, code: '', secondsToResend: 0));
        });
      case RecoveryStep.phoneCode:
        // Opening the session is enough: the root of the app takes the member to their groups.
        await _step(clearCodeOnError: true, () async {
          await recoverAccount.execute(state.recoveryToken ?? '', state.phone, state.code);
        });
      case RecoveryStep.email:
      case RecoveryStep.phone:
        break;
    }
  }

  /// Goes back one step; false when the page itself must close.
  bool back() {
    final RecoveryStep previous;
    switch (state.step) {
      case RecoveryStep.email:
        return false;
      case RecoveryStep.emailCode:
        previous = RecoveryStep.email;
      case RecoveryStep.phone:
        // The email was already proved: going back only changes the new number.
        return false;
      case RecoveryStep.phoneCode:
        previous = RecoveryStep.phone;
    }
    emit(state.copyWith(step: previous, code: '', clearError: true));
    return true;
  }

  Future<void> _step(Future<void> Function() block, {bool clearCodeOnError = false}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await block();
      emit(state.copyWith(isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error), code: clearCodeOnError ? '' : null));
    }
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }
}
