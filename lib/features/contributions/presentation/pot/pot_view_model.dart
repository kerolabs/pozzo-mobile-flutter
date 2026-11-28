import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';

class PotState {
  const PotState({
    this.cycle,
    this.period,
    this.auction,
    this.photos = const {},
    this.isLoading = true,
    this.errorMessage,
  });

  final Cycle? cycle;
  final Period? period;
  final Auction? auction;
  final Map<String, String> photos;
  final bool isLoading;
  final String? errorMessage;

  PotState copyWith({
    Cycle? cycle,
    Period? period,
    Auction? auction,
    Map<String, String>? photos,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PotState(
      cycle: cycle ?? this.cycle,
      period: period ?? this.period,
      auction: auction ?? this.auction,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// C1: the pot of the current period of a started group and how each member stands.
class PotViewModel extends ViewModel<PotState> {
  PotViewModel({
    required this.getPotState,
    required this.findAuction,
    required this.getMemberPhotos,
    required this.groupId,
  }) : super(const PotState()) {
    load();
    _loadPhotos();
  }

  final GetPotStateUseCase getPotState;
  final FindAuctionUseCase findAuction;
  final GetMemberPhotosUseCase getMemberPhotos;
  final String groupId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.period == null, clearError: true));
    try {
      final (cycle, period) = await getPotState.execute(groupId);
      emit(state.copyWith(isLoading: false, cycle: cycle, period: period));
      final auction = await findAuction.execute(period.id);
      if (auction != null) emit(state.copyWith(auction: auction));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  Future<void> _loadPhotos() async => emit(state.copyWith(photos: await getMemberPhotos.execute(groupId)));
}
