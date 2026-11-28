class RegisterState {
  const RegisterState({this.displayName = '', this.termsAccepted = false, this.isLoading = false, this.errorMessage});

  final String displayName;
  final bool termsAccepted;
  final bool isLoading;
  final String? errorMessage;

  bool get canSubmit => displayName.trim().isNotEmpty && termsAccepted && !isLoading;

  RegisterState copyWith({
    String? displayName,
    bool? termsAccepted,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterState(
      displayName: displayName ?? this.displayName,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
