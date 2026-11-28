import 'package:pozzo/core/enum_codes.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group_repository.dart';
import 'package:pozzo/features/savings_groups/infrastructure/local/group_dao.dart';
import 'package:pozzo/features/savings_groups/infrastructure/mappers/group_mappers.dart';
import 'package:pozzo/features/savings_groups/infrastructure/remote/group_dtos.dart';
import 'package:pozzo/features/savings_groups/infrastructure/remote/groups_api.dart';

class SavingsGroupRepositoryImpl implements SavingsGroupRepository {
  const SavingsGroupRepositoryImpl({required this.api, required this.dao});

  final GroupsApi api;
  final GroupDao dao;

  /// Every group the backend answers is kept on the phone, so the list is up to date.
  Future<SavingsGroup> _saveLocally(GroupDto dto) async {
    await dao.upsert(dto);
    return dto.toDomain();
  }

  @override
  Future<List<SavingsGroup>> getLocalGroups() async => (await dao.getAll()).map((dto) => dto.toDomain()).toList();

  @override
  Future<List<SavingsGroup>> refreshMyGroups() async {
    final groups = await api.getMyGroups();
    await dao.replaceAll(groups);
    return getLocalGroups();
  }

  @override
  Future<void> clearLocalGroups() => dao.deleteAll();

  @override
  Future<SavingsGroup> createGroup(NewGroup group) async =>
      _saveLocally(await api.createGroup(group.toCreateRequest()));

  @override
  Future<SavingsGroup> updateGroup(String groupId, NewGroup group) async {
    var updated = await api.updateRules(groupId, group.toRulesRequest());
    final destination = group.destination;
    if (destination != null) updated = await api.defineDestination(groupId, destination.toDto());
    return _saveLocally(updated);
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await api.deleteGroup(groupId);
    await dao.deleteById(groupId);
  }

  @override
  Future<SavingsGroup> getGroup(String groupId) async {
    try {
      return await _saveLocally(await api.getGroup(groupId));
    } on ApiException catch (error) {
      // The group no longer exists or the member left it.
      if (error.status == 404) await dao.deleteById(groupId);
      rethrow;
    }
  }

  @override
  Future<SavingsGroup> startGroup(String groupId) async => _saveLocally(await api.startGroup(groupId));

  @override
  Future<SavingsGroup> activatePaidPlan(String groupId) async => _saveLocally(await api.activatePaidPlan(groupId));

  @override
  Future<SavingsGroup> openNewCycle(String groupId, DateTime firstContributionDate) async =>
      _saveLocally(await api.openNewCycle(groupId, Formats.isoDate(firstContributionDate)));

  @override
  Future<Invitation> generateInvitation(String groupId) async => (await api.generateInvitation(groupId)).toDomain();

  @override
  Future<Invitation> getOrGenerateInvitation(String groupId) async {
    try {
      return (await api.getActiveInvitation(groupId)).toDomain();
    } on ApiException catch (error) {
      if (error.status == 404) return generateInvitation(groupId);
      rethrow;
    }
  }

  @override
  Future<GroupPreview> previewInvitation(String code) async => (await api.previewInvitation(code)).toDomain();

  @override
  Future<SavingsGroup> joinGroup(String code) async => _saveLocally(await api.joinGroup(code));

  @override
  Future<List<Member>> getMembers(String groupId) async =>
      (await api.getMembers(groupId)).map((dto) => dto.toDomain()).toList();

  @override
  Future<List<Member>> addManualMember(String groupId, String displayName, String? phoneNumber) async =>
      (await api.addManualMember(groupId, displayName, phoneNumber)).map((dto) => dto.toDomain()).toList();

  @override
  Future<void> removeMember(String groupId, String membershipId) => api.removeMember(groupId, membershipId);

  @override
  Future<List<Member>> registerDropout(String groupId, String membershipId) async =>
      (await api.registerDropout(groupId, membershipId)).map((dto) => dto.toDomain()).toList();

  @override
  Future<List<Member>> replaceMember(
    String groupId,
    String droppedMembershipId,
    String displayName,
    String? phoneNumber,
  ) async =>
      (await api.replaceMember(groupId, droppedMembershipId, displayName, phoneNumber))
          .map((dto) => dto.toDomain())
          .toList();

  @override
  Future<TurnCalendar> getTurns(String groupId) async => (await api.getTurns(groupId)).toDomain();

  @override
  Future<TurnCalendar> drawTurns(String groupId) async => (await api.drawTurns(groupId)).toDomain();

  @override
  Future<TurnCalendar> assignAgreedTurns(String groupId, List<String> order) async =>
      (await api.assignAgreedTurns(groupId, order)).toDomain();

  @override
  Future<TurnCalendar> assignTurnsByAuction(String groupId, AuctionRules rules) async => (await api.assignTurnsByAuction(
        groupId,
        {
          'closesDaysBeforeCutoff': rules.closesDaysBeforeCutoff,
          'minimumBid': rules.minimumBid,
          'fallback': rules.fallback.code,
        },
      ))
          .toDomain();
}
