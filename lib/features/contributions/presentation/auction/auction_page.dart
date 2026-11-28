import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/presentation/auction/auction_view_model.dart';
import 'package:pozzo/features/contributions/presentation/widgets/contribution_widgets.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

/// C10: "Subasta del turno".
class AuctionPage extends StatefulWidget {
  const AuctionPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  late final AuctionViewModel viewModel = getIt<AuctionViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _bid() async {
    final message = await viewModel.bid();
    if (message != null && mounted) showMessage(context, message);
  }

  Future<void> _close(Auction auction) async {
    final organizerChooses = auction.bids.isEmpty && auction.fallback == AuctionFallback.organizer;
    if (organizerChooses) {
      final winner = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => _ChooseWinner(candidates: viewModel.state.candidates, photos: viewModel.state.photos),
      );
      if (winner != null) await viewModel.close(winner);
      return;
    }
    final highest = auction.highestBid;
    final confirmed = await confirmAction(
      context,
      title: '¿Cerrar la subasta ahora?',
      message: highest != null
          ? 'Cobra ${highest.displayName}, con la mayor oferta. Ya no se aceptan más ofertas.'
          : 'Nadie ofertó: el turno se sortea entre quienes aún no cobran, sin descuento.',
      confirmLabel: 'Cerrar',
    );
    if (confirmed) await viewModel.close(null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Subasta del turno')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final auction = state.auction;
          final cycle = state.cycle;
          if (auction == null || cycle == null) {
            return LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load);
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: viewModel.load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _AuctionCard(auction: auction),
                      if (!auction.isOpen && auction.winnerName != null) ...[
                        const SizedBox(height: 12),
                        _AuctionResult(auction: auction),
                      ],
                      const SectionTitle('Ofertas'),
                      if (auction.bids.isEmpty)
                        InfoBanner(
                          text: auction.isOpen
                              ? 'Aún no hay ofertas. Quien no ha cobrado puede ofrecer un descuento desde '
                                  '${Formats.soles(auction.minimumBid)}.'
                              : 'Nadie ofertó en esta subasta.',
                        ),
                      for (var i = 0; i < auction.bids.length; i++)
                        _BidRow(
                          bid: auction.bids[i],
                          highest: i == 0,
                          isMe: auction.bids[i].membershipId == cycle.myMembershipId,
                          photoUrl: state.photos[auction.bids[i].membershipId],
                        ),
                    ],
                  ),
                ),
              ),
              BottomActions(
                children: [
                  if (auction.isOpen && auction.canBid) ...[
                    PozzoTextField(
                      label: auction.myBid == null
                          ? 'Tu oferta de descuento'
                          : 'Mejora tu oferta (ahora ${Formats.soles(auction.myBid!)})',
                      value: state.bid,
                      onChanged: viewModel.onBidChanged,
                      prefix: 'S/',
                      placeholder: Formats.plainAmount(auction.minimumBid),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      supportingText: state.bidValue != null
                          ? 'Recibirías ${Formats.soles(auction.potAmount - state.bidValue!)} si ganas.'
                          : 'Mínimo ${Formats.soles(auction.minimumBid)} y menos que el pozo de '
                              '${Formats.soles(auction.potAmount)}.',
                      errorText: state.errorMessage,
                    ),
                    const SizedBox(height: 8),
                    PozzoPrimaryButton(
                      text: auction.myBid == null ? 'Ofertar' : 'Mejorar oferta',
                      icon: Icons.gavel,
                      onPressed: _bid,
                      enabled: state.bidValue != null,
                      loading: state.isBidding,
                    ),
                  ] else if (auction.isOpen && !cycle.isOrganizer)
                    Text(
                      'Ya cobraste en este ciclo, así que no puedes ofertar. Puedes seguir la subasta.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  if (cycle.isOrganizer && auction.isOpen) ...[
                    if (!auction.canBid) ErrorText(state.errorMessage),
                    const SizedBox(height: 8),
                    PozzoOutlinedButton(
                      text: state.isClosing ? 'Cerrando…' : 'Cerrar la subasta',
                      icon: Icons.lock_clock_outlined,
                      enabled: !state.isClosing,
                      onPressed: () => _close(auction),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final onBrand = colors.onPrimaryContainer;
    final highest = auction.highestBid;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turno ${auction.turnNumber} · Pozo ${Formats.soles(auction.potAmount)}',
            style: text.titleSmall?.copyWith(color: onBrand),
          ),
          Text(
            highest == null ? 'Sin ofertas' : Formats.soles(highest.amount),
            style: text.displaySmall?.copyWith(color: onBrand),
          ),
          Text(
            highest != null
                ? 'mayor oferta, de ${highest.displayName}'
                : 'oferta mínima ${Formats.soles(auction.minimumBid)}',
            style: text.bodyLarge?.copyWith(color: onBrand),
          ),
          const SizedBox(height: 8),
          Text(
            auction.isOpen ? 'Abierta hasta el ${Formats.mediumDate(auction.closesOn)}' : 'Cerrada',
            style: text.labelLarge?.copyWith(color: onBrand),
          ),
        ],
      ),
    );
  }
}

class _AuctionResult extends StatelessWidget {
  const _AuctionResult({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final how = switch (auction.resolution) {
      AuctionResolution.bid =>
        'con la mayor oferta, de ${auction.discount == null ? '' : Formats.soles(auction.discount!)}',
      AuctionResolution.draw => 'por sorteo, porque nadie ofertó',
      AuctionResolution.organizer => 'elegido por la cabeza, porque nadie ofertó',
      null => '',
    };
    final receives = auction.payoutAmount == null ? '' : Formats.soles(auction.payoutAmount!);
    return InfoBanner(text: 'Cobra ${auction.winnerName} $how. Recibe $receives.', icon: Icons.emoji_events_outlined);
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({required this.bid, required this.highest, required this.isMe, required this.photoUrl});

  final AuctionBid bid;
  final bool highest;
  final bool isMe;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final status = PozzoStatusColors.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: InitialsAvatar(name: bid.displayName, size: 40, photoUrl: photoUrl),
      title: Text(isMe ? '${bid.displayName} (tú)' : bid.displayName),
      subtitle: Text('Ofrece ${Formats.soles(bid.amount)} · recibiría ${Formats.soles(bid.receives)}'),
      trailing: highest
          ? StatusChip(text: 'Mayor', background: status.successContainer, foreground: status.onSuccessContainer)
          : null,
    );
  }
}

class _ChooseWinner extends StatefulWidget {
  const _ChooseWinner({required this.candidates, required this.photos});

  final List<Turn> candidates;
  final Map<String, String> photos;

  @override
  State<_ChooseWinner> createState() => _ChooseWinnerState();
}

class _ChooseWinnerState extends State<_ChooseWinner> {
  String? winner;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Quién cobra este turno?', style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Nadie ofertó. Elige entre quienes aún no cobran; recibe el pozo completo.',
              style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final turn in widget.candidates)
              MemberOption(
                name: turn.displayName,
                isMe: turn.isMe,
                selected: winner == turn.membershipId,
                photoUrl: widget.photos[turn.membershipId],
                onTap: () => setState(() => winner = turn.membershipId),
              ),
            const SizedBox(height: 16),
            PozzoPrimaryButton(
              text: 'Dar el turno',
              enabled: winner != null,
              onPressed: () => Navigator.pop(context, winner),
            ),
          ],
        ),
      ),
    );
  }
}
