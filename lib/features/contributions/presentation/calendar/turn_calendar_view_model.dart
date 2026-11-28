import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

class TurnCalendarState {
  const TurnCalendarState({
    this.cycle,
    this.calendar,
    this.winners = const {},
    this.isLoading = true,
    this.errorMessage,
  });

  final Cycle? cycle;
  final TurnCalendar? calendar;

  /// Who collected each turn already decided, in the groups that auction their turns.
  final Map<int, String> winners;
  final bool isLoading;
  final String? errorMessage;
}

/// C4: the turns of the cycle: who already collected, who collects now and who is next.
class TurnCalendarViewModel extends ViewModel<TurnCalendarState> {
  TurnCalendarViewModel({
    required this.getCycleHistory,
    required this.getTurns,
    required this.findAuction,
    required this.groupId,
  }) : super(const TurnCalendarState()) {
    load();
  }

  final GetCycleHistoryUseCase getCycleHistory;
  final GetTurnsUseCase getTurns;
  final FindAuctionUseCase findAuction;
  final String groupId;

  Future<void> load() async {
    emit(TurnCalendarState(cycle: state.cycle, calendar: state.calendar, winners: state.winners, isLoading: state.calendar == null));
    try {
      final (cycle, periods) = await getCycleHistory.execute(groupId);
      final calendar = await getTurns.execute(groupId);
      final current = periods.where((period) => period.turnNumber == cycle.currentTurn).firstOrNull;
      final currentDecided = current == null || (await findAuction.execute(current.id))?.isOpen != true;
      final winners = {
        for (final period in periods)
          if (period.turnNumber < cycle.currentTurn || !cycle.isActive || currentDecided)
            period.turnNumber: period.payoutMemberName,
      };
      emit(TurnCalendarState(cycle: cycle, calendar: calendar, winners: winners, isLoading: false));
    } catch (error) {
      emit(
        TurnCalendarState(
          cycle: state.cycle,
          calendar: state.calendar,
          winners: state.winners,
          isLoading: false,
          errorMessage: userMessageOf(error),
        ),
      );
    }
  }
}
