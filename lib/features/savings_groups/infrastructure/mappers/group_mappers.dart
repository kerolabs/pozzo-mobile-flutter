import 'package:pozzo/core/enum_codes.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/infrastructure/remote/group_dtos.dart';

extension DestinationDtoMapper on DestinationDto {
  Destination toDomain() => Destination(method: parseEnum(PaymentMethod.values, method), phoneNumber: phoneNumber);
}

extension DestinationMapper on Destination {
  DestinationDto toDto() => DestinationDto(method: method.code, phoneNumber: phoneNumber);
}

extension GroupDtoMapper on GroupDto {
  SavingsGroup toDomain() {
    return SavingsGroup(
      id: id,
      name: name,
      status: parseEnum(GroupStatus.values, status),
      // Groups created before the plans existed have all the features.
      plan: parseEnum(GroupPlan.values, plan, fallback: GroupPlan.paid),
      role: parseEnum(GroupRole.values, role),
      organizerName: organizerName,
      contributionAmount: rules.contributionAmount,
      currency: rules.currency,
      periodicity: parseEnum(Periodicity.values, rules.periodicity),
      seats: rules.seats,
      membersCount: membersCount,
      potAmount: rules.potAmount,
      firstContributionDate: Formats.parseDate(rules.firstContributionDate),
      destination: rules.destination?.toDomain(),
      turnMethod: turnMethod == null ? null : parseEnum(TurnMethod.values, turnMethod),
      myTurnNumber: myTurnNumber,
      myTurnDate: myTurnDate == null ? null : Formats.parseDate(myTurnDate!),
      readiness: Readiness(
        groupFull: readiness.groupFull,
        turnsAssigned: readiness.turnsAssigned,
        destinationDefined: readiness.destinationDefined,
        canStart: readiness.canStart,
      ),
    );
  }
}

extension NewGroupMapper on NewGroup {
  Map<String, dynamic> toCreateRequest() => {
        ...toRulesRequest(),
        'destination': destination?.toDto().toJson(),
        'plan': plan.code,
      };

  Map<String, dynamic> toRulesRequest() => {
        'name': name,
        'contributionAmount': contributionAmount,
        'periodicity': periodicity.code,
        'seats': seats,
        'firstContributionDate': Formats.isoDate(firstContributionDate),
      };
}

extension MemberDtoMapper on MemberDto {
  Member toDomain() => Member(
        membershipId: id,
        displayName: displayName,
        kind: parseEnum(MembershipKind.values, kind, fallback: MembershipKind.app),
        isOrganizer: organizer,
        isMe: me,
        phoneNumber: phoneNumber,
        turnNumber: turnNumber,
        photoUrl: photoUrl,
        accountId: accountId,
      );
}

extension TurnCalendarDtoMapper on TurnCalendarDto {
  TurnCalendar toDomain() => TurnCalendar(
        method: method == null ? null : parseEnum(TurnMethod.values, method),
        drawSeed: drawSeed,
        assignedAt: assignedAt == null ? null : DateTime.parse(assignedAt!),
        potAmount: potAmount,
        turns: [
          for (final turn in turns)
            Turn(
              turnNumber: turn.turnNumber,
              membershipId: turn.membershipId,
              displayName: turn.displayName,
              cutoffDate: Formats.parseDate(turn.cutoffDate),
              isMe: turn.me,
              photoUrl: turn.photoUrl,
            ),
        ],
      );
}

extension InvitationDtoMapper on InvitationDto {
  Invitation toDomain() => Invitation(code: code, link: link, expiresAt: DateTime.parse(expiresAt));
}

extension GroupPreviewDtoMapper on GroupPreviewDto {
  GroupPreview toDomain() => GroupPreview(
        groupId: groupId,
        name: name,
        status: parseEnum(GroupStatus.values, status),
        organizerName: organizerName,
        contributionAmount: rules.contributionAmount,
        periodicity: parseEnum(Periodicity.values, rules.periodicity),
        seats: rules.seats,
        potAmount: rules.potAmount,
        firstContributionDate: Formats.parseDate(rules.firstContributionDate),
        cutoffDay: rules.cutoffDay,
        membersCount: membersCount,
        freeSeats: freeSeats,
      );
}
