import 'dart:typed_data';

/// The current cycle of a started group: who collects now, how much and where the money goes.
class Cycle {
  const Cycle({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.isActive,
    required this.currentTurn,
    required this.totalTurns,
    required this.contributionAmount,
    required this.potAmount,
    required this.destinationMethod,
    required this.destinationPhone,
    required this.payeeName,
    required this.isOrganizer,
    required this.myMembershipId,
    required this.myTurnNumber,
  });

  final String id;
  final String groupId;
  final String groupName;
  final bool isActive;
  final int currentTurn;
  final int totalTurns;
  final double contributionAmount;
  final double potAmount;
  final String destinationMethod;
  final String destinationPhone;
  final String payeeName;
  final bool isOrganizer;
  final String myMembershipId;
  final int myTurnNumber;
}

enum ContributionState {
  validated,
  inReview,
  pending,
  late,
  covered;

  bool get isSettled => this == ContributionState.validated || this == ContributionState.covered;
}

enum PeriodState { open, potComplete, delivered }

/// How one member stands in a period.
class MemberContribution {
  const MemberContribution({
    required this.membershipId,
    required this.displayName,
    required this.isMe,
    required this.collects,
    required this.state,
    required this.contributionId,
    this.amount,
    this.reviewSince,
  });

  final String membershipId;
  final String displayName;
  final bool isMe;
  final bool collects;
  final ContributionState state;
  final String? contributionId;

  /// What this member owes, when it is not the regular contribution (after an auction).
  final double? amount;
  final DateTime? reviewSince;
}

/// A period of the cycle: its cutoff, who collects and how the pot is going.
class Period {
  const Period({
    required this.id,
    required this.cycleId,
    required this.groupName,
    required this.turnNumber,
    required this.totalTurns,
    required this.state,
    required this.cutoffDate,
    required this.daysToCutoff,
    required this.payoutMembershipId,
    required this.payoutMemberName,
    required this.contributionAmount,
    required this.potAmount,
    required this.collectedAmount,
    required this.missingAmount,
    required this.settledCount,
    required this.membersCount,
    required this.myState,
    required this.members,
    required this.payoutAmount,
    this.deliveredAt,
    this.hasPayoutProof = false,
  });

  final String id;
  final String cycleId;
  final String groupName;
  final int turnNumber;
  final int totalTurns;
  final PeriodState state;
  final DateTime cutoffDate;
  final int daysToCutoff;
  final String payoutMembershipId;
  final String payoutMemberName;
  final double contributionAmount;
  final double potAmount;
  final double collectedAmount;
  final double missingAmount;
  final int settledCount;
  final int membersCount;
  final ContributionState? myState;
  final List<MemberContribution> members;
  final double payoutAmount;
  final DateTime? deliveredAt;
  final bool hasPayoutProof;

  double get auctionDiscount => potAmount - payoutAmount;

  double get progress => potAmount == 0 ? 0 : (collectedAmount / potAmount).clamp(0, 1).toDouble();

  int get inReviewCount => members.where((member) => member.state == ContributionState.inReview).length;

  List<MemberContribution> get unsettled => members
      .where((member) => !member.state.isSettled && member.state != ContributionState.inReview)
      .toList();

  double amountOwedBy(String membershipId) =>
      members.where((member) => member.membershipId == membershipId).firstOrNull?.amount ?? contributionAmount;

  double get myAmount => members.where((member) => member.isMe).firstOrNull?.amount ?? contributionAmount;
}

enum ReceiptSource {
  yape('Yape'),
  plin('Plin'),
  bank('Transferencia bancaria');

  const ReceiptSource(this.label);

  final String label;
}

/// The data of a transfer receipt as the member writes it.
class ReceiptData {
  const ReceiptData({
    required this.operationNumber,
    required this.payerName,
    required this.payeeName,
    required this.amount,
    required this.paidAt,
    required this.source,
  });

  final String operationNumber;
  final String? payerName;
  final String payeeName;
  final double amount;
  final DateTime paidAt;
  final ReceiptSource source;
}

enum ContributionMethod { transfer, cash, coverage }

enum ContributionStatus { validated, inconsistent, approved, rejected }

/// A field of the receipt that does not match the rules of the group.
class Inconsistency {
  const Inconsistency({required this.field, required this.expected, required this.found});

