import 'package:pozzo/features/compliance_history/domain/compliance.dart';
import 'package:pozzo/features/compliance_history/infrastructure/remote/compliance_api.dart';

class ComplianceRepositoryImpl implements ComplianceRepository {
  const ComplianceRepositoryImpl({required this.api});

  final ComplianceApi api;

  @override
  Future<MyHistory> getMyHistory() => api.getMyHistory();

  @override
  Future<List<MemberCompliance>> getGroupCompliance(String groupId) => api.getGroupCompliance(groupId);

  @override
  Future<ShareLink> shareMyHistory() => api.shareMyHistory();

  @override
  Future<ComplianceSummary> getMemberSummary(String accountId) => api.getMemberSummary(accountId);
}
