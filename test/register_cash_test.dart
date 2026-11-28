import 'package:flutter_test/flutter_test.dart';
import 'package:pozzo/features/contributions/infrastructure/contribution_repository_impl.dart';
import 'package:pozzo/features/contributions/infrastructure/local/my_contributions_dao.dart';
import 'package:pozzo/features/contributions/infrastructure/remote/contributions_api.dart';

class FakeContributionsApi extends Fake implements ContributionsApi {
  Map<String, dynamic>? cashRequest;

  @override
  Future<Map<String, dynamic>> registerCash(String periodId, Map<String, dynamic> request) async {
    cashRequest = request;
    return {
      'id': 'contribution-1',
      'periodId': periodId,
      'membershipId': request['membershipId'],
      'amount': request['amount'],
      'method': 'CASH',
      'status': 'VALIDATED',
      'registeredAt': '2026-11-28T10:00:00Z',
    };
  }
}

class FakeMyContributionsDao extends Fake implements MyContributionsDao {}

void main() {
  late FakeContributionsApi api;
  late ContributionRepositoryImpl repository;

  setUp(() {
    api = FakeContributionsApi();
    repository = ContributionRepositoryImpl(api: api, dao: FakeMyContributionsDao());
  });

  test('a cash amount equal to what is owed is sent without a confirmed difference', () async {
    await repository.registerCash('period-1', 'member-1', 200, DateTime(2026, 11, 28));

    expect(api.cashRequest?['differenceConfirmed'], isFalse);
  });

  test('a different cash amount the organizer confirmed is sent as confirmed', () async {
    await repository.registerCash('period-1', 'member-1', 150, DateTime(2026, 11, 28), differenceConfirmed: true);

    expect(api.cashRequest?['amount'], 150);
    expect(api.cashRequest?['differenceConfirmed'], isTrue);
  });
}
