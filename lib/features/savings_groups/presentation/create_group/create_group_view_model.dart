import 'dart:math';

import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/create_group/create_group_state.dart';

/// G2: creates a group in three steps (rules, dates and destination, summary), or edits the rules of
/// one that has not started when it receives its id.
class CreateGroupViewModel extends ViewModel<CreateGroupState> {
  CreateGroupViewModel({
    required this.createGroup,
    required this.updateGroup,
    required this.getGroupDetail,
    required this.getProfile,
    required this.getLocalGroups,
    required this.activatePaidPlan,
    String? editingGroupId,
  }) : super(CreateGroupState(editingGroupId: editingGroupId, isPreparing: editingGroupId != null)) {
    if (editingGroupId != null) {
      _loadGroup(editingGroupId);
    } else {
      _offerWalletNumber();
      _checkFreePlan();
    }
  }

  final CreateGroupUseCase createGroup;
  final UpdateGroupUseCase updateGroup;
  final GetGroupDetailUseCase getGroupDetail;
  final GetProfileUseCase getProfile;
  final GetLocalGroupsUseCase getLocalGroups;
  final ActivatePaidPlanUseCase activatePaidPlan;

  Future<void> _checkFreePlan() async {
    final groups = await getLocalGroups.execute();
    emit(state.copyWith(freePlanInUse: groups.any((group) => group.usesFreePlanSlot)));
  }

  /// The destination starts with the Yape or Plin number of the profile, or the phone of the account.
  Future<void> _offerWalletNumber() async {
    try {
      final profile = await getProfile.execute();
      final number = profile.walletNumber ?? PhoneNumbers.local(profile.phoneNumber);
      if (state.destinationPhone.isEmpty) emit(state.copyWith(destinationPhone: number));
    } catch (_) {
      // Without the profile the organizer writes the number.
    }
  }

  Future<void> _loadGroup(String groupId) async {
    try {
      final detail = await getGroupDetail.execute(groupId);
      final group = detail.group;
      emit(
        state.copyWith(
          isPreparing: false,
          name: group.name,
          amount: Formats.plainAmount(group.contributionAmount),
          periodicity: group.periodicity,
          seats: group.seats,
          firstContributionDate: group.firstContributionDate,
          paymentMethod: group.destination?.method,
          destinationPhone: group.destination?.phoneNumber ?? '',
          minSeats: max(NewGroup.minSeats, detail.members.length),
          originalSeats: group.seats,
          turnsAssigned: group.readiness.turnsAssigned,
          groupPlan: group.plan,
          plan: group.plan,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isPreparing: false, errorMessage: userMessageOf(error)));
    }
  }

  void onNameChanged(String value) => emit(
        state.copyWith(name: value.length > NewGroup.nameMaxLength ? value.substring(0, NewGroup.nameMaxLength) : value),
      );

  void onAmountChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    emit(state.copyWith(amount: cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned));
  }

  void onPeriodicityChanged(Periodicity value) => emit(state.copyWith(periodicity: value));

  void onPlanChanged(GroupPlan value) => emit(state.copyWith(plan: value));

  void onSeatsChanged(int value) => emit(state.copyWith(seats: value.clamp(state.minSeats, NewGroup.maxSeats)));

  void onFirstContributionDateChanged(DateTime value) => emit(state.copyWith(firstContributionDate: value));

  void onPaymentMethodChanged(PaymentMethod value) => emit(state.copyWith(paymentMethod: value));

  void onDestinationPhoneChanged(String value) => emit(state.copyWith(destinationPhone: PhoneNumbers.clean(value)));

  void next() {
    switch (state.step) {
      case CreateGroupStep.rules:
        if (state.rulesValid) emit(state.copyWith(step: CreateGroupStep.dates));
      case CreateGroupStep.dates:
        if (state.datesValid) emit(state.copyWith(step: CreateGroupStep.summary));
      case CreateGroupStep.summary:
        break;
    }
  }

  /// Goes back one step; false when the page itself must close.
  bool back() {
    if (state.step == CreateGroupStep.rules) return false;
    emit(state.copyWith(step: CreateGroupStep.values[state.step.index - 1], clearError: true));
    return true;
  }

  /// Creates the group and returns it with its invitation; null when it failed.
  Future<(SavingsGroup, Invitation)?> create() async {
    if (!state.rulesValid || !state.datesValid || state.isLoading) return null;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final created = await createGroup.execute(state.toNewGroup());
      emit(state.copyWith(isLoading: false));
      return created;
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
      return null;
    }
  }

  /// Saves the rules of the group being edited; true when they were saved.
  Future<bool> save() async {
    final groupId = state.editingGroupId;
    if (groupId == null || !state.rulesValid || !state.datesValid || state.isLoading) return false;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      if (state.activatesPaidPlan) await activatePaidPlan.execute(groupId);
      await updateGroup.execute(groupId, state.toNewGroup());
      emit(state.copyWith(isLoading: false, groupPlan: state.effectivePlan));
      return true;
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}
