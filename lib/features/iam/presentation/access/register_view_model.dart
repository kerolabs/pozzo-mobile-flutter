import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/register_state.dart';

/// A4: a new number completes the profile with the name the group will see.
class RegisterViewModel extends ViewModel<RegisterState> {
  RegisterViewModel({required this.completeRegistration, required this.registration}) : super(const RegisterState());

  final CompleteRegistrationUseCase completeRegistration;
  final RegistrationRequired registration;

  void onNameChanged(String value) =>
      emit(state.copyWith(displayName: value.length > 80 ? value.substring(0, 80) : value, clearError: true));

  void onTermsChanged(bool accepted) => emit(state.copyWith(termsAccepted: accepted));

  /// Opening the session is enough: the root of the app takes the member to their groups.
  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await completeRegistration.execute(registration.registrationToken, state.displayName, state.termsAccepted);
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }
}
