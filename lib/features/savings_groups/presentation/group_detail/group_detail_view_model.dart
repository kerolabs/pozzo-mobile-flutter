import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_state.dart';

/// G7: the detail of a group: what is missing to start it, its members and turns, and its rules.
/// The actions return the message to show, so the page only shows it.
class GroupDetailViewModel extends ViewModel<GroupDetailState> {
  GroupDetailViewModel({
    required this.getGroupDetail,
    required this.addManualMember,
    required this.removeMember,
    required this.registerDropout,
    required this.replaceMember,
    required this.getInvitation,
    required this.deleteGroup,
    required this.openNewCycle,
    required this.groupId,
  }) : super(const GroupDetailState()) {
    load();
  }

  final GetGroupDetailUseCase getGroupDetail;
  final AddManualMemberUseCase addManualMember;
  final RemoveMemberUseCase removeMember;
  final RegisterDropoutUseCase registerDropout;
  final ReplaceMemberUseCase replaceMember;
  final GetInvitationUseCase getInvitation;
  final DeleteGroupUseCase deleteGroup;
  final OpenNewCycleUseCase openNewCycle;
  final String groupId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.detail == null, clearError: true));
    try {
      emit(state.copyWith(isLoading: false, detail: await getGroupDetail.execute(groupId)));
    } on ApiException catch (error) {
      if (error.status == 404) {
        emit(state.copyWith(isLoading: false, closed: true));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: error.userMessage));
      }
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  void selectTab(GroupDetailTab tab) => emit(state.copyWith(tab: tab));

  /// Adds someone who will not use the app; null when it worked, or the error to show in the form.
  Future<String?> addMember(String name, String phone) async {
    try {
      await addManualMember.execute(groupId, name, phone);
      await load();
      return null;
    } catch (error) {
      return userMessageOf(error);
    }
  }

  /// Hides the member while the organizer can undo; [confirmRemove] removes them.
  void hide(Member member) => emit(state.copyWith(hiddenMember: member.membershipId));

  void undoRemove() => emit(state.copyWith(clearHidden: true));

  Future<String?> confirmRemove(Member member) async {
    try {
      await removeMember.execute(groupId, member.membershipId);
      emit(state.copyWith(clearHidden: true));
      await load();
      return null;
    } catch (error) {
      emit(state.copyWith(clearHidden: true));
      return userMessageOf(error);
    }
  }

  Future<String> dropout(Member member) async {
    emit(state.copyWith(isBusy: true));
    try {
      await registerDropout.execute(groupId, member.membershipId);
      emit(state.copyWith(isBusy: false, tab: GroupDetailTab.members));
      await load();
      return '${member.displayName} dejó la junta. Asigna a alguien en su turno.';
    } catch (error) {
      emit(state.copyWith(isBusy: false));
      return userMessageOf(error);
    }
  }

  /// Puts someone in the turn of a member who left; null when it worked, or the error for the form.
  Future<String?> replace(Turn turn, String name, String phone) async {
    try {
      await replaceMember.execute(groupId, turn.membershipId, name, phone);
      await load();
      return null;
    } catch (error) {
      return userMessageOf(error);
    }
  }

  Future<Invitation> invitation() => getInvitation.execute(groupId);

  /// True when the group was deleted.
  Future<bool> delete() async {
    emit(state.copyWith(isBusy: true));
    try {
      await deleteGroup.execute(groupId);
      emit(state.copyWith(isBusy: false, closed: true));
      return true;
    } catch (error) {
      emit(state.copyWith(isBusy: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }

  /// Opens a new cycle with the same rules and members; returns the new group.
  Future<SavingsGroup> newCycle(DateTime firstContributionDate) async {
    emit(state.copyWith(isBusy: true));
    try {
      return await openNewCycle.execute(groupId, firstContributionDate);
    } finally {
      emit(state.copyWith(isBusy: false));
    }
  }
}
