import 'package:pozzo/core/network/api_client.dart';
import 'package:pozzo/features/compliance_history/domain/compliance.dart';

/// Endpoints of Compliance History. The answers are small, so they become domain objects here.
class ComplianceApi {
  const ComplianceApi({required this.client});

  final ApiClient client;

  static ComplianceSummary summaryFromJson(Map<String, dynamic> json) => ComplianceSummary(
        level: json['level'] as String? ?? '',
        contributions: json['contributions'] as int? ?? 0,
        onTime: json['onTime'] as int? ?? 0,
        late: json['late'] as int? ?? 0,
        covered: json['covered'] as int? ?? 0,
        rejected: json['rejected'] as int? ?? 0,
        dropouts: json['dropouts'] as int? ?? 0,
        cyclesCompleted: json['cyclesCompleted'] as int? ?? 0,
      );

  Future<MyHistory> getMyHistory() async {
    final json = await client.get('members/me/compliance') as Map<String, dynamic>;
    return MyHistory(
      summary: summaryFromJson(json['summary'] as Map<String, dynamic>),
      groups: [
        for (final item in (json['groups'] as List? ?? []).cast<Map<String, dynamic>>())
          GroupCompliance(
            groupId: item['groupId'] as String,
            groupName: item['groupName'] as String,
            completed: item['status'] == 'COMPLETED',
            onTime: item['onTime'] as int? ?? 0,
            contributions: item['contributions'] as int? ?? 0,
          ),
      ],
    );
  }

  Future<List<MemberCompliance>> getGroupCompliance(String groupId) async {
    final list = (await client.get('groups/$groupId/compliance') as List).cast<Map<String, dynamic>>();
    return [
      for (final item in list)
        MemberCompliance(
          membershipId: item['membershipId'] as String,
          displayName: item['displayName'] as String,
          isOrganizer: item['organizer'] as bool? ?? false,
          usesApp: item['usesApp'] as bool? ?? false,
          summary: item['summary'] == null ? null : summaryFromJson(item['summary'] as Map<String, dynamic>),
        ),
    ];
  }

  Future<ShareLink> shareMyHistory() async {
    final json = await client.post('members/me/compliance/share') as Map<String, dynamic>;
    return ShareLink(
      token: json['token'] as String,
      url: json['url'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Future<ComplianceSummary> getMemberSummary(String accountId) async =>
      summaryFromJson(await client.get('members/$accountId/compliance/summary') as Map<String, dynamic>);
}
