import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/compliance_history/application/compliance_use_cases.dart';
import 'package:pozzo/features/compliance_history/domain/compliance.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

class HistoryGroup {
  const HistoryGroup({required this.id, required this.name, required this.isClosed});

  final String id;
  final String name;
  final bool isClosed;
}

enum HistoryRole {
  organizer('Cabeza de junta'),
  participant('Participante');

  const HistoryRole(this.label);

  final String label;
}

class HistoryState {
  const HistoryState({
    this.isResolving = true,
    this.role = HistoryRole.organizer,
    this.organizedGroups = const [],
    this.joinedGroups = const [],
    this.selectedGroupId,
    this.cycle,
    this.periods = const [],
    this.members = const [],
    this.photos = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isResolving;
  final HistoryRole role;
  final List<HistoryGroup> organizedGroups;
  final List<HistoryGroup> joinedGroups;
  final String? selectedGroupId;
  final Cycle? cycle;
  final List<Period> periods;
  final List<MemberCompliance> members;
  final Map<String, String> photos;
  final bool isLoading;
  final String? errorMessage;

  bool get hasGroups => organizedGroups.isNotEmpty || joinedGroups.isNotEmpty;

  List<HistoryGroup> get groups => groupsOf(role);

  HistoryGroup? get selectedGroup => groups.where((group) => group.id == selectedGroupId).firstOrNull;

  /// Only the organizer sees how each member pays.
  bool get showsMembers => role == HistoryRole.organizer;

  List<HistoryGroup> groupsOf(HistoryRole role) => role == HistoryRole.organizer ? organizedGroups : joinedGroups;

  HistoryState copyWith({
    bool? isResolving,
    HistoryRole? role,
    List<HistoryGroup>? organizedGroups,
    List<HistoryGroup>? joinedGroups,
    String? selectedGroupId,
    Cycle? cycle,
    bool clearCycle = false,
    List<Period>? periods,
    List<MemberCompliance>? members,
    Map<String, String>? photos,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      isResolving: isResolving ?? this.isResolving,
      role: role ?? this.role,
      organizedGroups: organizedGroups ?? this.organizedGroups,
      joinedGroups: joinedGroups ?? this.joinedGroups,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      cycle: clearCycle ? null : cycle ?? this.cycle,
      periods: periods ?? this.periods,
      members: members ?? this.members,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// H1: the contributions of every member period by period in the started groups, as organizer or
/// as participant.
class HistoryViewModel extends ViewModel<HistoryState> {
  HistoryViewModel({
    required this.getLocalGroups,
    required this.refreshMyGroups,
    required this.getCycleHistory,
    required this.getGroupCompliance,
    required this.getMemberPhotos,
  }) : super(const HistoryState()) {
    _resolve();
  }

  final GetLocalGroupsUseCase getLocalGroups;
  final RefreshMyGroupsUseCase refreshMyGroups;
  final GetCycleHistoryUseCase getCycleHistory;
  final GetGroupComplianceUseCase getGroupCompliance;
  final GetMemberPhotosUseCase getMemberPhotos;

  Future<void> _resolve() async {
    List<SavingsGroup> groups;
    try {
      groups = await refreshMyGroups.execute();
    } catch (_) {
      groups = await getLocalGroups.execute();
    }
    final started = groups.where((group) => group.isStarted).toList()
      ..sort((a, b) => (a.status == GroupStatus.closed ? 1 : 0).compareTo(b.status == GroupStatus.closed ? 1 : 0));
    HistoryGroup toHistory(SavingsGroup group) =>
        HistoryGroup(id: group.id, name: group.name, isClosed: group.status == GroupStatus.closed);
    final organized = started.where((group) => group.isOrganizer).map(toHistory).toList();
    final joined = started.where((group) => !group.isOrganizer).map(toHistory).toList();
    final role = organized.isEmpty && joined.isNotEmpty ? HistoryRole.participant : HistoryRole.organizer;
    emit(state.copyWith(isResolving: false, organizedGroups: organized, joinedGroups: joined, role: role));
    final first = state.groups.firstOrNull;
    if (first != null) await select(first.id);
  }

  Future<void> selectRole(HistoryRole role) async {
    final first = state.groupsOf(role).firstOrNull;
    if (first == null) return;
    emit(state.copyWith(role: role));
    await select(first.id);
  }

  Future<void> select(String groupId) async {
    emit(state.copyWith(selectedGroupId: groupId, clearCycle: true, periods: const [], members: const [], photos: const {}));
    await load();
  }

  Future<void> load() async {
    final groupId = state.selectedGroupId;
    if (groupId == null) return;
    final withMembers = state.showsMembers;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final (cycle, periods) = await getCycleHistory.execute(groupId);
      final members = withMembers ? await getGroupCompliance.execute(groupId) : const <MemberCompliance>[];
      final photos = await getMemberPhotos.execute(groupId);
      if (state.selectedGroupId != groupId) return;
      emit(state.copyWith(isLoading: false, cycle: cycle, periods: periods, members: members, photos: photos));
    } catch (error) {
      if (state.selectedGroupId != groupId) return;
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }
}

class MyHistoryState {
  const MyHistoryState({this.history, this.isLoading = true, this.isSharing = false, this.errorMessage});

  final MyHistory? history;
  final bool isLoading;
  final bool isSharing;
  final String? errorMessage;
}

/// H2: how the member pays in all their groups, and a link to show it to someone outside Pozzo.
class MyHistoryViewModel extends ViewModel<MyHistoryState> {
  MyHistoryViewModel({required this.getMyHistory, required this.shareMyHistory}) : super(const MyHistoryState()) {
    load();
  }

  final GetMyHistoryUseCase getMyHistory;
  final ShareMyHistoryUseCase shareMyHistory;

  Future<void> load() async {
    emit(MyHistoryState(history: state.history, isLoading: state.history == null));
    try {
      emit(MyHistoryState(history: await getMyHistory.execute(), isLoading: false));
    } catch (error) {
      emit(MyHistoryState(history: state.history, isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  /// The message with the link of the history, or null when it failed.
  Future<String?> share() async {
    if (state.isSharing) return null;
    emit(MyHistoryState(history: state.history, isLoading: false, isSharing: true));
    try {
      final link = await shareMyHistory.execute();
      emit(MyHistoryState(history: state.history, isLoading: false));
      return 'Mi historial de cumplimiento en Pozzo: ${link.url}';
    } catch (error) {
      emit(MyHistoryState(history: state.history, isLoading: false, errorMessage: userMessageOf(error)));
      return null;
    }
  }
}
