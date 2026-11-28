import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

class MyGroupsState {
  const MyGroupsState({
    this.groups = const [],
    this.isRefreshing = true,
    this.loadedOnce = false,
    this.errorMessage,
  });

  final List<SavingsGroup> groups;
  final bool isRefreshing;
  final bool loadedOnce;
  final String? errorMessage;

  bool get showEmptyState => loadedOnce && groups.isEmpty;

  bool get waitingToStart =>
      groups.any((group) => group.status == GroupStatus.draft || group.status == GroupStatus.ready);

  MyGroupsState copyWith({
    List<SavingsGroup>? groups,
    bool? isRefreshing,
    bool? loadedOnce,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyGroupsState(
      groups: groups ?? this.groups,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
