import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/phone_state.dart';

/// A2: the member writes their number and receives a code by SMS.
class PhoneViewModel extends ViewModel<PhoneState> {
  PhoneViewModel({required this.requestCode}) : super(const PhoneState());

  final RequestCodeUseCase requestCode;

  void onPhoneChanged(String value) => emit(state.copyWith(phone: PhoneNumbers.clean(value), clearError: true));

  Future<CodeRequest?> sendCode() async {
    if (state.isLoading) return null;
    if (!PhoneNumbers.isValid(state.phone)) {
      emit(state.copyWith(errorMessage: 'Ingresa un celular de nueve dígitos que empiece con 9.'));
      return null;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final request = await requestCode.execute(state.phone);
      emit(state.copyWith(isLoading: false));
      return request;
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
      return null;
    }
  }
}
