import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';

class SettleState {
  SettleState({
    this.cycle,
    this.period,
    this.photos = const {},
    this.isLoading = true,
    this.selectedMember,
    this.coveredBy,
    this.amount = '',
    DateTime? receivedOn,
    this.isSaving = false,
    this.errorMessage,
  }) : receivedOn = receivedOn ?? Formats.today();

  final Cycle? cycle;
  final Period? period;
  final Map<String, String> photos;
  final bool isLoading;

  /// The member whose contribution is settled.
  final String? selectedMember;

  /// Who covers it, in a coverage.
  final String? coveredBy;
  final String amount;
  final DateTime receivedOn;
  final bool isSaving;
  final String? errorMessage;

  double? get amountValue {
    final value = double.tryParse(amount.replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  /// What the selected member owes in this period.
  double? get owed => selectedMember == null ? null : period?.amountOwedBy(selectedMember!);

  bool get amountDiffers => owed != null && amountValue != null && (amountValue! - owed!).abs() >= 0.005;

  SettleState copyWith({
    Cycle? cycle,
    Period? period,
    Map<String, String>? photos,
    bool? isLoading,
    String? selectedMember,
    String? coveredBy,
    bool clearCoveredBy = false,
    String? amount,
    DateTime? receivedOn,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettleState(
      cycle: cycle ?? this.cycle,
      period: period ?? this.period,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      selectedMember: selectedMember ?? this.selectedMember,
      coveredBy: clearCoveredBy ? null : coveredBy ?? this.coveredBy,
      amount: amount ?? this.amount,
      receivedOn: receivedOn ?? this.receivedOn,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// C11 and C12: the organizer settles a contribution of someone else, in cash or covered by another member.
class SettleViewModel extends ViewModel<SettleState> {
  SettleViewModel({
    required this.getPotState,
    required this.registerCash,
    required this.registerCoverage,
    required this.getMemberPhotos,
    required this.groupId,
  }) : super(SettleState()) {
    _load();
  }

  final GetPotStateUseCase getPotState;
  final RegisterCashUseCase registerCash;
  final RegisterCoverageUseCase registerCoverage;
  final GetMemberPhotosUseCase getMemberPhotos;
  final String groupId;

  Future<void> _load() async {
    try {
      final (cycle, period) = await getPotState.execute(groupId);
      final only = period.unsettled.length == 1 ? period.unsettled.single : null;
      emit(
        state.copyWith(
          cycle: cycle,
          period: period,
          isLoading: false,
          selectedMember: only?.membershipId,
          amount: Formats.plainAmount(
            only == null ? period.contributionAmount : period.amountOwedBy(only.membershipId),
          ),
          coveredBy: cycle.myMembershipId,
        ),
      );
      emit(state.copyWith(photos: await getMemberPhotos.execute(groupId)));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  void onMemberSelected(String membershipId) {
    final owed = state.period?.amountOwedBy(membershipId);
    emit(
      state.copyWith(
        selectedMember: membershipId,
        clearCoveredBy: state.coveredBy == membershipId,
        amount: owed == null ? null : Formats.plainAmount(owed),
        clearError: true,
      ),
    );
  }

  void onCoveredBySelected(String membershipId) => emit(state.copyWith(coveredBy: membershipId, clearError: true));

  void onAmountChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    emit(state.copyWith(amount: cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned));
  }

  void onReceivedOnChanged(DateTime value) => emit(state.copyWith(receivedOn: value));

  Future<bool> registerCashContribution() => _save((period) {
        final member = state.selectedMember;
        final amount = state.amountValue;
        if (member == null) throw const AppException('Elige a quién recibiste el aporte.');
        if (amount == null) throw const AppException('Ingresa el monto recibido.');
        return registerCash.execute(period.id, member, amount, state.receivedOn);
      });

  Future<bool> registerCoverageContribution() => _save((period) {
        final member = state.selectedMember;
        final coveredBy = state.coveredBy;
        if (member == null) throw const AppException('Elige el aporte que se cubre.');
        if (coveredBy == null) throw const AppException('Elige quién lo cubre.');
        return registerCoverage.execute(period.id, member, coveredBy);
      });

  Future<bool> _save(Future<Contribution> Function(Period period) block) async {
    final period = state.period;
    if (period == null || state.isSaving) return false;
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await block(period);
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}

class DeliverState {
  const DeliverState({this.cycle, this.period, this.isLoading = true, this.isSaving = false, this.errorMessage, this.delivery});

  final Cycle? cycle;
  final Period? period;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final PotDelivery? delivery;
}

/// C13: the organizer marks the pot as delivered after transferring it.
class DeliverViewModel extends ViewModel<DeliverState> {
  DeliverViewModel({
    required this.getPotState,
    required this.deliverPot,
    required this.getCycleHistory,
    required this.groupId,
  }) : super(const DeliverState()) {
    _load();
  }

  final GetPotStateUseCase getPotState;
  final DeliverPotUseCase deliverPot;
  final GetCycleHistoryUseCase getCycleHistory;
  final String groupId;

  Future<void> _load() async {
    try {
      final (cycle, period) = await getPotState.execute(groupId);
      emit(DeliverState(cycle: cycle, period: period, isLoading: false));
    } catch (error) {
      emit(DeliverState(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  Future<void> deliver() async {
    final period = state.period;
    if (period == null || state.isSaving) return;
    emit(DeliverState(cycle: state.cycle, period: period, isLoading: false, isSaving: true));
    try {
      final delivery = await deliverPot.execute(period.id);
      emit(DeliverState(cycle: state.cycle, period: period, isLoading: false, delivery: delivery));
    } catch (error) {
      // The answer may have been lost after the backend recorded the delivery: it is checked before failing.
      final recorded = await _recordedDelivery(period);
      emit(
        DeliverState(
          cycle: state.cycle,
          period: period,
          isLoading: false,
          delivery: recorded,
          errorMessage: recorded != null
              ? null
              : 'No se registró la entrega: ${userMessageOf(error)} El pozo sigue pendiente de entrega; puedes '
                  'intentarlo de nuevo.',
        ),
      );
    }
  }

  Future<PotDelivery?> _recordedDelivery(Period period) async {
    try {
      final (cycle, periods) = await getCycleHistory.execute(groupId);
      final delivered =
          periods.where((item) => item.id == period.id && item.state == PeriodState.delivered).firstOrNull;
      if (delivered == null) return null;
      return PotDelivery(
        deliveredPeriodId: delivered.id,
        deliveredTurn: delivered.turnNumber,
        deliveredAmount: delivered.payoutAmount,
        cycleClosed: !cycle.isActive,
        nextTurn: cycle.isActive ? cycle.currentTurn : null,
      );
    } catch (_) {
      return null;
    }
  }
}
