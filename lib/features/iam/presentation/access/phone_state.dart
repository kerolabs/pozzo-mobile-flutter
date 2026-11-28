import 'package:pozzo/features/iam/domain/profile.dart';

class PhoneState {
  const PhoneState({this.phone = '', this.isLoading = false, this.errorMessage});

  final String phone;
  final bool isLoading;
  final String? errorMessage;

  bool get canSend => PhoneNumbers.isValid(phone) && !isLoading;

  PhoneState copyWith({String? phone, bool? isLoading, String? errorMessage, bool clearError = false}) {
    return PhoneState(
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
