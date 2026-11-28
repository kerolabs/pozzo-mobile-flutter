import 'package:pozzo/core/format/formats.dart';

enum GroupStatus { draft, ready, started, closed }

enum GroupPlan {
  free,
  paid;

  static const int freeMaxSeats = 6;
  static const double paidPrice = 15;
}

enum GroupRole { organizer, participant }

enum Periodicity {
  weekly('Semanal'),
  biweekly('Quincenal'),
  monthly('Mensual');

  const Periodicity(this.title);

  final String title;

  String get adjective => title.toLowerCase();
}

enum TurnMethod {
  draw('Por sorteo'),
  agreed('Orden acordado'),
  auction('Por subasta');

  const TurnMethod(this.label);

  final String label;
}

enum AuctionFallback { draw, organizer }

enum PaymentMethod {
  yape('Yape'),
  plin('Plin');

  const PaymentMethod(this.label);

  final String label;
}

enum MembershipKind { app, manual }

/// Where the members send their contributions: a Yape or Plin number.
class Destination {
  const Destination({required this.method, required this.phoneNumber});

  final PaymentMethod method;
  final String phoneNumber;
}

class AuctionRules {
  const AuctionRules({required this.closesDaysBeforeCutoff, required this.minimumBid, required this.fallback});

  final int closesDaysBeforeCutoff;
  final double minimumBid;
  final AuctionFallback fallback;
}

/// What is missing before the organizer can start the group.
class Readiness {
  const Readiness({
    required this.groupFull,
    required this.turnsAssigned,
    required this.destinationDefined,
    required this.canStart,
  });

  final bool groupFull;
  final bool turnsAssigned;
  final bool destinationDefined;
  final bool canStart;
}

/// A savings group (junta) as the member sees it.
class SavingsGroup {
  const SavingsGroup({
    required this.id,
    required this.name,
    required this.status,
    required this.plan,
    required this.role,
    required this.organizerName,
    required this.contributionAmount,
    required this.currency,
    required this.periodicity,
    required this.seats,
    required this.membersCount,
    required this.potAmount,
    required this.firstContributionDate,
    required this.destination,
    required this.turnMethod,
    required this.myTurnNumber,
    required this.myTurnDate,
    required this.readiness,
  });

  final String id;
  final String name;
  final GroupStatus status;
  final GroupPlan plan;
  final GroupRole role;
  final String organizerName;
  final double contributionAmount;
  final String currency;
  final Periodicity periodicity;
  final int seats;
  final int membersCount;
  final double potAmount;
  final DateTime firstContributionDate;
  final Destination? destination;
  final TurnMethod? turnMethod;
  final int? myTurnNumber;
  final DateTime? myTurnDate;
  final Readiness readiness;

  bool get isOrganizer => role == GroupRole.organizer;
  bool get isStarted => status == GroupStatus.started || status == GroupStatus.closed;
  bool get usesFreePlanSlot => isOrganizer && plan == GroupPlan.free && status != GroupStatus.closed;

  /// The date of the cutoff of [turnNumber], counted from the first contribution.
  DateTime cutoffDateOfTurn(int turnNumber) {
    final periods = turnNumber - 1;
    final first = firstContributionDate;
    switch (periodicity) {
      case Periodicity.weekly:
        return DateTime(first.year, first.month, first.day + 7 * periods);
      case Periodicity.biweekly:
        return DateTime(first.year, first.month, first.day + 14 * periods);
      case Periodicity.monthly:
        return Formats.plusMonths(first, periods);
    }
  }
}

/// The rules of a group being created or edited.
class NewGroup {
  const NewGroup({
    required this.name,
    required this.contributionAmount,
    required this.periodicity,
    required this.seats,
    required this.firstContributionDate,
    required this.destination,
    this.plan = GroupPlan.free,
  });

  static const int minSeats = 2;
  static const int maxSeats = 50;
  static const int nameMaxLength = 80;

