import 'package:pozzo/core/enum_codes.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

/// Turns the JSON of the Contributions endpoints into domain objects, and back for the requests.
class ContributionMappers {
  const ContributionMappers._();

  static double _amount(Object? value) => value == null ? 0 : (value as num).toDouble();

  static double? _optionalAmount(Object? value) => value == null ? null : (value as num).toDouble();

  static DateTime? _instant(Object? value) => value == null ? null : DateTime.parse(value as String);

  static Cycle cycle(Map<String, dynamic> json) => Cycle(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        groupName: json['groupName'] as String? ?? '',
        isActive: json['status'] == 'ACTIVE',
        currentTurn: json['currentTurn'] as int? ?? 1,
        totalTurns: json['totalTurns'] as int? ?? 1,
        contributionAmount: _amount(json['contributionAmount']),
        potAmount: _amount(json['potAmount']),
        destinationMethod: json['destinationMethod'] as String? ?? '',
        destinationPhone: json['destinationPhoneNumber'] as String? ?? '',
        payeeName: json['payeeName'] as String? ?? '',
        isOrganizer: json['role'] == 'ORGANIZER',
        myMembershipId: json['myMembershipId'] as String? ?? '',
        myTurnNumber: json['myTurnNumber'] as int? ?? 0,
      );

  static Period period(Map<String, dynamic> json) {
    final potAmount = _amount(json['potAmount']);
    return Period(
      id: json['periodId'] as String,
      cycleId: json['cycleId'] as String,
      groupName: json['groupName'] as String? ?? '',
      turnNumber: json['turnNumber'] as int,
      totalTurns: json['totalTurns'] as int,
      state: parseEnum(PeriodState.values, json['status'] as String?),
      cutoffDate: Formats.parseDate(json['cutoffDate'] as String),
      daysToCutoff: json['daysToCutoff'] as int? ?? 0,
      payoutMembershipId: json['payoutMembershipId'] as String? ?? '',
      payoutMemberName: json['payoutMemberName'] as String? ?? '',
      contributionAmount: _amount(json['contributionAmount']),
      potAmount: potAmount,
      collectedAmount: _amount(json['collectedAmount']),
      missingAmount: _amount(json['missingAmount']),
      settledCount: json['settledCount'] as int? ?? 0,
      membersCount: json['membersCount'] as int? ?? 0,
      myState: json['myStatus'] == null ? null : parseEnum(ContributionState.values, json['myStatus'] as String),
      members: [
        for (final member in (json['members'] as List? ?? []).cast<Map<String, dynamic>>())
          MemberContribution(
            membershipId: member['membershipId'] as String,
            displayName: member['displayName'] as String,
            isMe: member['me'] as bool? ?? false,
            collects: member['collects'] as bool? ?? false,
            state: parseEnum(ContributionState.values, member['status'] as String?),
            contributionId: member['contributionId'] as String?,
            amount: _optionalAmount(member['amount']),
            reviewSince: _instant(member['reviewSince']),
          ),
      ],
      payoutAmount: _optionalAmount(json['payoutAmount']) ?? potAmount,
      deliveredAt: _instant(json['deliveredAt']),
      hasPayoutProof: json['hasPayoutProof'] as bool? ?? false,
    );
  }

