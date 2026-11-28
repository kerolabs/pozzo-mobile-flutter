import 'dart:typed_data';

import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/profile/profile_state.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';

/// I1: the profile of the member, the data only they see and the end of the session.
class ProfileViewModel extends ViewModel<ProfileState> {
  ProfileViewModel({
    required this.getProfile,
    required this.updateDisplayName,
    required this.updateWalletNumber,
    required this.updateBackupEmail,
    required this.changeProfilePhoto,
    required this.removeProfilePhoto,
    required this.signOut,
    required this.clearLocalGroups,
    required this.clearLocalContributions,
  }) : super(const ProfileState());

  final GetProfileUseCase getProfile;
  final UpdateDisplayNameUseCase updateDisplayName;
  final UpdateWalletNumberUseCase updateWalletNumber;
  final UpdateBackupEmailUseCase updateBackupEmail;
  final ChangeProfilePhotoUseCase changeProfilePhoto;
  final RemoveProfilePhotoUseCase removeProfilePhoto;
  final SignOutUseCase signOut;
  final ClearLocalGroupsUseCase clearLocalGroups;
  final ClearLocalContributionsUseCase clearLocalContributions;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.profile == null, clearError: true));
    try {
      emit(state.copyWith(profile: await getProfile.execute(), isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  Future<void> rename(String displayName) async {
    if (displayName.trim().isEmpty) return;
    await _save(() => updateDisplayName.execute(displayName));
  }

  Future<void> saveWalletNumber(String digits) => _save(() => updateWalletNumber.execute(digits));

  Future<void> saveBackupEmail(String email) => _save(() => updateBackupEmail.execute(email));

  Future<void> changePhoto(Uint8List jpeg) => _savePhoto(() => changeProfilePhoto.execute(jpeg));

  Future<void> removePhoto() => _savePhoto(removeProfilePhoto.execute);

  Future<void> _save(Future<Profile> Function() update) async {
    if (state.profile == null || state.isSaving) return;
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      emit(state.copyWith(profile: await update(), isSaving: false));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: userMessageOf(error)));
    }
  }

  Future<void> _savePhoto(Future<Profile> Function() update) async {
    if (state.isUploadingPhoto) return;
    emit(state.copyWith(isUploadingPhoto: true, clearError: true));
    try {
      emit(state.copyWith(profile: await update(), isUploadingPhoto: false));
    } catch (error) {
      emit(state.copyWith(isUploadingPhoto: false, errorMessage: userMessageOf(error)));
    }
  }

  /// Clears what this phone keeps of the account; the root of the app goes back to the welcome.
  Future<void> closeSession() async {
    await clearLocalGroups.execute();
    await clearLocalContributions.execute();
    try {
      await signOut.execute();
    } on AppException {
      // The session is already closed on the phone even if the backend could not be reached.
    }
  }
}
