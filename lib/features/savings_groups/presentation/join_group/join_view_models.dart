import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

class JoinCodeState {
  const JoinCodeState({this.code = '', this.isLoading = false, this.errorMessage});

  final String code;
  final bool isLoading;
  final String? errorMessage;

  bool get canSearch => InvitationCodes.isComplete(code) && !isLoading;
}

/// G4: the member writes the code of an invitation and Pozzo looks for its group.
class JoinCodeViewModel extends ViewModel<JoinCodeState> {
  JoinCodeViewModel({required this.previewInvitation}) : super(const JoinCodeState());

  final PreviewInvitationUseCase previewInvitation;

  void onCodeChanged(String value) => emit(JoinCodeState(code: InvitationCodes.normalize(value)));

  /// Returns the code when a group has it, so the page shows the group; null when not.
  Future<String?> search() async {
    final code = state.code;
    if (!InvitationCodes.isComplete(code)) return null;
    emit(JoinCodeState(code: code, isLoading: true));
    try {
      await previewInvitation.execute(code);
      emit(JoinCodeState(code: code));
      return code;
    } catch (error) {
      final message = error is ApiException && error.status == 404
          ? 'No encontramos una junta con ese código. Revisa que esté bien escrito o pide uno nuevo.'
          : userMessageOf(error);
      emit(JoinCodeState(code: code, errorMessage: message));
      return null;
    }
  }
}

class JoinPreviewState {
  const JoinPreviewState({this.preview, this.isLoading = true, this.isJoining = false, this.errorMessage});

  final GroupPreview? preview;
  final bool isLoading;
  final bool isJoining;
  final String? errorMessage;

  JoinPreviewState copyWith({
    GroupPreview? preview,
    bool? isLoading,
    bool? isJoining,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JoinPreviewState(
      preview: preview ?? this.preview,
      isLoading: isLoading ?? this.isLoading,
      isJoining: isJoining ?? this.isJoining,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// G5: the group of the invitation, before joining it.
class JoinPreviewViewModel extends ViewModel<JoinPreviewState> {
  JoinPreviewViewModel({required this.previewInvitation, required this.joinGroup, required this.code})
      : super(const JoinPreviewState()) {
    load();
  }

  final PreviewInvitationUseCase previewInvitation;
  final JoinGroupUseCase joinGroup;
  final String code;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      emit(state.copyWith(isLoading: false, preview: await previewInvitation.execute(code)));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  /// True when the member joined.
  Future<bool> join() async {
    if (state.isJoining) return false;
    emit(state.copyWith(isJoining: true, clearError: true));
    try {
      await joinGroup.execute(code);
      emit(state.copyWith(isJoining: false));
      return true;
    } catch (error) {
      emit(state.copyWith(isJoining: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}
