import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group_repository.dart';

class GetLocalGroupsUseCase {
  const GetLocalGroupsUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<List<SavingsGroup>> execute() => repository.getLocalGroups();
}

class RefreshMyGroupsUseCase {
  const RefreshMyGroupsUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<List<SavingsGroup>> execute() => repository.refreshMyGroups();
}

class ClearLocalGroupsUseCase {
  const ClearLocalGroupsUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<void> execute() => repository.clearLocalGroups();
}

/// Creates the group and its first invitation, which the organizer shares right away.
class CreateGroupUseCase {
  const CreateGroupUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<(SavingsGroup, Invitation)> execute(NewGroup group) async {
    final created = await repository.createGroup(
      NewGroup(
        name: group.name.trim(),
        contributionAmount: group.contributionAmount,
        periodicity: group.periodicity,
        seats: group.seats,
        firstContributionDate: group.firstContributionDate,
        destination: group.destination,
        plan: group.plan,
      ),
    );
    return (created, await repository.generateInvitation(created.id));
  }
}

class UpdateGroupUseCase {
  const UpdateGroupUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<SavingsGroup> execute(String groupId, NewGroup group) => repository.updateGroup(groupId, group);
}

class DeleteGroupUseCase {
  const DeleteGroupUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<void> execute(String groupId) => repository.deleteGroup(groupId);
}

class GetGroupUseCase {
  const GetGroupUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<SavingsGroup> execute(String groupId) => repository.getGroup(groupId);
}

/// The group, its members and its turns, requested at the same time.
class GetGroupDetailUseCase {
  const GetGroupDetailUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<GroupDetail> execute(String groupId) async {
    final (group, members, turns) = await (
      repository.getGroup(groupId),
      repository.getMembers(groupId),
      repository.getTurns(groupId),
    ).wait;
    return GroupDetail(group: group, members: members, turns: turns);
  }
}

class StartGroupUseCase {
  const StartGroupUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<SavingsGroup> execute(String groupId) => repository.startGroup(groupId);
}

class ActivatePaidPlanUseCase {
  const ActivatePaidPlanUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<SavingsGroup> execute(String groupId) => repository.activatePaidPlan(groupId);
}

class OpenNewCycleUseCase {
  const OpenNewCycleUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<SavingsGroup> execute(String groupId, DateTime firstContributionDate) =>
      repository.openNewCycle(groupId, firstContributionDate);
}

class GetInvitationUseCase {
  const GetInvitationUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<Invitation> execute(String groupId) => repository.getOrGenerateInvitation(groupId);
}

class PreviewInvitationUseCase {
  const PreviewInvitationUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<GroupPreview> execute(String code) => repository.previewInvitation(InvitationCodes.normalize(code));
}

class JoinGroupUseCase {
  const JoinGroupUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<SavingsGroup> execute(String code) => repository.joinGroup(InvitationCodes.normalize(code));
}

class GetMembersUseCase {
  const GetMembersUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<List<Member>> execute(String groupId) => repository.getMembers(groupId);
}

/// The photos of the members by membership, for the screens that list them. Without them the
/// initials are shown, so a failure is not an error.
class GetMemberPhotosUseCase {
  const GetMemberPhotosUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<Map<String, String>> execute(String groupId) async {
    try {
      final members = await repository.getMembers(groupId);
      return {
        for (final member in members)
          if (member.photoUrl != null) member.membershipId: member.photoUrl!,
      };
    } catch (_) {
      return {};
    }
  }
}

class AddManualMemberUseCase {
  const AddManualMemberUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<List<Member>> execute(String groupId, String displayName, String? phoneNumber) => repository.addManualMember(
        groupId,
        displayName.trim(),
        phoneNumber == null || phoneNumber.trim().isEmpty ? null : phoneNumber,
      );
}

class RemoveMemberUseCase {
  const RemoveMemberUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<void> execute(String groupId, String membershipId) => repository.removeMember(groupId, membershipId);
}

class RegisterDropoutUseCase {
  const RegisterDropoutUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<List<Member>> execute(String groupId, String membershipId) =>
      repository.registerDropout(groupId, membershipId);
}

class ReplaceMemberUseCase {
  const ReplaceMemberUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<List<Member>> execute(String groupId, String droppedMembershipId, String displayName, String? phoneNumber) =>
      repository.replaceMember(
        groupId,
        droppedMembershipId,
        displayName.trim(),
        phoneNumber == null || phoneNumber.trim().isEmpty ? null : phoneNumber,
      );
}

class GetTurnsUseCase {
  const GetTurnsUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<TurnCalendar> execute(String groupId) => repository.getTurns(groupId);
}

class DrawTurnsUseCase {
  const DrawTurnsUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<TurnCalendar> execute(String groupId) => repository.drawTurns(groupId);
}

class AssignAgreedTurnsUseCase {
  const AssignAgreedTurnsUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<TurnCalendar> execute(String groupId, List<String> order) => repository.assignAgreedTurns(groupId, order);
}

class AssignTurnsByAuctionUseCase {
  const AssignTurnsByAuctionUseCase({required this.repository});

  final SavingsGroupRepository repository;

  Future<TurnCalendar> execute(String groupId, AuctionRules rules) => repository.assignTurnsByAuction(groupId, rules);
}
