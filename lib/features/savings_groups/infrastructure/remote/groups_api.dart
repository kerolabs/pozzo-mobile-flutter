import 'package:pozzo/core/network/api_client.dart';
import 'package:pozzo/features/savings_groups/infrastructure/remote/group_dtos.dart';

/// Endpoints of Savings Groups: `/groups`, `/invitations` and `/members/me/groups`.
class GroupsApi {
  const GroupsApi({required this.client});

  final ApiClient client;

  GroupDto _group(dynamic json) => GroupDto.fromJson(json as Map<String, dynamic>);

  List<MemberDto> _members(dynamic json) =>
      (json as List).map((e) => MemberDto.fromJson(e as Map<String, dynamic>)).toList();

  TurnCalendarDto _turns(dynamic json) => TurnCalendarDto.fromJson(json as Map<String, dynamic>);

  Future<List<GroupDto>> getMyGroups() async =>
      ((await client.get('members/me/groups')) as List).map(_group).toList();

  Future<GroupDto> createGroup(Map<String, dynamic> request) async => _group(await client.post('groups', body: request));

  Future<GroupDto> getGroup(String groupId) async => _group(await client.get('groups/$groupId'));

  Future<GroupDto> updateRules(String groupId, Map<String, dynamic> request) async =>
      _group(await client.put('groups/$groupId/rules', body: request));

  Future<GroupDto> defineDestination(String groupId, DestinationDto destination) async =>
      _group(await client.patch('groups/$groupId/destination', body: destination.toJson()));

  Future<void> deleteGroup(String groupId) => client.delete('groups/$groupId');

  Future<GroupDto> startGroup(String groupId) async => _group(await client.post('groups/$groupId/start'));

  Future<GroupDto> activatePaidPlan(String groupId) async => _group(await client.post('groups/$groupId/plan/paid'));

  Future<GroupDto> openNewCycle(String groupId, String firstContributionDate) async => _group(
        await client.post('groups/$groupId/new-cycle', body: {'firstContributionDate': firstContributionDate}),
      );

  Future<InvitationDto> generateInvitation(String groupId) async =>
      InvitationDto.fromJson(await client.post('groups/$groupId/invitations'));

  Future<InvitationDto> getActiveInvitation(String groupId) async =>
      InvitationDto.fromJson(await client.get('groups/$groupId/invitations/active'));

  Future<GroupPreviewDto> previewInvitation(String code) async =>
      GroupPreviewDto.fromJson(await client.get('invitations/$code'));

  Future<GroupDto> joinGroup(String code) async => _group(await client.post('invitations/$code/join'));

  Future<List<MemberDto>> getMembers(String groupId) async => _members(await client.get('groups/$groupId/members'));

  Future<List<MemberDto>> addManualMember(String groupId, String displayName, String? phoneNumber) async => _members(
        await client.post(
          'groups/$groupId/members/manual',
          body: {'displayName': displayName, 'phoneNumber': phoneNumber},
        ),
      );

  Future<void> removeMember(String groupId, String membershipId) =>
      client.delete('groups/$groupId/members/$membershipId');

  Future<List<MemberDto>> registerDropout(String groupId, String membershipId) async =>
      _members(await client.post('groups/$groupId/members/$membershipId/dropout'));

  Future<List<MemberDto>> replaceMember(String groupId, String membershipId, String displayName, String? phone) async =>
      _members(
        await client.post(
          'groups/$groupId/members/$membershipId/replacement',
          body: {'displayName': displayName, 'phoneNumber': phone},
        ),
      );

  Future<TurnCalendarDto> getTurns(String groupId) async => _turns(await client.get('groups/$groupId/turns'));

  Future<TurnCalendarDto> drawTurns(String groupId) async => _turns(await client.post('groups/$groupId/turns/draw'));

  Future<TurnCalendarDto> assignAgreedTurns(String groupId, List<String> order) async =>
      _turns(await client.post('groups/$groupId/turns/agreed', body: {'order': order}));

  Future<TurnCalendarDto> assignTurnsByAuction(String groupId, Map<String, dynamic> rules) async =>
      _turns(await client.post('groups/$groupId/turns/auction', body: rules));
}
