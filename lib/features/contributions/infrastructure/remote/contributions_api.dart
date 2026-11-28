import 'dart:typed_data';

import 'package:pozzo/core/network/api_client.dart';

/// Endpoints of Contributions: cycles, periods, contributions, reviews, the payout and the auctions.
/// They answer the JSON as it comes; the repository maps it.
class ContributionsApi {
  const ContributionsApi({required this.client});

  final ApiClient client;

  Future<Map<String, dynamic>> _map(Future<dynamic> request) async => (await request) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> _list(Future<dynamic> request) async =>
      ((await request) as List).cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> getCycleOfGroup(String groupId) => _map(client.get('groups/$groupId/cycle'));

  Future<Map<String, dynamic>> getCurrentPeriod(String cycleId) =>
      _map(client.get('cycles/$cycleId/periods/current'));

  Future<List<Map<String, dynamic>>> getPeriods(String cycleId) => _list(client.get('cycles/$cycleId/periods'));

  Future<Map<String, dynamic>> getMyContributions(String cycleId) =>
      _map(client.get('cycles/$cycleId/members/me/contributions'));

  Future<Map<String, dynamic>> registerContribution(String periodId, Map<String, dynamic> receipt) =>
      _map(client.post('periods/$periodId/contributions', body: receipt));

  Future<Map<String, dynamic>> registerCash(String periodId, Map<String, dynamic> request) =>
      _map(client.post('periods/$periodId/contributions/cash', body: request));

  Future<Map<String, dynamic>> registerCoverage(String periodId, Map<String, dynamic> request) =>
      _map(client.post('periods/$periodId/contributions/coverage', body: request));

  Future<Map<String, dynamic>> attachReceiptImage(String contributionId, Uint8List jpeg) => _map(
        client.multipart(
          'PUT',
          'contributions/$contributionId/receipt-image',
          field: 'image',
          bytes: jpeg,
          filename: 'receipt.jpg',
        ),
      );

  Future<Map<String, dynamic>> getReceiptImage(String contributionId) =>
      _map(client.get('contributions/$contributionId/receipt-image'));

  Future<Map<String, dynamic>> shareContribution(String contributionId) =>
      _map(client.post('contributions/$contributionId/share'));

  Future<List<Map<String, dynamic>>> getPendingReviews(String periodId) =>
      _list(client.get('periods/$periodId/contributions/pending-review'));

  Future<List<Map<String, dynamic>>> getReviewed(String periodId) =>
      _list(client.get('periods/$periodId/contributions/reviewed'));

  Future<Map<String, dynamic>> reopenReview(String contributionId) =>
      _map(client.post('contributions/$contributionId/review/reopen'));

  Future<Map<String, dynamic>> review(String contributionId, String decision, String? note) =>
      _map(client.patch('contributions/$contributionId/review', body: {'decision': decision, 'note': note}));

  Future<Map<String, dynamic>> deliverPot(String periodId) => _map(client.post('periods/$periodId/payout'));

  Future<Map<String, dynamic>> swapTurns(String cycleId, String first, String second) => _map(
        client.post('cycles/$cycleId/turns/swap', body: {'firstMembershipId': first, 'secondMembershipId': second}),
      );

  Future<void> attachPayoutProof(String periodId, Uint8List jpeg) =>
      client.multipart('PUT', 'periods/$periodId/payout/proof', field: 'image', bytes: jpeg, filename: 'transfer.jpg');

  Future<Map<String, dynamic>> getPayoutProof(String periodId) => _map(client.get('periods/$periodId/payout/proof'));

  Future<Map<String, dynamic>> getAuction(String periodId) => _map(client.get('periods/$periodId/auction'));

  Future<Map<String, dynamic>> placeBid(String periodId, double amount) =>
      _map(client.post('periods/$periodId/auction/bids', body: {'amount': amount}));

  Future<Map<String, dynamic>> closeAuction(String periodId, String? winnerMembershipId) =>
      _map(client.post('periods/$periodId/auction/close', body: {'winnerMembershipId': winnerMembershipId}));
}
