import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/contributions/presentation/calendar/swap_turns_page.dart';
import 'package:pozzo/features/contributions/presentation/calendar/turn_calendar_view_model.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

enum _TurnKind { collected, current, mine, pending, auction }

/// C4: "Calendario de turnos".
class TurnCalendarPage extends StatefulWidget {
  const TurnCalendarPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<TurnCalendarPage> createState() => _TurnCalendarPageState();
}

class _TurnCalendarPageState extends State<TurnCalendarPage> {
  late final TurnCalendarViewModel viewModel = getIt<TurnCalendarViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _swap() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => SwapTurnsPage(groupId: widget.groupId)));
    viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final cycle = state.cycle;
        final calendar = state.calendar;
        final auctioned = calendar?.method == TurnMethod.auction;
        final notStarted =
            cycle == null ? 0 : (calendar?.turns ?? []).where((turn) => turn.turnNumber > cycle.currentTurn).length;
        final canSwap = cycle != null && cycle.isOrganizer && cycle.isActive && !auctioned && notStarted >= 2;
        return Scaffold(
          appBar: AppBar(title: const Text('Calendario de turnos')),
          bottomNavigationBar: canSwap
              ? BottomActions(
                  children: [
                    PozzoOutlinedButton(text: 'Intercambiar turnos', icon: Icons.swap_vert, onPressed: _swap),
                  ],
                )
              : null,
          body: cycle == null || calendar == null
              ? LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${cycle.groupName} · ${cycle.totalTurns} períodos · Pozo ${Formats.soles(cycle.potAmount)} '
                      'por turno',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    if (auctioned) ...[
                      const SizedBox(height: 12),
                      const InfoBanner(
                        text: 'Los turnos se subastan: quién cobra en cada período se decide en su subasta.',
                      ),
                    ],
                    const SizedBox(height: 12),
                    for (final turn in calendar.turns)
                      Builder(
                        builder: (context) {
                          final collected = !cycle.isActive || turn.turnNumber < cycle.currentTurn;
                          final current = cycle.isActive && turn.turnNumber == cycle.currentTurn;
                          final toAuction = auctioned && !collected && !current;
                          final winner = auctioned ? state.winners[turn.turnNumber] : null;
                          final String name;
                          if (toAuction) {
                            name = 'Por subastar';
                          } else if (auctioned && current && winner == null) {
                            name = 'En subasta';
                          } else if (winner != null) {
                            name = winner;
                          } else {
                            name = turn.isMe ? '${turn.displayName} (tú)' : turn.displayName;
                          }
                          final kind = collected
                              ? _TurnKind.collected
                              : current
                                  ? _TurnKind.current
                                  : toAuction
                                      ? _TurnKind.auction
                                      : turn.isMe
                                          ? _TurnKind.mine
                                          : _TurnKind.pending;
                          return _TurnCalendarRow(
                            number: turn.turnNumber,
                            name: name,
                            date: Formats.mediumDate(turn.cutoffDate),
                            kind: kind,
                          );
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _TurnCalendarRow extends StatelessWidget {
  const _TurnCalendarRow({required this.number, required this.name, required this.date, required this.kind});

  final int number;
  final String name;
  final String date;
  final _TurnKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    final (badge, onBadge) = switch (kind) {
      _TurnKind.collected => (status.successContainer, status.onSuccessContainer),
      _TurnKind.current => (colors.primary, colors.onPrimary),
      _ => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
    final Widget trailing = switch (kind) {
      _TurnKind.collected =>
        StatusChip(text: 'Cobró', background: status.successContainer, foreground: status.onSuccessContainer),
      _TurnKind.current => Text('Vigente', style: text.labelLarge?.copyWith(color: colors.onSecondaryContainer)),
      _TurnKind.mine =>
        StatusChip(text: 'Tu turno', background: colors.tertiaryContainer, foreground: colors.onTertiaryContainer),
      _TurnKind.pending =>
        StatusChip(text: 'Pendiente', background: colors.surfaceContainerHighest, foreground: colors.onSurfaceVariant),
      _TurnKind.auction =>
        StatusChip(text: 'Subasta', background: colors.tertiaryContainer, foreground: colors.onTertiaryContainer),
    };
    final highlighted = kind == _TurnKind.current;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? colors.secondaryContainer : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: badge,
            child: Text('$number', style: text.labelLarge?.copyWith(color: onBadge)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleMedium),
                Text(date, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
