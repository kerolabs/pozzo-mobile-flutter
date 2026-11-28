import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

enum AuctionStatus { open, closed }

enum AuctionResolution { bid, draw, organizer }

class AuctionBid {
  const AuctionBid({
    required this.membershipId,
    required this.displayName,
    required this.amount,
    required this.receives,
    required this.placedAt,
  });

  final String membershipId;
  final String displayName;

  /// The discount offered on the pot.
  final double amount;

  /// What the bidder would receive: the pot minus the discount.
  final double receives;
  final DateTime placedAt;
}

/// The auction of the turn of a period, in the groups that assign turns by auction.
class Auction {
  const Auction({
    required this.periodId,
    required this.turnNumber,
    required this.status,
    required this.closesOn,
    required this.minimumBid,
    required this.potAmount,
    required this.fallback,
    required this.canBid,
    required this.myBid,
    required this.myBidIsHighest,
    required this.bids,
    required this.winnerMembershipId,
    required this.winnerName,
    required this.discount,
    required this.payoutAmount,
    required this.resolution,
    required this.closedAt,
  });

  final String periodId;
  final int turnNumber;
  final AuctionStatus status;
  final DateTime closesOn;
  final double minimumBid;
  final double potAmount;
  final AuctionFallback fallback;
  final bool canBid;
  final double? myBid;
  final bool myBidIsHighest;

  /// Highest first.
  final List<AuctionBid> bids;
  final String? winnerMembershipId;
  final String? winnerName;
  final double? discount;
  final double? payoutAmount;
  final AuctionResolution? resolution;
  final DateTime? closedAt;

  bool get isOpen => status == AuctionStatus.open;

  AuctionBid? get highestBid => bids.firstOrNull;
}

abstract class AuctionRepository {
  Future<Auction> getAuction(String periodId);

  Future<Auction> placeBid(String periodId, double amount);

  Future<Auction> closeAuction(String periodId, String? winnerMembershipId);
}
