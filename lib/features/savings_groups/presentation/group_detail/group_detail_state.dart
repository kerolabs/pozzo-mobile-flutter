import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

enum GroupDetailTab {
  members('Integrantes'),
  rules('Reglas');

  const GroupDetailTab(this.label);

  final String label;
}

class GroupDetailState {
  const GroupDetailState({
    this.detail,
    this.isLoading = true,
    this.errorMessage,
    this.tab = GroupDetailTab.members,
    this.hiddenMember,
    this.closed = false,
    this.isBusy = false,
  });

  final GroupDetail? detail;
  final bool isLoading;
  final String? errorMessage;
  final GroupDetailTab tab;

  /// A member being removed: hidden while the organizer can still undo it.
  final String? hiddenMember;

  /// The group no longer exists (deleted, or the member is no longer part of it).
  final bool closed;

  /// An action is running: deleting, registering a dropout or opening a cycle.
  final bool isBusy;

  SavingsGroup? get group => detail?.group;

  bool get canEdit => group != null && group!.isOrganizer && !group!.isStarted;

  GroupDetailState copyWith({
    GroupDetail? detail,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    GroupDetailTab? tab,
    String? hiddenMember,
    bool clearHidden = false,
    bool? closed,
    bool? isBusy,
  }) {
    return GroupDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      tab: tab ?? this.tab,
      hiddenMember: clearHidden ? null : hiddenMember ?? this.hiddenMember,
      closed: closed ?? this.closed,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}
