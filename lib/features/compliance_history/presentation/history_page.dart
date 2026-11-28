import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/compliance_history/domain/compliance.dart';
import 'package:pozzo/features/compliance_history/presentation/history_view_models.dart';
import 'package:pozzo/features/compliance_history/presentation/my_history_page.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';

/// H1: "Historial", the second tab. Without started groups it shows the history of the member.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryViewModel viewModel = getIt<HistoryViewModel>();
  int tab = 0;

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        if (state.isResolving) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!state.hasGroups) return const MyHistoryPage(showBack: false);
        return _groupHistory(state);
      },
    );
  }

  String _subtitle(Cycle? cycle, Period? current) {
    if (cycle == null) return '';
    if (!cycle.isActive) return 'Ciclo completado · ${cycle.totalTurns} períodos';
    if (current == null) return 'Período ${cycle.currentTurn} de ${cycle.totalTurns}';
    return 'Período ${current.turnNumber} de ${current.totalTurns} · Corte ${Formats.shortDate(current.cutoffDate)}';
  }

  Widget _groupHistory(HistoryState state) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final showsMembers = state.showsMembers && tab == 1;
    final cycle = state.cycle;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          PopupMenuButton<HistoryRole>(
            tooltip: 'Ver juntas como cabeza o participante',
            icon: const Icon(Icons.person_outline),
            onSelected: (role) {
              if (role == state.role) return;
              setState(() => tab = 0);
              viewModel.selectRole(role);
            },
            itemBuilder: (context) => [
              for (final role in HistoryRole.values)
                PopupMenuItem(
                  value: role,
                  enabled: state.groupsOf(role).isNotEmpty,
                  child: ListTile(
                    leading: role == state.role ? const Icon(Icons.check) : const SizedBox(width: 24),
                    title: Text(switch (state.groupsOf(role).length) {
                      0 => '${role.label} (sin juntas)',
                      1 => '${role.label} · 1 junta',
                      final count => '${role.label} · $count juntas',
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: [
          PozzoOutlinedButton(
            text: 'Ver y compartir mi historial',
            icon: Icons.ios_share,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyHistoryPage(showBack: true)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Como ${state.role.label.toLowerCase()}', style: text.labelLarge?.copyWith(color: colors.primary)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.selectedGroup?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineSmall,
                      ),
                      Text(
                        _subtitle(cycle, state.periods.lastOrNull),
                        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (state.groups.length > 1)
                  PopupMenuButton<String>(
                    tooltip: 'Elegir otra junta',
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onSelected: viewModel.select,
                    itemBuilder: (context) => [
                      for (final group in state.groups)
                        PopupMenuItem(
                          value: group.id,
                          child: Text(group.isClosed ? '${group.name} (cerrada)' : group.name),
                        ),
                    ],
                  ),
              ],
            ),
            if (state.showsMembers) ...[
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Aportes')),
                  ButtonSegment(value: 1, label: Text('Integrantes')),
                ],
                selected: {tab},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => setState(() => tab = selection.first),
              ),
            ],
            Expanded(
              child: cycle == null
                  ? LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load)
                  : RefreshIndicator(
                      onRefresh: viewModel.load,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: showsMembers
                            ? [for (final member in state.members) _MemberCompliance(member: member, photos: state.photos)]
                            : _matrix(cycle, state.periods, state.photos),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _matrix(Cycle cycle, List<Period> periods, Map<String, String> photos) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final members = periods.lastOrNull?.members ?? const <MemberContribution>[];
    final byTurn = {for (final period in periods) period.turnNumber: period};
    final currentTurn = cycle.isActive ? cycle.currentTurn : null;
    const cell = 32.0;
    final current = periods.lastOrNull;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: cell),
                  for (final member in members)
                    SizedBox(
                      height: cell + 8,
                      width: 120,
                      child: Row(
                        children: [
                          InitialsAvatar(name: member.displayName, size: 28, photoUrl: photos[member.membershipId]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              member.displayName.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var turn = 1; turn <= cycle.totalTurns; turn++)
                        Container(
                          width: cell,
                          decoration: BoxDecoration(
                            color: turn == currentTurn ? colors.secondaryContainer : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: cell,
                                child: Center(
                                  child: Text(
                                    '$turn',
                                    style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              for (final member in members)
                                SizedBox(
                                  height: cell + 8,
                                  child: Center(
                                    child: _StateMark(
                                      state: byTurn[turn]
                                          ?.members
                                          .where((m) => m.membershipId == member.membershipId)
                                          .firstOrNull
                                          ?.state,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          for (final (state, label) in const [
            (ContributionState.validated, 'Validado'),
            (ContributionState.inReview, 'Revisión'),
            (ContributionState.pending, 'Pendiente'),
            (ContributionState.late, 'Atrasado'),
            (ContributionState.covered, 'Cubierto'),
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StateMark(state: state),
                const SizedBox(width: 4),
                Text(label, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
        ],
      ),
      if (current != null && current.state != PeriodState.delivered) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            _Figure(label: 'Validados', value: '${current.settledCount} de ${current.membersCount}'),
            _Figure(label: 'Por revisar', value: '${current.inReviewCount}'),
            _Figure(label: 'Pendientes', value: '${current.unsettled.length}'),
          ],
        ),
      ],
    ];
  }
}

class _StateMark extends StatelessWidget {
  const _StateMark({required this.state});

  final ContributionState? state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    return switch (state) {
      null => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: colors.outlineVariant, shape: BoxShape.circle),
        ),
      ContributionState.validated => Icon(Icons.check_circle, size: 20, color: status.success, semanticLabel: 'Validado'),
      ContributionState.inReview =>
        Icon(Icons.hourglass_top, size: 20, color: status.onWarningContainer, semanticLabel: 'En revisión'),
      ContributionState.pending =>
        Icon(Icons.schedule, size: 20, color: colors.onSurfaceVariant, semanticLabel: 'Pendiente'),
      ContributionState.late => Icon(Icons.warning_amber, size: 20, color: colors.error, semanticLabel: 'Atrasado'),
      ContributionState.covered =>
        Icon(Icons.volunteer_activism_outlined, size: 20, color: colors.onSurfaceVariant, semanticLabel: 'Cubierto'),
    };
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: text.headlineMedium),
        ],
      ),
    );
  }
}

class _MemberCompliance extends StatelessWidget {
  const _MemberCompliance({required this.member, required this.photos});

  final MemberCompliance member;
  final Map<String, String> photos;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final summary = member.summary;
    final manual = !member.usesApp || summary == null;
    String onTime(ComplianceSummary summary) => summary.contributions == 0
        ? 'Aún sin aportes'
        : '${summary.onTime} de ${summary.contributions} puntuales';
    final detail = manual
        ? 'Sin la app · lo registras tú'
        : member.isOrganizer
            ? 'Cabeza · ${onTime(summary)}'
            : onTime(summary);
    final Widget chip;
    if (manual) {
      chip = StatusChip(text: 'Manual', background: colors.surfaceContainerHighest, foreground: colors.onSurfaceVariant);
    } else {
      final punctuality = summary.punctuality;
      if (punctuality == null) {
        chip = StatusChip(text: 'Nuevo', background: colors.surfaceContainerHighest, foreground: colors.onSurfaceVariant);
      } else if (punctuality >= 90) {
        chip = StatusChip(
          text: '$punctuality %',
          background: status.successContainer,
          foreground: status.onSuccessContainer,
        );
      } else if (punctuality >= 75) {
        chip = StatusChip(
          text: '$punctuality %',
          background: status.warningContainer,
          foreground: status.onWarningContainer,
        );
      } else {
        chip = StatusChip(text: '$punctuality %', background: colors.errorContainer, foreground: colors.onErrorContainer);
      }
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: InitialsAvatar(name: member.displayName, photoUrl: photos[member.membershipId]),
      title: Text(member.displayName),
      subtitle: Text(detail),
      trailing: chip,
    );
  }
}
