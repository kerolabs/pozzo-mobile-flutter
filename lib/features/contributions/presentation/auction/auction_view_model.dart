import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

class AuctionState {
  const AuctionState({
    this.cycle,
    this.period,
    this.auction,
    this.bid = '',
    this.candidates = const [],
    this.photos = const {},
    this.isLoading = true,
    this.isBidding = false,
    this.isClosing = false,
    this.errorMessage,
  });

  final Cycle? cycle;
  final Period? period;
  final Auction? auction;
  final String bid;

  /// Who has not collected yet: the organizer chooses among them when nobody bid.
  final List<Turn> candidates;
  final Map<String, String> photos;
  final bool isLoading;
  final bool isBidding;
  final bool isClosing;
  final String? errorMessage;

  double? get bidValue {
    final value = double.tryParse(bid.replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  AuctionState copyWith({
    Cycle? cycle,
    Period? period,
    Auction? auction,
    String? bid,
    List<Turn>? candidates,
    Map<String, String>? photos,
    bool? isLoading,
    bool? isBidding,
    bool? isClosing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuctionState(
      cycle: cycle ?? this.cycle,
      period: period ?? this.period,
      auction: auction ?? this.auction,
      bid: bid ?? this.bid,
      candidates: candidates ?? this.candidates,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isBidding: isBidding ?? this.isBidding,
      isClosing: isClosing ?? this.isClosing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// C10: the auction of the turn of the current period. Members who have not collected bid a discount
/// on the pot; the organizer closes it.
class AuctionViewModel extends ViewModel<AuctionState> {
  AuctionViewModel({
    required this.getTurnAuction,
    required this.placeBid,
    required this.closeAuction,
    required this.getTurns,
    required this.getMemberPhotos,
    required this.groupId,
  }) : super(const AuctionState()) {
    load();
  }

  final GetTurnAuctionUseCase getTurnAuction;
  final PlaceBidUseCase placeBid;
  final CloseAuctionUseCase closeAuction;
  final GetTurnsUseCase getTurns;
  final GetMemberPhotosUseCase getMemberPhotos;
  final String groupId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.auction == null, clearError: true));
    try {
      final (cycle, period, auction) = await getTurnAuction.execute(groupId);
      emit(state.copyWith(isLoading: false, cycle: cycle, period: period, auction: auction));
      final turns = await getTurns.execute(groupId);
      emit(
        state.copyWith(
          candidates: turns.turns.where((turn) => turn.turnNumber >= cycle.currentTurn).toList(),
          photos: await getMemberPhotos.execute(groupId),
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  void onBidChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    emit(state.copyWith(bid: cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned, clearError: true));
  }

  /// Returns the message to show, or null when it failed (the error stays under the field).
  Future<String?> bid() async {
    final period = state.period;
    final amount = state.bidValue;
    if (period == null || amount == null || state.isBidding) return null;
    emit(state.copyWith(isBidding: true, clearError: true));
    try {
      final auction = await placeBid.execute(period.id, amount);
      emit(state.copyWith(isBidding: false, bid: '', auction: auction));
      return auction.myBidIsHighest ? 'Tu oferta es la mayor por ahora.' : 'Registramos tu oferta.';
    } catch (error) {
      emit(state.copyWith(isBidding: false, errorMessage: userMessageOf(error)));
      return null;
    }
  }

  /// Closes the auction; [winnerMembershipId] only when nobody bid and the organizer chooses.
  Future<bool> close(String? winnerMembershipId) async {
    final period = state.period;
    if (period == null || state.isClosing) return false;
    emit(state.copyWith(isClosing: true, clearError: true));
    try {
      final auction = await closeAuction.execute(period.id, winnerMembershipId);
      emit(state.copyWith(isClosing: false, auction: auction));
      return true;
    } catch (error) {
      emit(state.copyWith(isClosing: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}