  final String name;
  final double contributionAmount;
  final Periodicity periodicity;
  final int seats;
  final DateTime firstContributionDate;
  final Destination? destination;
  final GroupPlan plan;

  double get potAmount => contributionAmount * seats;
}

class Member {
  const Member({
    required this.membershipId,
    required this.displayName,
    required this.kind,
    required this.isOrganizer,
    required this.isMe,
    required this.phoneNumber,
    required this.turnNumber,
    this.photoUrl,
    this.accountId,
  });

  final String membershipId;
  final String displayName;
  final MembershipKind kind;
  final bool isOrganizer;
  final bool isMe;
  final String? phoneNumber;
  final int? turnNumber;
  final String? photoUrl;
  final String? accountId;
}

class Turn {
  const Turn({
    required this.turnNumber,
    required this.membershipId,
    required this.displayName,
    required this.cutoffDate,
    required this.isMe,
    this.photoUrl,
  });

  final int turnNumber;
  final String membershipId;
  final String displayName;
  final DateTime cutoffDate;
  final bool isMe;
  final String? photoUrl;
}

class TurnCalendar {
  const TurnCalendar({
    required this.method,
    required this.drawSeed,
    required this.assignedAt,
    required this.potAmount,
    required this.turns,
  });

  final TurnMethod? method;
  final String? drawSeed;
  final DateTime? assignedAt;
  final double potAmount;
  final List<Turn> turns;
}

/// A group with its members and its turns, as the detail shows it.
class GroupDetail {
  const GroupDetail({required this.group, required this.members, required this.turns});

  final SavingsGroup group;
  final List<Member> members;
  final TurnCalendar turns;
}

/// An invitation to join a group: a code of six characters and its link.
class Invitation {
  const Invitation({required this.code, required this.link, required this.expiresAt});

  final String code;
  final String link;
  final DateTime expiresAt;
}

/// What a person sees of a group before joining it with a code.
class GroupPreview {
  const GroupPreview({
    required this.groupId,
    required this.name,
    required this.status,
    required this.organizerName,
    required this.contributionAmount,
    required this.periodicity,
    required this.seats,
    required this.potAmount,
    required this.firstContributionDate,
    required this.cutoffDay,
    required this.membersCount,
    required this.freeSeats,
  });

  final String groupId;
  final String name;
  final GroupStatus status;
  final String organizerName;
  final double contributionAmount;
  final Periodicity periodicity;
  final int seats;
  final double potAmount;
  final DateTime firstContributionDate;
  final int cutoffDay;
  final int membersCount;
  final int freeSeats;
}

/// Codes of invitation: six letters or digits, shown as "JB-7K4M".
class InvitationCodes {
  const InvitationCodes._();

  static const int length = 6;

  static String normalize(String input) {
    final code = input.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return code.length > length ? code.substring(0, length) : code;
  }

  static String display(String normalized) =>
      normalized.length > 2 ? '${normalized.substring(0, 2)}-${normalized.substring(2)}' : normalized;

  static bool isComplete(String normalized) => normalized.length == length;
}

/// Labels of the rules of a group.
class GroupLabels {
  const GroupLabels._();

  static const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  static String cutoff(Periodicity periodicity, DateTime firstContributionDate) {
    final weekday = _weekdays[firstContributionDate.weekday - 1];
    switch (periodicity) {
      case Periodicity.monthly:
        return 'Día ${firstContributionDate.day} de cada mes';
      case Periodicity.weekly:
        return 'Cada $weekday';
      case Periodicity.biweekly:
        return 'Un $weekday de por medio';
    }
  }

  static String shortCutoff(Periodicity periodicity, DateTime firstContributionDate) {
    if (periodicity == Periodicity.monthly) return 'Corte día ${firstContributionDate.day}';
    final label = cutoff(periodicity, firstContributionDate);
    return 'Corte ${label[0].toLowerCase()}${label.substring(1)}';
  }

  static String turnMethod(TurnMethod? method) => method?.label ?? 'Sin definir';
}
