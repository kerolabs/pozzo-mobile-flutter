import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

enum CreateGroupStep {
  rules(1, 'Reglas'),
  dates(2, 'Fechas y destino'),
  summary(3, 'Resumen');

  const CreateGroupStep(this.number, this.label);

  final int number;
  final String label;
}

class CreateGroupState {
  CreateGroupState({
    this.step = CreateGroupStep.rules,
    this.name = '',
    this.amount = '',
    this.periodicity = Periodicity.monthly,
    this.seats = GroupPlan.freeMaxSeats,
    this.plan = GroupPlan.free,
    this.groupPlan,
    this.freePlanInUse = false,
    DateTime? firstContributionDate,
    this.paymentMethod = PaymentMethod.yape,
    this.destinationPhone = '',
    this.isLoading = false,
    this.errorMessage,
    this.editingGroupId,
    this.isPreparing = false,
    this.minSeats = NewGroup.minSeats,
    this.originalSeats,
    this.turnsAssigned = false,
  }) : firstContributionDate = firstContributionDate ?? Formats.today().add(const Duration(days: 7));

  final CreateGroupStep step;
  final String name;
  final String amount;
  final Periodicity periodicity;
  final int seats;
  final GroupPlan plan;

  /// The plan the group already has, when it is edited.
  final GroupPlan? groupPlan;
  final bool freePlanInUse;
  final DateTime firstContributionDate;
  final PaymentMethod paymentMethod;
  final String destinationPhone;
  final bool isLoading;
  final String? errorMessage;
  final String? editingGroupId;
  final bool isPreparing;
  final int minSeats;
  final int? originalSeats;
  final bool turnsAssigned;

  bool get isEditing => editingGroupId != null;

  String? get freePlanUnavailableReason {
    if (seats > GroupPlan.freeMaxSeats) return 'Más de ${GroupPlan.freeMaxSeats} integrantes requiere el plan de pago.';
    if (!isEditing && freePlanInUse) return 'Ya tienes una junta activa con el plan gratuito.';
    return null;
  }

  GroupPlan get effectivePlan {
    if (groupPlan == GroupPlan.paid || freePlanUnavailableReason != null) return GroupPlan.paid;
    if (isEditing) return GroupPlan.free;
    return plan;
  }

  bool get activatesPaidPlan => effectivePlan == GroupPlan.paid && groupPlan != GroupPlan.paid;

  bool get clearsTurns => turnsAssigned && originalSeats != null && seats != originalSeats;

  /// The amount typed, with at most two decimals and at least S/ 1.
  double? get contributionAmount {
    final text = amount.replaceAll(',', '.');
    final value = double.tryParse(text);
    if (value == null || value < 1) return null;
    final decimals = text.contains('.') ? text.split('.').last.length : 0;
    return decimals <= 2 ? value : null;
  }

  double? get potAmount => contributionAmount == null ? null : contributionAmount! * seats;

  bool get rulesValid =>
      name.trim().isNotEmpty && contributionAmount != null && seats >= minSeats && seats <= NewGroup.maxSeats;

  bool get datesValid => !firstContributionDate.isBefore(Formats.today()) && PhoneNumbers.isValid(destinationPhone);

  NewGroup toNewGroup() => NewGroup(
        name: name,
        contributionAmount: contributionAmount ?? 0,
        periodicity: periodicity,
        seats: seats,
        firstContributionDate: firstContributionDate,
        destination: Destination(method: paymentMethod, phoneNumber: destinationPhone),
        plan: effectivePlan,
      );

  CreateGroupState copyWith({
    CreateGroupStep? step,
    String? name,
    String? amount,
    Periodicity? periodicity,
    int? seats,
    GroupPlan? plan,
    GroupPlan? groupPlan,
    bool? freePlanInUse,
    DateTime? firstContributionDate,
    PaymentMethod? paymentMethod,
    String? destinationPhone,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isPreparing,
    int? minSeats,
    int? originalSeats,
    bool? turnsAssigned,
  }) {
    return CreateGroupState(
      step: step ?? this.step,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      periodicity: periodicity ?? this.periodicity,
      seats: seats ?? this.seats,
      plan: plan ?? this.plan,
      groupPlan: groupPlan ?? this.groupPlan,
      freePlanInUse: freePlanInUse ?? this.freePlanInUse,
      firstContributionDate: firstContributionDate ?? this.firstContributionDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      destinationPhone: destinationPhone ?? this.destinationPhone,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      editingGroupId: editingGroupId,
      isPreparing: isPreparing ?? this.isPreparing,
      minSeats: minSeats ?? this.minSeats,
      originalSeats: originalSeats ?? this.originalSeats,
      turnsAssigned: turnsAssigned ?? this.turnsAssigned,
    );
  }
}
