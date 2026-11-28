import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

/// G8: the method to assign the turns. The auction needs the paid plan.
class AssignTurnsState {
  const AssignTurnsState({this.method = TurnMethod.draw, this.plan, this.isActivating = false, this.errorMessage});

  final TurnMethod method;
  final GroupPlan? plan;
  final bool isActivating;
  final String? errorMessage;

  bool get auctionLocked => plan == GroupPlan.free;
}

class AssignTurnsViewModel extends ViewModel<AssignTurnsState> {
  AssignTurnsViewModel({required this.getLocalGroups, required this.activatePaidPlan, required this.groupId})
      : super(const AssignTurnsState()) {
    _loadPlan();
  }

  final GetLocalGroupsUseCase getLocalGroups;
  final ActivatePaidPlanUseCase activatePaidPlan;
  final String groupId;

  Future<void> _loadPlan() async {
    final groups = await getLocalGroups.execute();
    final plan = groups.where((group) => group.id == groupId).firstOrNull?.plan;
    emit(AssignTurnsState(method: state.method, plan: plan));
  }

  void choose(TurnMethod method) => emit(AssignTurnsState(method: method, plan: state.plan));

  /// True when the paid plan is active.
  Future<bool> activate() async {
    if (state.isActivating) return false;
    emit(AssignTurnsState(method: state.method, plan: state.plan, isActivating: true));
    try {
      final group = await activatePaidPlan.execute(groupId);
      emit(AssignTurnsState(method: state.method, plan: group.plan));
      return true;
    } catch (error) {
      emit(AssignTurnsState(method: state.method, plan: state.plan, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}

class DrawState {
  const DrawState({this.calendar, this.isDrawing = true, this.errorMessage});

  final TurnCalendar? calendar;
  final bool isDrawing;
  final String? errorMessage;
}

/// G9: draws the turns as soon as it opens; the organizer can draw again before confirming.
class DrawResultViewModel extends ViewModel<DrawState> {
  DrawResultViewModel({required this.drawTurns, required this.groupId}) : super(const DrawState()) {
    draw();
  }

  final DrawTurnsUseCase drawTurns;
  final String groupId;

  Future<void> draw() async {
    emit(DrawState(calendar: state.calendar));
    try {
      emit(DrawState(calendar: await drawTurns.execute(groupId), isDrawing: false));
    } catch (error) {
      emit(DrawState(calendar: state.calendar, isDrawing: false, errorMessage: userMessageOf(error)));
    }
  }
}

class AgreedOrderState {
  const AgreedOrderState({
    this.order = const [],
    this.detail,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<Member> order;
  final GroupDetail? detail;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  AgreedOrderState copyWith({
    List<Member>? order,
    GroupDetail? detail,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AgreedOrderState(
      order: order ?? this.order,
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// G10: the organizer orders the turns as the group agreed.
class AgreedOrderViewModel extends ViewModel<AgreedOrderState> {
  AgreedOrderViewModel({required this.getGroupDetail, required this.assignAgreedTurns, required this.groupId})
      : super(const AgreedOrderState()) {
    _load();
  }

  final GetGroupDetailUseCase getGroupDetail;
  final AssignAgreedTurnsUseCase assignAgreedTurns;
  final String groupId;

  Future<void> _load() async {
    try {
      final detail = await getGroupDetail.execute(groupId);
      final order = [...detail.members]
        ..sort((a, b) => (a.turnNumber ?? 1 << 30).compareTo(b.turnNumber ?? 1 << 30));
      emit(state.copyWith(isLoading: false, detail: detail, order: order));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  /// Moves a member as ReorderableListView reports it: [newIndex] is already the final position.
  void move(int oldIndex, int newIndex) {
    final order = [...state.order];
    final member = order.removeAt(oldIndex);
    order.insert(newIndex, member);
    emit(state.copyWith(order: order));
  }

  /// True when the order was saved.
  Future<bool> confirm() async {
    if (state.order.isEmpty || state.isSaving) return false;
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await assignAgreedTurns.execute(groupId, state.order.map((member) => member.membershipId).toList());
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}

class AuctionRulesState {
  const AuctionRulesState({
    this.closesDaysBeforeCutoff = 2,
    this.minimumBid = '',
    this.fallback = AuctionFallback.draw,
    this.isSaving = false,
    this.errorMessage,
  });

  static const int maxClosingDays = 30;

  final int closesDaysBeforeCutoff;
  final String minimumBid;
  final AuctionFallback fallback;
  final bool isSaving;
  final String? errorMessage;

  double? get minimumBidValue {
    final value = double.tryParse(minimumBid.replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  AuctionRulesState copyWith({
    int? closesDaysBeforeCutoff,
    String? minimumBid,
    AuctionFallback? fallback,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuctionRulesState(
      closesDaysBeforeCutoff: closesDaysBeforeCutoff ?? this.closesDaysBeforeCutoff,
      minimumBid: minimumBid ?? this.minimumBid,
      fallback: fallback ?? this.fallback,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// G11: the rules of the auction of turns.
class AuctionRulesViewModel extends ViewModel<AuctionRulesState> {
  AuctionRulesViewModel({required this.assignTurnsByAuction, required this.groupId})
      : super(const AuctionRulesState());

  final AssignTurnsByAuctionUseCase assignTurnsByAuction;
  final String groupId;

  void onClosingDaysChanged(int value) => emit(
        state.copyWith(closesDaysBeforeCutoff: value.clamp(0, AuctionRulesState.maxClosingDays), clearError: true),
      );

  void onMinimumBidChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    emit(state.copyWith(minimumBid: cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned, clearError: true));
  }

  void onFallbackChanged(AuctionFallback value) => emit(state.copyWith(fallback: value));

  /// True when the auction was set.
  Future<bool> save() async {
    final minimumBid = state.minimumBidValue;
    if (minimumBid == null || state.isSaving) return false;
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await assignTurnsByAuction.execute(
        groupId,
        AuctionRules(
          closesDaysBeforeCutoff: state.closesDaysBeforeCutoff,
          minimumBid: minimumBid,
          fallback: state.fallback,
        ),
      );
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}

class StartGroupState {
  const StartGroupState({this.detail, this.isLoading = true, this.isStarting = false, this.errorMessage});

  final GroupDetail? detail;
  final bool isLoading;
  final bool isStarting;
  final String? errorMessage;
}

/// G12: the last check before starting the group.
class StartGroupViewModel extends ViewModel<StartGroupState> {
  StartGroupViewModel({required this.getGroupDetail, required this.startGroup, required this.groupId})
      : super(const StartGroupState()) {
    _load();
  }

  final GetGroupDetailUseCase getGroupDetail;
  final StartGroupUseCase startGroup;
  final String groupId;

  Future<void> _load() async {
    try {
      emit(StartGroupState(detail: await getGroupDetail.execute(groupId), isLoading: false));
    } catch (error) {
      emit(StartGroupState(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  /// True when the group started.
  Future<bool> start() async {
    if (state.isStarting) return false;
    emit(StartGroupState(detail: state.detail, isLoading: false, isStarting: true));
    try {
      await startGroup.execute(groupId);
      emit(StartGroupState(detail: state.detail, isLoading: false));
      return true;
    } catch (error) {
      emit(StartGroupState(detail: state.detail, isLoading: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}
