/// Shapes of the Savings Groups endpoints. Each DTO keeps the JSON it came from, so the groups can be
/// stored on the phone as they arrived.
double _amount(Object? value) => value == null ? 0 : (value as num).toDouble();

class DestinationDto {
  const DestinationDto({required this.method, required this.phoneNumber});

  final String method;
  final String phoneNumber;

  factory DestinationDto.fromJson(Map<String, dynamic> json) =>
      DestinationDto(method: json['method'] as String, phoneNumber: json['phoneNumber'] as String);

  Map<String, dynamic> toJson() => {'method': method, 'phoneNumber': phoneNumber};
}

class RulesDto {
  const RulesDto({
    required this.contributionAmount,
    required this.currency,
    required this.periodicity,
    required this.seats,
    required this.firstContributionDate,
    required this.cutoffDay,
    required this.potAmount,
    required this.destination,
  });

  final double contributionAmount;
  final String currency;
  final String periodicity;
  final int seats;
  final String firstContributionDate;
  final int cutoffDay;
  final double potAmount;
  final DestinationDto? destination;

  factory RulesDto.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'] as Map<String, dynamic>?;
    return RulesDto(
      contributionAmount: _amount(json['contributionAmount']),
      currency: json['currency'] as String? ?? 'PEN',
      periodicity: json['periodicity'] as String,
      seats: json['seats'] as int,
      firstContributionDate: json['firstContributionDate'] as String,
      cutoffDay: json['cutoffDay'] as int? ?? 1,
      potAmount: _amount(json['potAmount']),
      destination: destination == null ? null : DestinationDto.fromJson(destination),
    );
  }
}

class ReadinessDto {
  const ReadinessDto({
    required this.groupFull,
    required this.turnsAssigned,
    required this.destinationDefined,
    required this.canStart,
  });

  final bool groupFull;
  final bool turnsAssigned;
  final bool destinationDefined;
  final bool canStart;

  factory ReadinessDto.fromJson(Map<String, dynamic>? json) => ReadinessDto(
        groupFull: json?['groupFull'] as bool? ?? false,
        turnsAssigned: json?['turnsAssigned'] as bool? ?? false,
        destinationDefined: json?['destinationDefined'] as bool? ?? false,
        canStart: json?['canStart'] as bool? ?? false,
      );
}

class GroupDto {
  const GroupDto({
    required this.json,
    required this.id,
    required this.name,
    required this.status,
    required this.plan,
    required this.role,
    required this.organizerName,
    required this.rules,
    required this.membersCount,
    required this.turnMethod,
    required this.myTurnNumber,
    required this.myTurnDate,
    required this.readiness,
    required this.createdAt,
  });

  final Map<String, dynamic> json;
  final String id;
  final String name;
  final String status;
  final String? plan;
  final String role;
  final String organizerName;
  final RulesDto rules;
  final int membersCount;
  final String? turnMethod;
  final int? myTurnNumber;
  final String? myTurnDate;
  final ReadinessDto readiness;
  final String createdAt;

  factory GroupDto.fromJson(Map<String, dynamic> json) {
    return GroupDto(
      json: json,
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      plan: json['plan'] as String?,
      role: json['role'] as String,
      organizerName: json['organizerName'] as String? ?? '',
      rules: RulesDto.fromJson(json['rules'] as Map<String, dynamic>),
      membersCount: json['membersCount'] as int? ?? 0,
      turnMethod: json['turnMethod'] as String?,
      myTurnNumber: json['myTurnNumber'] as int?,
      myTurnDate: json['myTurnDate'] as String?,
      readiness: ReadinessDto.fromJson(json['readiness'] as Map<String, dynamic>?),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class MemberDto {
  const MemberDto({
    required this.id,
    required this.displayName,
    required this.kind,
    required this.organizer,
    required this.me,
    required this.phoneNumber,
    required this.turnNumber,
    required this.photoUrl,
    required this.accountId,
  });

  final String id;
  final String displayName;
  final String kind;
  final bool organizer;
  final bool me;
  final String? phoneNumber;
  final int? turnNumber;
  final String? photoUrl;
  final String? accountId;

  factory MemberDto.fromJson(Map<String, dynamic> json) => MemberDto(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        kind: json['kind'] as String? ?? 'APP',
        organizer: json['organizer'] as bool? ?? false,
        me: json['me'] as bool? ?? false,
        phoneNumber: json['phoneNumber'] as String?,
        turnNumber: json['turnNumber'] as int?,
        photoUrl: json['photoUrl'] as String?,
        accountId: json['accountId'] as String?,
      );
}

class TurnDto {
  const TurnDto({
    required this.turnNumber,
    required this.membershipId,
    required this.displayName,
    required this.cutoffDate,
    required this.me,
    required this.photoUrl,
  });

  final int turnNumber;
  final String membershipId;
  final String displayName;
  final String cutoffDate;
  final bool me;
  final String? photoUrl;

  factory TurnDto.fromJson(Map<String, dynamic> json) => TurnDto(
        turnNumber: json['turnNumber'] as int,
        membershipId: json['membershipId'] as String,
        displayName: json['displayName'] as String,
        cutoffDate: json['cutoffDate'] as String,
        me: json['me'] as bool? ?? false,
        photoUrl: json['photoUrl'] as String?,
      );
}

class TurnCalendarDto {
  const TurnCalendarDto({
    required this.method,
    required this.drawSeed,
    required this.assignedAt,
    required this.potAmount,
    required this.turns,
  });

  final String? method;
  final String? drawSeed;
  final String? assignedAt;
  final double potAmount;
  final List<TurnDto> turns;

  factory TurnCalendarDto.fromJson(Map<String, dynamic> json) => TurnCalendarDto(
        method: json['method'] as String?,
        drawSeed: json['drawSeed'] as String?,
        assignedAt: json['assignedAt'] as String?,
        potAmount: _amount(json['potAmount']),
        turns: (json['turns'] as List? ?? []).map((e) => TurnDto.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class InvitationDto {
  const InvitationDto({required this.code, required this.link, required this.expiresAt});

  final String code;
  final String link;
  final String expiresAt;

  factory InvitationDto.fromJson(Map<String, dynamic> json) => InvitationDto(
        code: json['code'] as String,
        link: json['link'] as String? ?? '',
        expiresAt: json['expiresAt'] as String,
      );
}

class GroupPreviewDto {
  const GroupPreviewDto({
    required this.groupId,
    required this.name,
    required this.status,
    required this.organizerName,
    required this.rules,
    required this.membersCount,
    required this.freeSeats,
  });

  final String groupId;
  final String name;
  final String status;
  final String organizerName;
  final RulesDto rules;
  final int membersCount;
  final int freeSeats;

  factory GroupPreviewDto.fromJson(Map<String, dynamic> json) => GroupPreviewDto(
        groupId: json['groupId'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        organizerName: json['organizerName'] as String? ?? '',
        rules: RulesDto.fromJson(json['rules'] as Map<String, dynamic>),
        membersCount: json['membersCount'] as int? ?? 0,
        freeSeats: json['freeSeats'] as int? ?? 0,
      );
}
