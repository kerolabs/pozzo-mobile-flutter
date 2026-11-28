import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/presentation/auction/auction_page.dart';
import 'package:pozzo/features/contributions/presentation/calendar/turn_calendar_page.dart';
import 'package:pozzo/features/contributions/presentation/organizer/organizer_pages.dart';
import 'package:pozzo/features/contributions/presentation/organizer/reviews_pages.dart';
import 'package:pozzo/features/contributions/presentation/periods/past_periods_page.dart';
import 'package:pozzo/features/contributions/presentation/pot/pot_view_model.dart';
import 'package:pozzo/features/contributions/presentation/register/register_contribution_page.dart';
import 'package:pozzo/features/contributions/presentation/widgets/contribution_widgets.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_page.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/member_profile_sheet.dart';

/// C1: "El pozo" of a started group, the screen the member opens most.
class PotPage extends StatefulWidget {
  const PotPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<PotPage> createState() => _PotPageState();
}

class _PotPageState extends State<PotPage> {
  late final PotViewModel viewModel = getIt<PotViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  /// Opens a page and reads the pot again when the member comes back.
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    if (mounted) viewModel.load();
  }

  Future<void> _openMember(MemberContribution contribution, Cycle cycle) async {
    try {
      final members = await getIt<GetMembersUseCase>().execute(widget.groupId);
      final member = members.where((m) => m.membershipId == contribution.membershipId).firstOrNull;
      if (member == null || !mounted) return;
      final contributionId = contribution.contributionId;
      await showMemberProfile(
        context,
        member,
        actions: [
          if (contributionId != null && (cycle.isOrganizer || contribution.isMe))
            PozzoOutlinedButton(
              text: 'Ver comprobante',
              icon: Icons.image_outlined,
              onPressed: () => showReceiptImage(context, contributionId),
            ),
        ],
      );
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final cycle = state.cycle;
        final period = state.period;
        final organizer = cycle?.isOrganizer == true;
        return Scaffold(
          appBar: AppBar(
            title: Text(cycle?.groupName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Calendario de turnos',
                onPressed: () => _open(TurnCalendarPage(groupId: groupId)),
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              PopupMenuButton<Widget>(
                tooltip: 'Más opciones',
                onSelected: _open,
                itemBuilder: (context) => [
                  PopupMenuItem(value: GroupDetailPage(groupId: groupId), child: const Text('Detalle de la junta')),
                  PopupMenuItem(value: PastPeriodsPage(groupId: groupId), child: const Text('Períodos anteriores')),
                  if (organizer && period?.state == PeriodState.open) ...[
                    PopupMenuItem(value: CashPage(groupId: groupId), child: const Text('Registrar aporte en efectivo')),
                    PopupMenuItem(value: CoverPage(groupId: groupId), child: const Text('Cubrir un aporte')),
                  ],
                  if (organizer && period != null && period.state != PeriodState.delivered)
                    PopupMenuItem(value: ReviewsPage(groupId: groupId), child: const Text('Aportes revisados')),
                ],
              ),
            ],
          ),
          bottomNavigationBar: cycle == null || period == null ? null : _actions(cycle, period),
          body: cycle == null || period == null
              ? LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load)
              : RefreshIndicator(
                  onRefresh: viewModel.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _PotCard(period: period, auctionOpen: state.auction?.isOpen == true),
                      if (state.auction != null) ...[
                        const SizedBox(height: 12),
                        _AuctionEntry(
                          auction: state.auction!,
                          onTap: () => _open(AuctionPage(groupId: groupId)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Estado de los aportes', style: Theme.of(context).textTheme.titleLarge),
                          ),
                          Text(
                            '${period.settledCount} de ${period.membersCount}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final member in period.members)
                        _MemberStateRow(
                          member: member,
                          organizer: organizer,
                          auctionOpen: state.auction?.isOpen == true,
                          photoUrl: state.photos[member.membershipId],
                          onTap: () => _openMember(member, cycle),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget? _actions(Cycle cycle, Period period) {
    final mine = period.myState;
    final canContribute =
        period.state == PeriodState.open && (mine == ContributionState.pending || mine == ContributionState.late);
    final reviews = cycle.isOrganizer && period.inReviewCount > 0;
    final deliver = cycle.isOrganizer && period.state == PeriodState.potComplete;
    if (!canContribute && !reviews && !deliver) return null;
    return BottomActions(
      children: [
        if (deliver)
          PozzoPrimaryButton(
            text: 'Entregar ${Formats.soles(period.payoutAmount)} a ${period.payoutMemberName.split(' ').first}',
            onPressed: () => _open(DeliverPage(groupId: widget.groupId)),
          ),
        if (reviews) ...[
          if (deliver) const SizedBox(height: 8),
          PozzoOutlinedButton(
            text: 'Revisar aportes (${period.inReviewCount})',
            icon: Icons.fact_check_outlined,
            onPressed: () => _open(ReviewsPage(groupId: widget.groupId)),
          ),
        ],
        if (canContribute) ...[
          if (deliver || reviews) const SizedBox(height: 8),
          PozzoPrimaryButton(
            text: 'Registrar mi aporte de ${Formats.soles(period.myAmount)}',
            icon: Icons.upload_outlined,
            onPressed: () => _open(RegisterContributionPage(groupId: widget.groupId)),
          ),
        ],
      ],
    );
  }
}

class _PotCard extends StatelessWidget {
  const _PotCard({required this.period, required this.auctionOpen});

  final Period period;
  final bool auctionOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final onBrand = colors.onPrimaryContainer;
    final who = auctionOpen ? 'Cobra quien gane la subasta' : 'Cobra ${period.payoutMemberName}';
    final missing = switch (period.state) {
      PeriodState.open => 'Faltan ${Formats.soles(period.missingAmount)}',
      PeriodState.potComplete => 'Pozo completo',
      PeriodState.delivered => 'Pozo entregado',
    };
    final days = period.daysToCutoff > 1
        ? 'faltan ${period.daysToCutoff} días'
        : period.daysToCutoff == 1
            ? 'falta 1 día'
            : period.daysToCutoff == 0
                ? 'es hoy'
                : 'venció';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Período ${period.turnNumber} de ${period.totalTurns} · $who',
            style: text.titleSmall?.copyWith(color: onBrand),
          ),
          const SizedBox(height: 8),
          Text(Formats.soles(period.collectedAmount), style: text.displayMedium?.copyWith(color: onBrand)),
          Text('de ${Formats.soles(period.potAmount)} reunidos', style: text.bodyLarge?.copyWith(color: onBrand)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: period.progress,
              minHeight: 8,
              color: onBrand,
              backgroundColor: onBrand.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(missing, style: text.labelLarge?.copyWith(color: onBrand))),
              Text(
                'Corte ${Formats.shortDate(period.cutoffDate)} · $days',
                style: text.labelLarge?.copyWith(color: onBrand),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuctionEntry extends StatelessWidget {
  const _AuctionEntry({required this.auction, required this.onTap});

  final Auction auction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highest = auction.highestBid;
    final detail = !auction.isOpen && auction.winnerName != null
        ? 'Cerrada · cobra ${auction.winnerName}'
        : highest != null
            ? 'Mayor oferta ${Formats.soles(highest.amount)} · cierra el ${Formats.mediumDate(auction.closesOn)}'
            : 'Sin ofertas · cierra el ${Formats.mediumDate(auction.closesOn)}';
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.gavel, color: colors.primary),
        title: const Text('Subasta del turno'),
        subtitle: Text(detail),
        trailing: const Icon(Icons.chevron_right, semanticLabel: 'Ver la subasta'),
      ),
    );
  }
}

class _MemberStateRow extends StatelessWidget {
  const _MemberStateRow({
    required this.member,
    required this.organizer,
    required this.auctionOpen,
    required this.photoUrl,
    required this.onTap,
  });

  final MemberContribution member;
  final bool organizer;
  final bool auctionOpen;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    final reviewSince = member.reviewSince;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            InitialsAvatar(name: member.displayName, size: 40, photoUrl: photoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.isMe ? '${member.displayName} (tú)' : member.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (member.collects && !auctionOpen) Text('Cobra en este período', style: small),
                  if (member.state == ContributionState.inReview)
                    Text(
                      '${organizer ? 'Te toca revisarlo' : 'Lo revisa la cabeza de junta'}'
                      '${reviewSince == null ? '' : ' desde el ${Formats.shortDate(reviewSince.toLocal())}'}',
                      style: small,
                    ),
                ],
              ),
            ),
            ContributionStateChip(state: member.state, isMine: member.isMe),
          ],
        ),
      ),
    );
  }
}
