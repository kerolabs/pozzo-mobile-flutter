import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/contributions/presentation/pot/pot_page.dart';
import 'package:pozzo/features/iam/infrastructure/local/session_manager.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/create_group/create_group_page.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_page.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/join_code_page.dart';
import 'package:pozzo/features/savings_groups/presentation/my_groups/my_groups_view_model.dart';

/// G1: "Mis juntas", the first tab.
class MyGroupsPage extends StatefulWidget {
  const MyGroupsPage({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  State<MyGroupsPage> createState() => _MyGroupsPageState();
}

class _MyGroupsPageState extends State<MyGroupsPage> {
  final MyGroupsViewModel viewModel = getIt<MyGroupsViewModel>();
  final SessionManager session = getIt<SessionManager>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // While a group waits for its members, the list is read again every 20 seconds.
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (viewModel.state.waitingToStart) viewModel.refreshQuietly();
    });
    viewModel.addListener(_showError);
  }

  @override
  void dispose() {
    _timer?.cancel();
    viewModel.removeListener(_showError);
    viewModel.dispose();
    super.dispose();
  }

  void _showError() {
    final error = viewModel.state.errorMessage;
    if (error == null || !mounted) return;
    viewModel.dismissError();
    showMessage(context, error);
  }

  /// Opens a page and reads the list again when the member comes back.
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    viewModel.refreshQuietly();
  }

  void _openGroup(SavingsGroup group) {
    _open(group.status == GroupStatus.started ? PotPage(groupId: group.id) : GroupDetailPage(groupId: group.id));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, session]),
      builder: (context, child) {
        final state = viewModel.state;
        return Scaffold(
          floatingActionButton: state.groups.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _open(const CreateGroupPage()),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear junta'),
                ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: viewModel.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _Header(
                    displayName: session.displayName ?? '',
                    photoUrl: session.photoUrl,
                    onOpenProfile: widget.onOpenProfile,
                  ),
                  const SizedBox(height: 16),
                  if (!state.loadedOnce && state.isRefreshing)
                    const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                  else if (state.showEmptyState)
                    _EmptyGroups(
                      onCreate: () => _open(const CreateGroupPage()),
                      onJoin: () => _open(const JoinCodePage()),
                    )
                  else ...[
                    for (final group in state.groups) ...[
                      _GroupCard(group: group, onTap: () => _openGroup(group)),
                      const SizedBox(height: 16),
                    ],
                    if (state.groups.isNotEmpty)
                      PozzoOutlinedButton(
                        text: 'Unirme con un código',
                        icon: Icons.key_outlined,
                        onPressed: () => _open(const JoinCodePage()),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.displayName, required this.photoUrl, required this.onOpenProfile});

  final String displayName;
  final String? photoUrl;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final firstName = displayName.trim().split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (firstName.isNotEmpty)
                Text('Hola, $firstName', style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
              Text('Mis juntas', style: text.headlineLarge),
            ],
          ),
        ),
        Tooltip(
          message: 'Ver mi perfil',
          child: GestureDetector(
            onTap: onOpenProfile,
            child: InitialsAvatar(
              name: displayName.trim().isEmpty ? '?' : displayName,
              size: 56,
              background: colors.primaryContainer,
              foreground: colors.onPrimaryContainer,
              photoUrl: photoUrl,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final SavingsGroup group;
  final VoidCallback onTap;

  String get _summary {
    switch (group.status) {
      case GroupStatus.started:
      case GroupStatus.closed:
        final turn = group.myTurnNumber;
        final date = group.myTurnDate;
        if (turn != null && date != null) return 'Te toca cobrar en el turno $turn, el ${Formats.shortDate(date)}.';
        return '${group.seats} integrantes.';
      case GroupStatus.draft:
      case GroupStatus.ready:
        if (!group.readiness.groupFull) {
          final missing = group.seats - group.membersCount;
          final rest = missing == 1 ? 'Falta 1 para iniciar.' : 'Faltan $missing para iniciar.';
          return '${group.membersCount} de ${group.seats} integrantes. $rest';
        }
        if (!group.readiness.turnsAssigned) return 'Grupo completo. Falta definir los turnos para iniciar.';
        if (!group.readiness.destinationDefined) return 'Falta definir a dónde se envían los aportes.';
        return 'Todo listo para iniciar.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    final organizer = group.isOrganizer;
    final container = organizer ? colors.primaryContainer : colors.surfaceContainerLow;
    final content = organizer ? colors.onPrimaryContainer : colors.onSurface;
    final secondary = organizer ? colors.onPrimaryContainer.withValues(alpha: 0.85) : colors.onSurfaceVariant;
    final (statusLabel, statusBg, statusFg) = switch (group.status) {
      GroupStatus.started => ('En curso', status.successContainer, status.onSuccessContainer),
      GroupStatus.closed => ('Cerrada', colors.surfaceContainerHighest, colors.onSurfaceVariant),
      _ => ('Por iniciar', status.warningContainer, status.onWarningContainer),
    };
    return Material(
      color: container,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: organizer ? container : colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(group.name, style: text.headlineSmall?.copyWith(color: content))),
                  Icon(Icons.chevron_right, color: content),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (organizer)
                    StatusChip(
                      text: 'Cabeza de junta',
                      background: colors.surface,
                      foreground: colors.primary,
                      icon: Icons.star_outline,
                    )
                  else
                    StatusChip(
                      text: 'Participante',
                      background: colors.surfaceContainerHighest,
                      foreground: colors.onSurfaceVariant,
                    ),
                  StatusChip(text: statusLabel, background: statusBg, foreground: statusFg),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aporte ${group.periodicity.adjective}',
                          style: text.bodyMedium?.copyWith(color: secondary),
                        ),
                        Text(
                          Formats.soles(group.contributionAmount),
                          style: text.headlineSmall?.copyWith(color: content),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Pozo por turno', style: text.bodyMedium?.copyWith(color: secondary)),
                      Text(Formats.soles(group.potAmount), style: text.headlineSmall?.copyWith(color: content)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_summary, style: text.bodyLarge?.copyWith(color: secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.onCreate, required this.onJoin});

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(color: colors.secondaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.groups_outlined, size: 72, color: colors.secondary),
            ),
          ),
          const SizedBox(height: 32),
          Text('Aún no tienes juntas', textAlign: TextAlign.center, style: text.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Crea una junta para tu grupo o únete con el código que te compartió tu cabeza de junta.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          PozzoPrimaryButton(text: 'Crear una junta', icon: Icons.add, onPressed: onCreate),
          const SizedBox(height: 12),
          PozzoOutlinedButton(text: 'Unirme con un código', icon: Icons.key_outlined, onPressed: onJoin),
        ],
      ),
    );
  }
}
