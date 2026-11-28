import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/presentation/my_groups/my_groups_state.dart';

/// G1: the groups of the member. The ones kept on the phone show at once; then the backend updates them.
class MyGroupsViewModel extends ViewModel<MyGroupsState> {
  MyGroupsViewModel({required this.getLocalGroups, required this.refreshMyGroups}) : super(const MyGroupsState()) {
    _start();
  }

  final GetLocalGroupsUseCase getLocalGroups;
  final RefreshMyGroupsUseCase refreshMyGroups;

  Future<void> _start() async {
    final local = await getLocalGroups.execute();
    emit(state.copyWith(groups: local, loadedOnce: local.isNotEmpty));
    await refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      final groups = await refreshMyGroups.execute();
      emit(state.copyWith(groups: groups, isRefreshing: false, loadedOnce: true));
    } catch (error) {
      emit(state.copyWith(isRefreshing: false, errorMessage: userMessageOf(error)));
    }
  }

  /// Updates the list without a spinner or an error, as when the member comes back to it.
  Future<void> refreshQuietly() async {
    try {
      final groups = await refreshMyGroups.execute();
      emit(state.copyWith(groups: groups, loadedOnce: true));
    } catch (_) {
      final local = await getLocalGroups.execute();
      emit(state.copyWith(groups: local));
    }
  }

  void dismissError() => emit(state.copyWith(clearError: true));
}
