/// How a member pays across all their groups.
class ComplianceSummary {
  const ComplianceSummary({
    required this.level,
    required this.contributions,
    required this.onTime,
    required this.late,
    required this.covered,
    required this.rejected,
    required this.dropouts,
    required this.cyclesCompleted,
  });

  final String level;
  final int contributions;
  final int onTime;
  final int late;
  final int covered;
  final int rejected;
  final int dropouts;
  final int cyclesCompleted;

  /// The percentage of contributions on time, or null without contributions.
  int? get punctuality => contributions == 0 ? null : (onTime * 100 / contributions).round();
}

/// How the member paid in one group.
class GroupCompliance {
  const GroupCompliance({
    required this.groupId,
    required this.groupName,
    required this.completed,
    required this.onTime,
    required this.contributions,
  });

  final String groupId;
  final String groupName;
  final bool completed;
  final int onTime;
  final int contributions;
}

class MyHistory {
  const MyHistory({required this.summary, required this.groups});

  final ComplianceSummary summary;
  final List<GroupCompliance> groups;
}

/// How a member of a group pays, as the organizer sees it.
class MemberCompliance {
  const MemberCompliance({
    required this.membershipId,
    required this.displayName,
    required this.isOrganizer,
    required this.usesApp,
    required this.summary,
  });

  final String membershipId;
  final String displayName;
  final bool isOrganizer;
  final bool usesApp;
  final ComplianceSummary? summary;
}

/// A temporary link to show the history to someone outside Pozzo.
class ShareLink {
  const ShareLink({required this.token, required this.url, required this.expiresAt});

  final String token;
  final String url;
  final DateTime expiresAt;
}

abstract class ComplianceRepository {
  Future<MyHistory> getMyHistory();

  Future<List<MemberCompliance>> getGroupCompliance(String groupId);

  Future<ShareLink> shareMyHistory();

  Future<ComplianceSummary> getMemberSummary(String accountId);
}
