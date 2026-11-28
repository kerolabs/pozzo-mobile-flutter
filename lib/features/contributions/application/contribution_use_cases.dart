import 'dart:typed_data';

import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';

/// The cycle of a group and its current period: everything the pot shows.
class GetPotStateUseCase {
  const GetPotStateUseCase({required this.repository});

  final ContributionRepository repository;

  Future<(Cycle, Period)> execute(String groupId) async {
    final cycle = await repository.getCycleOfGroup(groupId);
    return (cycle, await repository.getCurrentPeriod(cycle.id));
  }
}

class GetCycleHistoryUseCase {
  const GetCycleHistoryUseCase({required this.repository});

  final ContributionRepository repository;

  Future<(Cycle, List<Period>)> execute(String groupId) async {
    final cycle = await repository.getCycleOfGroup(groupId);
    return (cycle, await repository.getPeriods(cycle.id));
  }
}

class GetCycleOfGroupUseCase {
  const GetCycleOfGroupUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Cycle> execute(String groupId) => repository.getCycleOfGroup(groupId);
}

class GetMyContributionsUseCase {
  const GetMyContributionsUseCase({required this.repository});

  final ContributionRepository repository;

  Future<MyContributions> execute(String groupId) => repository.getMyContributions(groupId);
}

class ClearLocalContributionsUseCase {
  const ClearLocalContributionsUseCase({required this.repository});

  final ContributionRepository repository;

  Future<void> execute() => repository.clearLocalContributions();
}

class RegisterContributionUseCase {
  const RegisterContributionUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Contribution> execute(String periodId, ReceiptData receipt) => repository.registerContribution(
        periodId,
        ReceiptData(
          operationNumber: receipt.operationNumber.trim(),
          payerName: receipt.payerName,
          payeeName: receipt.payeeName.trim(),
          amount: receipt.amount,
          paidAt: receipt.paidAt,
          source: receipt.source,
        ),
      );
}

class RegisterCashUseCase {
  const RegisterCashUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Contribution> execute(
    String periodId,
    String membershipId,
    double amount,
    DateTime receivedOn, {
    bool differenceConfirmed = false,
  }) =>
      repository.registerCash(periodId, membershipId, amount, receivedOn, differenceConfirmed: differenceConfirmed);
}

class RegisterCoverageUseCase {
  const RegisterCoverageUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Contribution> execute(String periodId, String membershipId, String coveredByMembershipId) =>
      repository.registerCoverage(periodId, membershipId, coveredByMembershipId);
}

class AttachReceiptImageUseCase {
  const AttachReceiptImageUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Contribution> execute(String contributionId, Uint8List jpeg) {
    if (jpeg.isEmpty) throw const AppException('No pudimos leer esa imagen. Prueba con otra.');
    return repository.attachReceiptImage(contributionId, jpeg);
  }
}

class GetReceiptImageUseCase {
  const GetReceiptImageUseCase({required this.repository});

  final ContributionRepository repository;

  Future<String> execute(String contributionId) => repository.getReceiptImageUrl(contributionId);
}

class ShareContributionUseCase {
  const ShareContributionUseCase({required this.repository});

  final ContributionRepository repository;

  Future<String> execute(String contributionId) => repository.shareContribution(contributionId);
}

class GetPendingReviewsUseCase {
  const GetPendingReviewsUseCase({required this.repository});

  final ContributionRepository repository;

  Future<List<Contribution>> execute(String periodId) => repository.getPendingReviews(periodId);
}

class ReviewContributionUseCase {
  const ReviewContributionUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Contribution> execute(String contributionId, ReviewDecision decision, String? note) =>
      repository.review(contributionId, decision, note == null || note.trim().isEmpty ? null : note.trim());
}

class GetReviewedContributionsUseCase {
  const GetReviewedContributionsUseCase({required this.repository});

  final ContributionRepository repository;

  Future<List<Contribution>> execute(String periodId) => repository.getReviewed(periodId);
}

class ReopenReviewUseCase {
  const ReopenReviewUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Contribution> execute(String contributionId) => repository.reopenReview(contributionId);
}

class DeliverPotUseCase {
  const DeliverPotUseCase({required this.repository});

  final ContributionRepository repository;

  Future<PotDelivery> execute(String periodId) => repository.deliverPot(periodId);
}

class SwapTurnsUseCase {
  const SwapTurnsUseCase({required this.repository});

  final ContributionRepository repository;

  Future<Cycle> execute(String cycleId, String firstMembershipId, String secondMembershipId) =>
      repository.swapTurns(cycleId, firstMembershipId, secondMembershipId);
}

class AttachPayoutProofUseCase {
  const AttachPayoutProofUseCase({required this.repository});

  final ContributionRepository repository;

  Future<void> execute(String periodId, Uint8List jpeg) {
    if (jpeg.isEmpty) throw const AppException('No pudimos leer esa imagen. Prueba con otra.');
    return repository.attachPayoutProof(periodId, jpeg);
  }
}

class GetPayoutProofUseCase {
  const GetPayoutProofUseCase({required this.repository});

  final ContributionRepository repository;

  Future<String> execute(String periodId) => repository.getPayoutProofUrl(periodId);
}

/// The auction of the current period of a group, with its cycle and period.
class GetTurnAuctionUseCase {
  const GetTurnAuctionUseCase({required this.contributions, required this.auctions});

  final ContributionRepository contributions;
  final AuctionRepository auctions;

  Future<(Cycle, Period, Auction)> execute(String groupId) async {
    final cycle = await contributions.getCycleOfGroup(groupId);
    final period = await contributions.getCurrentPeriod(cycle.id);
    return (cycle, period, await auctions.getAuction(period.id));
  }
}

/// The auction of a period, or null when the group does not assign turns by auction.
class FindAuctionUseCase {
  const FindAuctionUseCase({required this.auctions});

  final AuctionRepository auctions;

  Future<Auction?> execute(String periodId) async {
    try {
      return await auctions.getAuction(periodId);
    } catch (_) {
      return null;
    }
  }
}

class PlaceBidUseCase {
  const PlaceBidUseCase({required this.auctions});

  final AuctionRepository auctions;

  Future<Auction> execute(String periodId, double amount) => auctions.placeBid(periodId, amount);
}

class CloseAuctionUseCase {
  const CloseAuctionUseCase({required this.auctions});

  final AuctionRepository auctions;

  Future<Auction> execute(String periodId, String? winnerMembershipId) =>
      auctions.closeAuction(periodId, winnerMembershipId);
}
