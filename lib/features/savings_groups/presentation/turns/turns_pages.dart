import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/turns/turns_view_models.dart';
import 'package:pozzo/features/savings_groups/presentation/widgets/plan_widgets.dart';
import 'package:pozzo/features/savings_groups/presentation/widgets/readiness_checklist.dart';
import 'package:pozzo/features/savings_groups/presentation/widgets/turn_row.dart';

/// G8: "Asignar turnos". Each method opens its page; when one is confirmed this page closes too and
/// returns true, so the detail reads the group again.
class AssignTurnsPage extends StatefulWidget {
  const AssignTurnsPage({super.key, required this.groupId, required this.seats});

  final String groupId;
  final int seats;

  @override
  State<AssignTurnsPage> createState() => _AssignTurnsPageState();
}

class _AssignTurnsPageState extends State<AssignTurnsPage> {
  late final AssignTurnsViewModel viewModel = getIt<AssignTurnsViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final state = viewModel.state;
    if (state.method == TurnMethod.auction && state.auctionLocked) {
      final accepted = await confirmPaidPlan(
        context,
        'La subasta de turnos es parte del plan de pago. Esta junta está en el plan gratuito.',
      );
      if (!accepted || !await viewModel.activate()) return;
    }
    if (!mounted) return;
    final Widget page = switch (viewModel.state.method) {
      TurnMethod.draw => DrawResultPage(groupId: widget.groupId),
      TurnMethod.agreed => AgreedOrderPage(groupId: widget.groupId),
      TurnMethod.auction => AuctionRulesPage(groupId: widget.groupId),
    };
    final assigned = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => page));
    if (assigned == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar turnos')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    const FormHeader(
                      title: '¿Cómo se reparte el orden de cobro?',
                      message: 'Elige el método que ya acordó tu grupo. Los turnos quedan visibles para todos.',
                    ),
                    _MethodCard(
                      icon: Icons.shuffle,
                      title: 'Sorteo',
                      description: 'El orden se define al azar entre los ${widget.seats} integrantes.',
                      selected: state.method == TurnMethod.draw,
                      onTap: () => viewModel.choose(TurnMethod.draw),
                    ),
                    _MethodCard(
                      icon: Icons.format_list_numbered,
                      title: 'Orden acordado',
                      description: 'Tú ordenas los turnos según lo conversado con el grupo.',
                      selected: state.method == TurnMethod.agreed,
                      onTap: () => viewModel.choose(TurnMethod.agreed),
                    ),
                    _MethodCard(
                      icon: Icons.gavel,
                      title: 'Subasta',
                      description: 'Cada turno se asigna a quien ofrece el mayor descuento sobre el pozo.',
                      selected: state.method == TurnMethod.auction,
                      badge: state.auctionLocked ? 'Plan de pago' : null,
                      onTap: () => viewModel.choose(TurnMethod.auction),
                    ),
                    if (state.errorMessage != null)
                      Text(state.errorMessage!, style: TextStyle(color: colors.error)),
                  ],
                ),
              ),
              BottomActions(
                children: [PozzoPrimaryButton(text: 'Continuar', onPressed: _continue, loading: state.isActivating)],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(width: selected ? 2 : 1, color: selected ? colors.primary : colors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? colors.primaryContainer : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: text.titleLarge),
                          if (badge != null)
                            StatusChip(
                              text: badge!,
                              background: colors.secondaryContainer,
                              foreground: colors.onSecondaryContainer,
                            ),
                        ],
                      ),
                      Text(description, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// G9: "Resultado del sorteo".
class DrawResultPage extends StatefulWidget {
  const DrawResultPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<DrawResultPage> createState() => _DrawResultPageState();
}

class _DrawResultPageState extends State<DrawResultPage> {
  late final DrawResultViewModel viewModel = getIt<DrawResultViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado del sorteo')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final calendar = state.calendar;
          return Column(
            children: [
              Expanded(
                child: calendar == null
                    ? LoadingOrError(loading: state.isDrawing, error: state.errorMessage, onRetry: viewModel.draw)
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          InfoBanner(
                            icon: Icons.shuffle,
                            text: 'Sorteo realizado'
                                '${calendar.assignedAt == null ? '' : ' el ${Formats.mediumDate(calendar.assignedAt!.toLocal())}, ${Formats.time(calendar.assignedAt!)}'}'
                                ', entre ${calendar.turns.length} integrantes.',
                          ),
                          const SizedBox(height: 8),
                          for (final turn in calendar.turns)
                            TurnRow(
                              turnNumber: turn.turnNumber,
                              name: turn.displayName,
                              cutoffDate: turn.cutoffDate,
                              highlighted: turn.turnNumber == 1,
                              trailing: InitialsAvatar(name: turn.displayName, size: 40, photoUrl: turn.photoUrl),
                            ),
                          ErrorText(state.errorMessage),
                        ],
                      ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Confirmar turnos',
                    onPressed: () => Navigator.pop(context, true),
                    enabled: calendar != null && !state.isDrawing,
                  ),
                  const SizedBox(height: 8),
                  PozzoOutlinedButton(
                    text: 'Repetir el sorteo',
                    icon: Icons.refresh,
                    onPressed: viewModel.draw,
                    enabled: !state.isDrawing,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// G10: "Ordenar turnos", by dragging the members.
class AgreedOrderPage extends StatefulWidget {
  const AgreedOrderPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<AgreedOrderPage> createState() => _AgreedOrderPageState();
}

class _AgreedOrderPageState extends State<AgreedOrderPage> {
  late final AgreedOrderViewModel viewModel = getIt<AgreedOrderViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final saved = await viewModel.confirm();
    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordenar turnos')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final group = state.detail?.group;
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: InfoBanner(text: 'Mantén presionado y arrastra para cambiar el orden de cobro.'),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.order.length,
                        onReorderItem: viewModel.move,
                        itemBuilder: (context, index) {
                          final member = state.order[index];
                          return Material(
                            key: ValueKey(member.membershipId),
                            color: Colors.transparent,
                            child: TurnRow(
                              turnNumber: index + 1,
                              name: member.displayName,
                              cutoffDate: group?.cutoffDateOfTurn(index + 1),
                              trailing: Icon(
                                Icons.drag_handle,
                                semanticLabel: 'Arrastrar',
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ErrorText(state.errorMessage)),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Confirmar orden',
                    onPressed: _confirm,
                    enabled: state.order.isNotEmpty,
                    loading: state.isSaving,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// G11: "Turnos por subasta".
class AuctionRulesPage extends StatefulWidget {
  const AuctionRulesPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<AuctionRulesPage> createState() => _AuctionRulesPageState();
}

class _AuctionRulesPageState extends State<AuctionRulesPage> {
  late final AuctionRulesViewModel viewModel = getIt<AuctionRulesViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await viewModel.save();
    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('Turnos por subasta')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final days = state.closesDaysBeforeCutoff;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    const InfoBanner(
                      icon: Icons.gavel,
                      text: 'Cada período abre una subasta entre quienes aún no cobran. Gana quien ofrece el mayor '
                          'descuento sobre el pozo, y ese descuento se reparte entre los demás en su siguiente aporte.',
                    ),
                    const SizedBox(height: 20),
                    const FieldLabel('¿Cuántos días antes del corte cierra cada subasta?'),
                    const SizedBox(height: 8),
                    NumberStepper(
                      value: days,
                      onChanged: viewModel.onClosingDaysChanged,
                      min: 0,
                      max: AuctionRulesState.maxClosingDays,
                    ),
                    Text(
                      days == 0
                          ? 'Cierra el mismo día del corte.'
                          : 'Cierra $days ${days == 1 ? 'día' : 'días'} antes del corte.',
                      textAlign: TextAlign.center,
                      style: small,
                    ),
                    const SizedBox(height: 20),
                    PozzoTextField(
                      label: 'Oferta mínima',
                      value: state.minimumBid,
                      onChanged: viewModel.onMinimumBidChanged,
                      prefix: 'S/',
                      placeholder: '20.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      supportingText: 'El descuento más pequeño que se acepta sobre el pozo.',
                    ),
                    const SizedBox(height: 20),
                    const FieldLabel('Si nadie oferta'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OptionChip(
                            text: 'Sorteo',
                            selected: state.fallback == AuctionFallback.draw,
                            onTap: () => viewModel.onFallbackChanged(AuctionFallback.draw),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OptionChip(
                            text: 'Elijo yo',
                            selected: state.fallback == AuctionFallback.organizer,
                            onTap: () => viewModel.onFallbackChanged(AuctionFallback.organizer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.fallback == AuctionFallback.draw
                          ? 'El turno se sortea entre quienes aún no cobran, sin descuento.'
                          : 'Tú eliges quién cobra entre quienes aún no cobran, sin descuento.',
                      style: small,
                    ),
                    ErrorText(state.errorMessage),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Confirmar subasta',
                    onPressed: _save,
                    enabled: state.minimumBidValue != null,
                    loading: state.isSaving,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// G12: "Iniciar junta".
class StartGroupPage extends StatefulWidget {
  const StartGroupPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<StartGroupPage> createState() => _StartGroupPageState();
}

class _StartGroupPageState extends State<StartGroupPage> {
  late final StartGroupViewModel viewModel = getIt<StartGroupViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final started = await viewModel.start();
    if (started && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar junta')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final detail = state.detail;
          if (detail == null) return LoadingOrError(loading: state.isLoading, error: state.errorMessage);
          final group = detail.group;
          final first = detail.turns.turns.firstOrNull;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    ReadinessChecklist(
                      items: [
                        ChecklistItem(
                          done: group.readiness.groupFull,
                          title: 'Grupo completo',
                          detail: '${detail.members.length} de ${group.seats} integrantes',
                        ),
                        ChecklistItem(
                          done: group.readiness.turnsAssigned,
                          title: 'Turnos definidos',
                          detail: GroupLabels.turnMethod(group.turnMethod),
                        ),
                        ChecklistItem(
                          done: group.readiness.destinationDefined,
                          title: 'Reglas fijadas',
                          detail: '${Formats.soles(group.contributionAmount)} · ${group.periodicity.title} · '
                              '${group.seats} integrantes',
                        ),
                      ],
                    ),
                    if (first != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primer período',
                              style: text.titleSmall?.copyWith(color: colors.onPrimaryContainer),
                            ),
                            Text(
                              group.turnMethod == TurnMethod.auction ? 'Se subasta' : 'Cobra ${first.displayName}',
                              style: text.headlineSmall?.copyWith(color: colors.onPrimaryContainer),
                            ),
                            Text(
                              'Corte: ${Formats.mediumDate(first.cutoffDate)} · Pozo ${Formats.soles(group.potAmount)}',
                              style: text.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    InfoBanner(
                      icon: Icons.warning_amber,
                      background: status.warningContainer,
                      foreground: status.onWarningContainer,
                      text: 'Al iniciar, el aporte, la periodicidad y el número de integrantes ya no se pueden cambiar.',
                    ),
                    ErrorText(state.errorMessage),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Iniciar junta',
                    onPressed: _start,
                    enabled: group.readiness.canStart,
                    loading: state.isStarting,
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Revisar las reglas')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