  final String field;
  final String expected;
  final String found;

  /// What the reviewer reads about the problem.
  String get label => switch (field) {
        'AMOUNT' => 'Monto distinto',
        'PAYEE' => 'Destinatario',
        'DATE' => 'Fuera de fecha',
        'EDITED_AMOUNT' => 'Monto corregido a mano',
        'EDITED_PAYEE' => 'Destinatario corregido a mano',
        'EDITED_DATE' => 'Fecha corregida a mano',
        'EDITED_OPERATION' => 'Operación corregida a mano',
        _ => field,
      };

  /// The field of the receipt it refers to.
  String get fieldLabel => switch (field) {
        'AMOUNT' => 'Monto',
        'PAYEE' => 'Enviado a',
        'DATE' => 'Fecha',
        _ => field,
      };
}

class Contribution {
  const Contribution({
    required this.id,
    required this.periodId,
    required this.membershipId,
    required this.memberName,
    required this.amount,
    required this.method,
    required this.status,
    required this.receipt,
    required this.inconsistencies,
    required this.registeredAt,
    this.hasReceiptImage = false,
  });

  final String id;
  final String periodId;
  final String membershipId;
  final String memberName;
  final double amount;
  final ContributionMethod method;
  final ContributionStatus status;
  final ReceiptData? receipt;
  final List<Inconsistency> inconsistencies;
  final DateTime registeredAt;
  final bool hasReceiptImage;
}

/// The pot was delivered: the cycle goes on with the next turn, or it closes.
class PotDelivery {
  const PotDelivery({
    required this.deliveredPeriodId,
    required this.deliveredTurn,
    required this.deliveredAmount,
    required this.cycleClosed,
    required this.nextTurn,
  });

  final String deliveredPeriodId;
  final int deliveredTurn;
  final double deliveredAmount;
  final bool cycleClosed;
  final int? nextTurn;
}

enum ReviewDecision { approve, reject }

class MyPeriodContribution {
  const MyPeriodContribution({
    required this.periodId,
    required this.turnNumber,
    required this.cutoffDate,
    required this.amount,
    required this.state,
    required this.contribution,
  });

  final String periodId;
  final int turnNumber;
  final DateTime cutoffDate;
  final double amount;
  final ContributionState state;
  final Contribution? contribution;
}

/// The contributions of the member in a cycle. [isOffline] means it comes from the phone.
class MyContributions {
  const MyContributions({
    required this.cycleId,
    required this.groupName,
    required this.contributedAmount,
    required this.pendingAmount,
    required this.periods,
    required this.savedAt,
    required this.isOffline,
  });

  final String cycleId;
  final String groupName;
  final double contributedAmount;
  final double pendingAmount;
  final List<MyPeriodContribution> periods;
  final DateTime savedAt;
  final bool isOffline;
}

abstract class ContributionRepository {
  Future<Cycle> getCycleOfGroup(String groupId);

  Future<Period> getCurrentPeriod(String cycleId);

  Future<List<Period>> getPeriods(String cycleId);

  /// From the backend; when there is no connection, the last copy kept on the phone.
  Future<MyContributions> getMyContributions(String groupId);

  Future<void> clearLocalContributions();

  Future<Contribution> registerContribution(String periodId, ReceiptData receipt);

  Future<Contribution> registerCash(String periodId, String membershipId, double amount, DateTime receivedOn);

  Future<Contribution> registerCoverage(String periodId, String membershipId, String coveredByMembershipId);

  Future<Contribution> attachReceiptImage(String contributionId, Uint8List jpeg);

  Future<String> getReceiptImageUrl(String contributionId);

  Future<String> shareContribution(String contributionId);

  Future<List<Contribution>> getPendingReviews(String periodId);

  Future<Contribution> review(String contributionId, ReviewDecision decision, String? note);

  Future<List<Contribution>> getReviewed(String periodId);

  Future<Contribution> reopenReview(String contributionId);

  Future<PotDelivery> deliverPot(String periodId);

  Future<Cycle> swapTurns(String cycleId, String firstMembershipId, String secondMembershipId);

  Future<void> attachPayoutProof(String periodId, Uint8List jpeg);

  Future<String> getPayoutProofUrl(String periodId);
}
