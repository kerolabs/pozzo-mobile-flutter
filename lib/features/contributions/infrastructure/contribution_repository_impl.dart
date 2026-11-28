import 'dart:typed_data';

import 'package:pozzo/core/enum_codes.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/infrastructure/local/my_contributions_dao.dart';
import 'package:pozzo/features/contributions/infrastructure/mappers/contribution_mappers.dart';
import 'package:pozzo/features/contributions/infrastructure/remote/contributions_api.dart';

class ContributionRepositoryImpl implements ContributionRepository {
  const ContributionRepositoryImpl({required this.api, required this.dao});

  final ContributionsApi api;
  final MyContributionsDao dao;

  @override
  Future<Cycle> getCycleOfGroup(String groupId) async => ContributionMappers.cycle(await api.getCycleOfGroup(groupId));

  @override
  Future<Period> getCurrentPeriod(String cycleId) async =>
      ContributionMappers.period(await api.getCurrentPeriod(cycleId));

  @override
  Future<List<Period>> getPeriods(String cycleId) async =>
      (await api.getPeriods(cycleId)).map(ContributionMappers.period).toList();

  @override
  Future<MyContributions> getMyContributions(String groupId) async {
    try {
      final cycle = await getCycleOfGroup(groupId);
      final json = await api.getMyContributions(cycle.id);
      final now = DateTime.now();
      await dao.upsert(groupId, json, now);
      return ContributionMappers.myContributions(json, now, isOffline: false);
    } catch (_) {
      final cached = await dao.find(groupId);
      if (cached == null) rethrow;
      return ContributionMappers.myContributions(cached.$1, cached.$2, isOffline: true);
    }
  }

  @override
  Future<void> clearLocalContributions() => dao.deleteAll();

  @override
  Future<Contribution> registerContribution(String periodId, ReceiptData receipt) async => ContributionMappers
      .contribution(await api.registerContribution(periodId, ContributionMappers.receiptRequest(receipt)));

  @override
  Future<Contribution> registerCash(
    String periodId,
    String membershipId,
    double amount,
    DateTime receivedOn, {
    bool differenceConfirmed = false,
  }) async =>
      ContributionMappers.contribution(
        await api.registerCash(
          periodId,
          {
            'membershipId': membershipId,
            'amount': amount,
            'receivedOn': Formats.isoDate(receivedOn),
            'differenceConfirmed': differenceConfirmed,
          },
        ),
      );

  @override
  Future<Contribution> registerCoverage(String periodId, String membershipId, String coveredByMembershipId) async =>
      ContributionMappers.contribution(
        await api.registerCoverage(
          periodId,
          {'membershipId': membershipId, 'coveredByMembershipId': coveredByMembershipId},
        ),
      );

  @override
  Future<Contribution> attachReceiptImage(String contributionId, Uint8List jpeg) async =>
      ContributionMappers.contribution(await api.attachReceiptImage(contributionId, jpeg));

  @override
  Future<String> getReceiptImageUrl(String contributionId) async =>
      (await api.getReceiptImage(contributionId))['url'] as String;

  @override
  Future<String> shareContribution(String contributionId) async =>
      (await api.shareContribution(contributionId))['url'] as String;

  @override
  Future<List<Contribution>> getPendingReviews(String periodId) async =>
      (await api.getPendingReviews(periodId)).map(ContributionMappers.contribution).toList();

  @override
  Future<Contribution> review(String contributionId, ReviewDecision decision, String? note) async =>
      ContributionMappers.contribution(await api.review(contributionId, decision.code, note));

  @override
  Future<List<Contribution>> getReviewed(String periodId) async =>
      (await api.getReviewed(periodId)).map(ContributionMappers.contribution).toList();

  @override
  Future<Contribution> reopenReview(String contributionId) async =>
      ContributionMappers.contribution(await api.reopenReview(contributionId));

  @override
  Future<PotDelivery> deliverPot(String periodId) async => ContributionMappers.potDelivery(await api.deliverPot(periodId));

  @override
  Future<Cycle> swapTurns(String cycleId, String firstMembershipId, String secondMembershipId) async =>
      ContributionMappers.cycle(await api.swapTurns(cycleId, firstMembershipId, secondMembershipId));

  @override
  Future<void> attachPayoutProof(String periodId, Uint8List jpeg) => api.attachPayoutProof(periodId, jpeg);

  @override
  Future<String> getPayoutProofUrl(String periodId) async => (await api.getPayoutProof(periodId))['url'] as String;
}

class AuctionRepositoryImpl implements AuctionRepository {
  const AuctionRepositoryImpl({required this.api});

  final ContributionsApi api;

  @override
  Future<Auction> getAuction(String periodId) async => ContributionMappers.auction(await api.getAuction(periodId));

  @override
  Future<Auction> placeBid(String periodId, double amount) async =>
      ContributionMappers.auction(await api.placeBid(periodId, amount));

  @override
  Future<Auction> closeAuction(String periodId, String? winnerMembershipId) async =>
      ContributionMappers.auction(await api.closeAuction(periodId, winnerMembershipId));
}
