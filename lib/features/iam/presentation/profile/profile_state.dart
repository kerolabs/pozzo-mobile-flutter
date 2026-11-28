import 'package:pozzo/features/iam/domain/profile.dart';

class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = true,
    this.isSaving = false,
    this.isUploadingPhoto = false,
    this.errorMessage,
  });

  final Profile? profile;
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingPhoto;
  final String? errorMessage;

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingPhoto,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