  static Contribution contribution(Map<String, dynamic> json) {
    final receipt = json['receipt'] as Map<String, dynamic>?;
    return Contribution(
      id: json['id'] as String,
      periodId: json['periodId'] as String,
      membershipId: json['membershipId'] as String,
      memberName: json['memberName'] as String? ?? '',
      amount: _amount(json['amount']),
      method: parseEnum(ContributionMethod.values, json['method'] as String?),
      status: parseEnum(ContributionStatus.values, json['status'] as String?),
      receipt: receipt == null
          ? null
          : ReceiptData(
              operationNumber: receipt['operationNumber'] as String? ?? '',
              payerName: receipt['payerName'] as String?,
              payeeName: receipt['payeeName'] as String? ?? '',
              amount: _amount(receipt['amount']),
              paidAt: Formats.parseDate(receipt['paidAt'] as String),
              source: parseEnum(ReceiptSource.values, receipt['source'] as String?, fallback: ReceiptSource.bank),
            ),
      inconsistencies: [
        for (final item in (json['inconsistencies'] as List? ?? []).cast<Map<String, dynamic>>())
          Inconsistency(
            field: item['field'] as String? ?? '',
            expected: item['expected'] as String? ?? '',
            found: item['found'] as String? ?? '',
          ),
      ],
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      hasReceiptImage: json['hasReceiptImage'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> receiptRequest(ReceiptData receipt) => {
        'operationNumber': receipt.operationNumber,
        'payerName': receipt.payerName,
        'payeeName': receipt.payeeName,
        'amount': receipt.amount,
        'paidAt': Formats.isoDate(receipt.paidAt),
        'source': receipt.source.code,
        'readByApp': null,
      };

  static MyContributions myContributions(Map<String, dynamic> json, DateTime savedAt, {required bool isOffline}) =>
      MyContributions(
        cycleId: json['cycleId'] as String,
        groupName: json['groupName'] as String? ?? '',
        contributedAmount: _amount(json['contributedAmount']),
        pendingAmount: _amount(json['pendingAmount']),
        periods: [
          for (final item in (json['periods'] as List? ?? []).cast<Map<String, dynamic>>())
            MyPeriodContribution(
              periodId: item['periodId'] as String,
              turnNumber: item['turnNumber'] as int,
              cutoffDate: Formats.parseDate(item['cutoffDate'] as String),
              amount: _amount(item['amount']),
              state: parseEnum(ContributionState.values, item['status'] as String?),
              contribution: item['contribution'] == null
                  ? null
                  : contribution(item['contribution'] as Map<String, dynamic>),
            ),
        ],
        savedAt: savedAt,
        isOffline: isOffline,
      );

  static PotDelivery potDelivery(Map<String, dynamic> json) => PotDelivery(
        deliveredPeriodId: json['deliveredPeriodId'] as String,
        deliveredTurn: json['deliveredTurn'] as int,
        deliveredAmount: _amount(json['deliveredAmount']),
        cycleClosed: json['cycleStatus'] == 'CLOSED',
        nextTurn: json['nextTurn'] as int?,
      );

  static Auction auction(Map<String, dynamic> json) => Auction(
        periodId: json['periodId'] as String,
        turnNumber: json['turnNumber'] as int,
        status: parseEnum(AuctionStatus.values, json['status'] as String?),
        closesOn: Formats.parseDate(json['closesOn'] as String),
        minimumBid: _amount(json['minimumBid']),
        potAmount: _amount(json['potAmount']),
        fallback: parseEnum(AuctionFallback.values, json['fallback'] as String?, fallback: AuctionFallback.draw),
        canBid: json['canBid'] as bool? ?? false,
        myBid: _optionalAmount(json['myBid']),
        myBidIsHighest: json['myBidIsHighest'] as bool? ?? false,
        bids: [
          for (final bid in (json['bids'] as List? ?? []).cast<Map<String, dynamic>>())
            AuctionBid(
              membershipId: bid['membershipId'] as String,
              displayName: bid['displayName'] as String,
              amount: _amount(bid['amount']),
              receives: _amount(bid['receives']),
              placedAt: DateTime.parse(bid['placedAt'] as String),
            ),
        ],
        winnerMembershipId: json['winnerMembershipId'] as String?,
        winnerName: json['winnerName'] as String?,
        discount: _optionalAmount(json['discount']),
        payoutAmount: _optionalAmount(json['payoutAmount']),
        resolution: json['resolution'] == null
            ? null
            : parseEnum(AuctionResolution.values, json['resolution'] as String),
        closedAt: _instant(json['closedAt']),
      );
}
