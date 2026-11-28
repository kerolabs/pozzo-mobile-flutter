import 'package:pozzo/features/compliance_history/domain/compliance.dart';

class GetMyHistoryUseCase {
  const GetMyHistoryUseCase({required this.repository});

  final ComplianceRepository repository;

  Future<MyHistory> execute() => repository.getMyHistory();
}

class GetGroupComplianceUseCase {
  const GetGroupComplianceUseCase({required this.repository});

  final ComplianceRepository repository;

  Future<List<MemberCompliance>> execute(String groupId) => repository.getGroupCompliance(groupId);
}

class ShareMyHistoryUseCase {
  const ShareMyHistoryUseCase({required this.repository});

  final ComplianceRepository repository;

  Future<ShareLink> execute() => repository.shareMyHistory();
}

class GetMemberSummaryUseCase {
  const GetMemberSummaryUseCase({required this.repository});

  final ComplianceRepository repository;

  Future<ComplianceSummary> execute(String accountId) => repository.getMemberSummary(accountId);
}
