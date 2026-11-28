import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/contributions/presentation/periods/past_periods_page.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/create_group/create_group_page.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_state.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_view_model.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/member_profile_sheet.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/invitation_page.dart';
import 'package:pozzo/features/savings_groups/presentation/turns/turns_pages.dart';
import 'package:pozzo/features/savings_groups/presentation/widgets/readiness_checklist.dart';
import 'package:pozzo/features/savings_groups/presentation/widgets/turn_row.dart';

/// G7: the detail of a group before it starts, or after it closes.
class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late final GroupDetailViewModel viewModel = getIt<GroupDetailViewModel>(param1: widget.groupId);
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // While the group waits for its members, it is read again every 15 seconds.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      final group = viewModel.state.group;
      if (group != null && !group.isStarted && !viewModel.state.isBusy) viewModel.load();
    });
    viewModel.addListener(_onChange);
  }

  @override
  void dispose() {
    _timer?.cancel();
    viewModel.removeListener(_onChange);
    viewModel.dispose();
    super.dispose();
  }

  /// The group was deleted or the member is no longer part of it: the page closes once.
  void _onChange() {
    if (!viewModel.state.closed || _leaving || !mounted) return;
    _leaving = true;
    Navigator.pop(context);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    viewModel.load();
  }

  Future<void> _invite(SavingsGroup group) async {
    try {
      final invitation = await viewModel.invitation();
      if (!mounted) return;
      await _open(InvitationPage(group: group, invitation: invitation, fromDetail: true));
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  Future<void> _delete(SavingsGroup group) async {
    final confirmed = await confirmAction(
      context,
      title: '¿Eliminar ${group.name}?',
      message: 'Se borran sus integrantes, sus turnos y su invitación. A quienes usan Pozzo les llegará un aviso. '
          'No se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmed) await viewModel.delete();
  }

  Future<void> _newCycle() async {
    final today = Formats.today();
    final date = await showDatePicker(
      context: context,
      initialDate: Formats.plusMonths(today, 1),
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      helpText: 'Primer aporte del nuevo ciclo',
      cancelText: 'Cancelar',
      confirmText: 'Abrir ciclo',
    );
    if (date == null || !mounted) return;
    final confirmed = await confirmAction(
      context,
      title: 'Abrir un nuevo ciclo',
      message: 'Se crea una junta nueva con las mismas reglas, destino e integrantes, por iniciar, con primer aporte '
          'el ${Formats.mediumDate(date)}. Podrás ajustarla, asignar los turnos e iniciarla como siempre.',
      confirmLabel: 'Abrir ciclo',
    );
    if (!confirmed) return;
    try {
      final group = await viewModel.newCycle(date);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GroupDetailPage(groupId: group.id)));
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  Future<void> _remove(Member member) async {
    viewModel.hide(member);
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.displayName} ya no es parte de la junta.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Deshacer', onPressed: () {}),
      ),
    );
    final reason = await controller.closed;
    if (reason == SnackBarClosedReason.action) {
      viewModel.undoRemove();
      return;
    }
    final error = await viewModel.confirmRemove(member);
    if (error != null && mounted) showMessage(context, error);
  }

  Future<void> _dropout(Member member) async {
    final confirmed = await confirmAction(
      context,
      title: '¿${member.displayName} dejó la junta?',
      message: 'Queda en su historial de cumplimiento y deja de recibir recordatorios. Su turno queda libre para que '
          'asignes a alguien en su lugar.',
      confirmLabel: 'Registrar deserción',
      destructive: true,
    );
    if (!confirmed) return;
    final message = await viewModel.dropout(member);
    if (mounted) showMessage(context, message);
  }

  void _openMember(Member member, GroupDetailState state) {
    final group = state.group!;
    final actions = <Widget>[
      if (state.canEdit && !member.isOrganizer)
        PozzoOutlinedButton(
          text: 'Quitar de la junta',
          icon: Icons.person_remove_outlined,
          onPressed: () {
            Navigator.pop(context);
            _remove(member);
          },
        ),
      if (group.isOrganizer && group.status == GroupStatus.started && !member.isOrganizer)
        PozzoOutlinedButton(
          text: 'Registrar deserción',
          icon: Icons.person_off_outlined,
          onPressed: () {
            Navigator.pop(context);
            _dropout(member);
          },
        ),
    ];
    showMemberProfile(context, member, actions: actions);
  }

  Future<void> _addMember() async {
    final added = await showPersonForm(
      context,
      title: 'Agregar sin la aplicación',
      message: 'Para quien no instalará Pozzo o aporta en efectivo. Tú registras sus aportes.',
      action: 'Agregar a la junta',
      onSave: viewModel.addMember,
    );
    if (added != null && mounted) showMessage(context, '$added se agregó a la junta.');
  }

  Future<void> _replace(Turn turn) async {
    final added = await showPersonForm(
      context,
      title: 'Reemplazo en el turno ${turn.turnNumber}',
      message: 'Toma el lugar de ${turn.displayName} y debe lo que quedó pendiente del período en curso. Si su '
          'celular ya usa Pozzo, se une con su cuenta; si no, tú registras sus aportes.',
      action: 'Asignar reemplazo',
      onSave: (name, phone) => viewModel.replace(turn, name, phone),
    );
    if (added != null && mounted) showMessage(context, '$added ocupa el turno ${turn.turnNumber}.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final detail = state.detail;
        final group = detail?.group;
        return Scaffold(
          appBar: AppBar(
            title: Text(group?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              if (state.canEdit)
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (option) {
                    switch (option) {
                      case 'edit':
                        _open(CreateGroupPage(editingGroupId: widget.groupId));
                      case 'invite':
                        _invite(group!);
                      case 'delete':
                        _delete(group!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar junta')),
                    ),
                    const PopupMenuItem(
                      value: 'invite',
                      child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Invitar integrantes')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        title: Text('Eliminar junta', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          floatingActionButton: state.canEdit &&
                  detail != null &&
                  !detail.group.readiness.groupFull &&
                  state.tab == GroupDetailTab.members
              ? FloatingActionButton.extended(
                  onPressed: _addMember,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Agregar'),
                )
              : null,
          bottomNavigationBar: detail == null ? null : _bottomActions(state, detail),
          body: detail == null
              ? LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load)
              : RefreshIndicator(onRefresh: viewModel.load, child: _content(state, detail)),
        );
      },
    );
  }

  Widget? _bottomActions(GroupDetailState state, GroupDetail detail) {
    final group = detail.group;
    if (group.status == GroupStatus.closed) {
      return BottomActions(
        children: [
          PozzoOutlinedButton(
            text: 'Ver los períodos del ciclo',
            onPressed: () => _open(PastPeriodsPage(groupId: widget.groupId)),
          ),
          if (group.isOrganizer) ...[
            const SizedBox(height: 8),
            PozzoPrimaryButton(text: 'Abrir un nuevo ciclo', onPressed: _newCycle, loading: state.isBusy),
          ],
        ],
      );
    }
    if (!state.canEdit) return null;
    final readiness = group.readiness;
    final Widget action;
    if (!readiness.groupFull) {
      action = PozzoPrimaryButton(text: 'Invitar integrantes', onPressed: () => _invite(group));
    } else if (!readiness.turnsAssigned) {
      action = PozzoPrimaryButton(
        text: 'Asignar turnos',
        onPressed: () => _open(AssignTurnsPage(groupId: widget.groupId, seats: group.seats)),
      );
    } else {
      action = PozzoPrimaryButton(
        text: 'Iniciar la junta',
        enabled: readiness.canStart,
        onPressed: () => _open(StartGroupPage(groupId: widget.groupId)),
      );
    }
    return BottomActions(children: [action]);
  }

  Widget _content(GroupDetailState state, GroupDetail detail) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    final group = detail.group;
    final (label, bg, fg) = switch (group.status) {
      GroupStatus.started => ('En curso', status.successContainer, status.onSuccessContainer),
      GroupStatus.closed => ('Cerrada', colors.surfaceContainerHighest, colors.onSurfaceVariant),
      _ => ('Por iniciar', status.warningContainer, status.onWarningContainer),
    };
    final destination = group.destination;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip(text: label, background: bg, foreground: fg),
            Text(
              '${Formats.soles(group.contributionAmount)} · ${group.periodicity.title} · '
              '${GroupLabels.shortCutoff(group.periodicity, group.firstContributionDate)}',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        if (!group.isStarted) ...[
          const SizedBox(height: 16),
          ReadinessChecklist(
            title: 'Para iniciar la junta',
            items: [
              ChecklistItem(
                done: group.readiness.groupFull,
                title: 'Grupo completo',
                detail: '${detail.members.length} de ${group.seats} integrantes',
              ),
              ChecklistItem(
                done: group.readiness.turnsAssigned,
                title: 'Turnos definidos',
                detail: group.readiness.turnsAssigned
                    ? GroupLabels.turnMethod(group.turnMethod)
                    : 'Falta elegir cómo se reparte el orden',
              ),
              ChecklistItem(
                done: group.readiness.destinationDefined,
                title: 'Destino de los aportes',
                detail: destination == null
                    ? 'Falta definir a dónde se envían los aportes'
                    : '${destination.method.label} · ${PhoneNumbers.grouped(destination.phoneNumber)}',
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SegmentedButton<GroupDetailTab>(
          segments: [
            for (final tab in GroupDetailTab.values) ButtonSegment(value: tab, label: Text(tab.label)),
          ],
          selected: {state.tab},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => viewModel.selectTab(selection.first),
        ),
        const SizedBox(height: 8),
        if (state.tab == GroupDetailTab.members) ..._members(state, detail) else ..._rules(group),
      ],
    );
  }

  List<Widget> _members(GroupDetailState state, GroupDetail detail) {
    final colors = Theme.of(context).colorScheme;
    final group = detail.group;
    final visible = detail.members.where((member) => member.membershipId != state.hiddenMember).toList();
    if (detail.turns.turns.isEmpty) {
      return [
        for (final member in visible) _MemberRow(member: member, onTap: () => _openMember(member, state)),
        if (!group.isStarted)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'La cabeza de junta define los turnos cuando el grupo está completo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
      ];
    }
    final membersById = {for (final member in detail.members) member.membershipId: member};
    final withTurn = detail.turns.turns.map((turn) => turn.membershipId).toSet();
    return [
      for (final turn in detail.turns.turns.where((turn) => turn.membershipId != state.hiddenMember))
        Builder(
          builder: (context) {
            final member = membersById[turn.membershipId];
            final dropped = group.isStarted && member == null;
            return InkWell(
              onTap: () {
                if (dropped && group.isOrganizer && group.status == GroupStatus.started) {
                  _replace(turn);
                } else if (member != null) {
                  _openMember(member, state);
                }
              },
              child: TurnRow(
                turnNumber: turn.turnNumber,
                name: turn.isMe ? '${turn.displayName} (tú)' : turn.displayName,
                cutoffDate: turn.cutoffDate,
                highlighted: turn.isMe,
                subtitle: dropped ? 'Dejó la junta · falta un reemplazo' : null,
                trailing: dropped
                    ? StatusChip(text: 'Desertó', background: colors.errorContainer, foreground: colors.onErrorContainer)
                    : member == null
                        ? null
                        : _MemberKindChip(member: member),
              ),
            );
          },
        ),
      for (final member in visible.where((member) => !withTurn.contains(member.membershipId)))
        _MemberRow(member: member, onTap: () => _openMember(member, state)),
      if (state.canEdit) ...[
        const SizedBox(height: 12),
        PozzoOutlinedButton(
          text: 'Cambiar turnos',
          onPressed: () => _open(AssignTurnsPage(groupId: widget.groupId, seats: group.seats)),
        ),
      ],
    ];
  }

  List<Widget> _rules(SavingsGroup group) {
    final colors = Theme.of(context).colorScheme;
    final destination = group.destination;
    return [
      if (!group.isOrganizer)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              StatusChip(
                text: 'Solo lectura',
                background: colors.surfaceContainerHighest,
                foreground: colors.onSurfaceVariant,
                icon: Icons.visibility_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Las administra la cabeza de la junta.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      SummaryCard(
        rows: [
          ('Aporte por integrante', Formats.soles(group.contributionAmount)),
          ('Periodicidad', group.periodicity.title),
          ('Integrantes', '${group.seats}'),
          ('Pozo por turno', Formats.soles(group.potAmount)),
          ('Día de corte', GroupLabels.cutoff(group.periodicity, group.firstContributionDate)),
          ('Primer aporte', Formats.mediumDate(group.firstContributionDate)),
          if (destination != null)
            ('Destino', '${destination.method.label} · ${PhoneNumbers.grouped(destination.phoneNumber)}'),
          ('Turnos', GroupLabels.turnMethod(group.turnMethod)),
          ('Plan', group.plan == GroupPlan.paid ? 'De pago' : 'Gratuito'),
        ],
      ),
    ];
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: InitialsAvatar(name: member.displayName, photoUrl: member.photoUrl),
      title: Text(member.isMe ? '${member.displayName} (tú)' : member.displayName),
      subtitle: member.phoneNumber == null ? null : Text(PhoneNumbers.display(member.phoneNumber!)),
      trailing: _MemberKindChip(member: member),
    );
  }
}

class _MemberKindChip extends StatelessWidget {
  const _MemberKindChip({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    if (member.isOrganizer) {
      return StatusChip(text: 'Cabeza', background: colors.secondaryContainer, foreground: colors.onSecondaryContainer);
    }
    if (member.kind == MembershipKind.app) {
      return StatusChip(text: 'Usa Pozzo', background: colors.surfaceContainerHighest, foreground: colors.onSurfaceVariant);
    }
    return StatusChip(text: 'Sin la app', background: status.warningContainer, foreground: status.onWarningContainer);
  }
}

/// A form for a person without the app: name and optional phone. [onSave] returns null when it worked,
/// or the error to show. Returns the name saved, or null when the organizer cancelled.
Future<String?> showPersonForm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  required Future<String?> Function(String name, String phone) onSave,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _PersonForm(title: title, message: message, action: action, onSave: onSave),
  );
}

class _PersonForm extends StatefulWidget {
  const _PersonForm({required this.title, required this.message, required this.action, required this.onSave});

  final String title;
  final String message;
  final String action;
  final Future<String?> Function(String name, String phone) onSave;

  @override
  State<_PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<_PersonForm> {
  String name = '';
  String phone = '';
  bool saving = false;
  String? error;

  bool get canSave => name.trim().isNotEmpty && (phone.isEmpty || PhoneNumbers.isValid(phone)) && !saving;

  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });
    final result = await widget.onSave(name, phone);
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context, name.trim());
    } else {
      setState(() {
        saving = false;
        error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(widget.message, style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            PozzoTextField(
              label: 'Nombre',
              value: name,
              autofocus: true,
              placeholder: 'Rosa Medina',
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => setState(() {
                name = value.length > 80 ? value.substring(0, 80) : value;
                error = null;
              }),
            ),
            const SizedBox(height: 16),
            PozzoTextField(
              label: 'Celular (opcional)',
              value: phone,
              prefix: '+51',
              placeholder: '999 000 000',
              keyboardType: TextInputType.phone,
              errorText: error,
              onChanged: (value) => setState(() {
                phone = PhoneNumbers.clean(value);
                error = null;
              }),
            ),
            const SizedBox(height: 24),
            PozzoPrimaryButton(text: widget.action, onPressed: _save, enabled: canSave, loading: saving),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}
