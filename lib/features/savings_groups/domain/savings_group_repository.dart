import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

/// Savings Groups: the groups of the member, their rules, members, invitations and turns.
abstract class SavingsGroupRepository {
  /// The groups kept on the phone, so the list opens at once and works without signal.
  Future<List<SavingsGroup>> getLocalGroups();

  /// Reads the groups from the backend and replaces the ones kept on the phone.
  Future<List<SavingsGroup>> refreshMyGroups();

  Future<void> clearLocalGroups();

  Future<SavingsGroup> createGroup(NewGroup group);

  Future<SavingsGroup> updateGroup(String groupId, NewGroup group);

  Future<void> deleteGroup(String groupId);

  Future<SavingsGroup> getGroup(String groupId);

  Future<SavingsGroup> startGroup(String groupId);

  Future<SavingsGroup> activatePaidPlan(String groupId);

  Future<SavingsGroup> openNewCycle(String groupId, DateTime firstContributionDate);

  Future<Invitation> generateInvitation(String groupId);

  /// The active invitation, or a new one when the group has none.
  Future<Invitation> getOrGenerateInvitation(String groupId);

  Future<GroupPreview> previewInvitation(String code);

  Future<SavingsGroup> joinGroup(String code);

  Future<List<Member>> getMembers(String groupId);

  Future<List<Member>> addManualMember(String groupId, String displayName, String? phoneNumber);

  Future<void> removeMember(String groupId, String membershipId);

  Future<List<Member>> registerDropout(String groupId, String membershipId);

  Future<List<Member>> replaceMember(String groupId, String droppedMembershipId, String displayName, String? phoneNumber);

  Future<TurnCalendar> getTurns(String groupId);

  Future<TurnCalendar> drawTurns(String groupId);

  Future<TurnCalendar> assignAgreedTurns(String groupId, List<String> order);

  Future<TurnCalendar> assignTurnsByAuction(String groupId, AuctionRules rules);
}
