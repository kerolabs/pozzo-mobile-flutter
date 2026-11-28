import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/presentation/organizer/organizer_view_models.dart';
import 'package:pozzo/features/contributions/presentation/widgets/contribution_widgets.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_page.dart';

/// The layout of the organizer forms: the content scrolls and the actions stay at the bottom.
class _OrganizerScaffold extends StatelessWidget {
  const _OrganizerScaffold({required this.title, required this.body, this.actions = const []});

  final String title;
  final List<Widget> body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(child: ListView(padding: const EdgeInsets.all(16), children: body)),
          if (actions.isNotEmpty) BottomActions(children: actions),
        ],
      ),
    );
  }
}

String _stateLabel(ContributionState state) => state == ContributionState.late ? 'Atrasado' : 'Pendiente';

/// C11: "Registrar efectivo".
class CashPage extends StatefulWidget {
  const CashPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<CashPage> {
  late final SettleViewModel viewModel = getIt<SettleViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final state = viewModel.state;
    if (state.amountDiffers) {
      final name = state.period?.members
              .where((member) => member.membershipId == state.selectedMember)
              .firstOrNull
              ?.displayName
              .split(' ')
              .first ??
          '';
      final confirmed = await confirmAction(
        context,
        title: '¿Registrar un monto distinto?',
        message: '$name debe ${Formats.soles(state.owed!)} en este período y vas a registrar '
            '${Formats.soles(state.amountValue!)}. El aporte quedará validado con ese monto.',
        confirmLabel: 'Registrar igual',
      );
      if (!confirmed) return;
    }
    final saved = await viewModel.registerCashContribution();
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final period = state.period;
        if (period == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Registrar efectivo')),
            body: LoadingOrError(loading: state.isLoading, error: state.errorMessage),
          );
        }
        final pending = period.unsettled;
        return _OrganizerScaffold(
          title: 'Registrar efectivo',
          body: [
            Text('¿De quién lo recibiste?', style: Theme.of(context).textTheme.titleMedium),
            if (pending.isEmpty)
              const InfoBanner(text: 'Todos ya aportaron en este período.', icon: Icons.task_alt),
            for (final member in pending)
              MemberOption(
                name: member.displayName,
                subtitle: _stateLabel(member.state),
                selected: state.selectedMember == member.membershipId,
                photoUrl: state.photos[member.membershipId],
                onTap: () => viewModel.onMemberSelected(member.membershipId),
              ),
            const SizedBox(height: 12),
            PozzoTextField(
              label: 'Monto recibido',
              value: state.amount,
              onChanged: viewModel.onAmountChanged,
              prefix: 'S/',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DateField(label: 'Fecha', value: state.receivedOn, onChanged: viewModel.onReceivedOnChanged),
            const SizedBox(height: 12),
            const InfoBanner(text: 'El aporte en efectivo queda validado al registrarlo y figura en el historial.'),
          ],
          actions: [
            ErrorText(state.errorMessage),
            PozzoPrimaryButton(
              text: 'Registrar aporte',
              onPressed: _register,
              enabled: state.selectedMember != null && state.amountValue != null,
              loading: state.isSaving,
            ),
          ],
        );
      },
    );
  }
}

/// C12: "Cubrir un aporte".
class CoverPage extends StatefulWidget {
  const CoverPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage> {
  late final SettleViewModel viewModel = getIt<SettleViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final saved = await viewModel.registerCoverageContribution();
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final period = state.period;
        if (period == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cubrir un aporte')),
            body: LoadingOrError(loading: state.isLoading, error: state.errorMessage),
          );
        }
        final pending = period.unsettled;
        return _OrganizerScaffold(
          title: 'Cubrir un aporte',
          body: [
            Text('¿Qué aporte se cubre?', style: title),
            if (pending.isEmpty)
              const InfoBanner(text: 'No hay aportes pendientes en este período.', icon: Icons.task_alt),
            for (final member in pending)
              MemberOption(
                name: member.displayName,
                subtitle: _stateLabel(member.state),
                selected: state.selectedMember == member.membershipId,
                photoUrl: state.photos[member.membershipId],
                onTap: () => viewModel.onMemberSelected(member.membershipId),
              ),
            const SizedBox(height: 12),
            Text('¿Quién lo cubre?', style: title),
            for (final member in period.members.where((m) => m.membershipId != state.selectedMember))
              MemberOption(
                name: member.displayName,
                isMe: member.isMe,
                selected: state.coveredBy == member.membershipId,
                photoUrl: state.photos[member.membershipId],
                onTap: () => viewModel.onCoveredBySelected(member.membershipId),
              ),
            const SizedBox(height: 12),
            InfoBanner(
              text: 'La cobertura completa el pozo de ${Formats.soles(period.contributionAmount)}. La deuda queda '
                  'entre ellos y se anota en el historial de cumplimiento.',
            ),
          ],
          actions: [
            ErrorText(state.errorMessage),
            PozzoPrimaryButton(
              text: 'Registrar cobertura',
              onPressed: _register,
              enabled: state.selectedMember != null && state.coveredBy != null,
              loading: state.isSaving,
            ),
          ],
        );
      },
    );
  }
}

/// C13: "Entregar pozo".
class DeliverPage extends StatefulWidget {
  const DeliverPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<DeliverPage> createState() => _DeliverPageState();
}

class _DeliverPageState extends State<DeliverPage> {
  late final DeliverViewModel viewModel = getIt<DeliverViewModel>(param1: widget.groupId);

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_onDelivered);
  }

  @override
  void dispose() {
    viewModel.removeListener(_onDelivered);
    viewModel.dispose();
    super.dispose();
  }

  /// The last turn closes the cycle: the pot and this page give way to the celebration.
  void _onDelivered() {
    final delivery = viewModel.state.delivery;
    final cycle = viewModel.state.cycle;
    if (delivery == null || !delivery.cycleClosed || cycle == null || !mounted) return;
    viewModel.removeListener(_onDelivered);
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (context) => CycleClosedPage(
          groupId: widget.groupId,
          groupName: cycle.groupName,
          totalTurns: cycle.totalTurns,
          potAmount: cycle.potAmount,
          lastPeriodId: delivery.deliveredPeriodId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final period = state.period;
        final delivery = state.delivery;
        if (delivery != null && !delivery.cycleClosed && period != null) {
          return _ResultLayout(
            icon: Icons.check_circle,
            title: 'Pozo entregado',
            message: '${Formats.soles(delivery.deliveredAmount)} a ${period.payoutMemberName}. Ya empezó el período '
                '${delivery.nextTurn}. Adjunta la transferencia para que todos la vean.',
            action: 'Ver el nuevo período',
            onAction: () => Navigator.pop(context),
            extra: [AttachPayoutProofButton(periodId: delivery.deliveredPeriodId)],
          );
        }
        if (period == null || state.cycle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Entregar pozo')),
            body: LoadingOrError(loading: state.isLoading, error: state.errorMessage),
          );
        }
        final firstName = period.payoutMemberName.split(' ').first;
        return _OrganizerScaffold(
          title: 'Entregar pozo',
          body: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(28)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período ${period.turnNumber} de ${period.totalTurns} · Pozo completo',
                    style: text.titleSmall?.copyWith(color: colors.onPrimaryContainer),
                  ),
                  Text(
                    Formats.soles(period.payoutAmount),
                    style: text.displayMedium?.copyWith(color: colors.onPrimaryContainer),
                  ),
                  Text(
                    'para ${period.payoutMemberName}',
                    style: text.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            if (period.auctionDiscount > 0) ...[
              const SizedBox(height: 12),
              InfoBanner(
                text: 'Entrega ${Formats.soles(period.payoutAmount)}: el pozo de ${Formats.soles(period.potAmount)} '
                    'menos el descuento de ${Formats.soles(period.auctionDiscount)} que $firstName ofreció en la '
                    'subasta.',
              ),
            ],
            const SizedBox(height: 12),
            SummaryCard(
              rows: [
                ('Aportes', '${period.settledCount} de ${period.membersCount}'),
                ('Cobra', period.payoutMemberName),
                ('Turno', '${period.turnNumber} de ${period.totalTurns}'),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.account_balance_wallet_outlined, color: colors.onSurfaceVariant),
              title: Text(
                'Transfiere el pozo a $firstName desde tu billetera y luego márcalo como entregado.',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            if (period.turnNumber == period.totalTurns)
              const InfoBanner(text: 'Es el último turno: al entregarlo se cierra el ciclo de la junta.'),
          ],
          actions: [
            ErrorText(state.errorMessage),
            PozzoPrimaryButton(
              text: 'Marcar como entregado',
              icon: Icons.task_alt,
              onPressed: viewModel.deliver,
              loading: state.isSaving,
            ),
          ],
        );
      },
    );
  }
}

/// C14: "¡Ciclo completado!".
class CycleClosedPage extends StatelessWidget {
  const CycleClosedPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.totalTurns,
    required this.potAmount,
    required this.lastPeriodId,
  });

  final String groupId;
  final String groupName;
  final int totalTurns;
  final double potAmount;
  final String? lastPeriodId;

  @override
  Widget build(BuildContext context) {
    return _ResultLayout(
      icon: Icons.celebration_outlined,
      title: '¡Ciclo completado!',
      message: 'Los $totalTurns integrantes de $groupName ya cobraron su turno del pozo de '
          '${Formats.soles(potAmount)}. El historial de cumplimiento de cada uno ya está actualizado. Si quieren '
          'seguir, abre un nuevo ciclo desde la junta.',
      action: 'Volver a mis juntas',
      onAction: () => Navigator.popUntil(context, (route) => route.isFirst),
      extra: [
        if (lastPeriodId != null) ...[AttachPayoutProofButton(periodId: lastPeriodId!), const SizedBox(height: 8)],
        PozzoOutlinedButton(
          text: 'Ver la junta y abrir un nuevo ciclo',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GroupDetailPage(groupId: groupId)),
          ),
        ),
      ],
    );
  }
}

class _ResultLayout extends StatelessWidget {
  const _ResultLayout({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
    this.extra = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ResultBadge(icon: icon),
                      const SizedBox(height: 24),
                      Text(title, textAlign: TextAlign.center, style: text.headlineMedium),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            BottomActions(
              children: [
                ...extra,
                const SizedBox(height: 8),
                PozzoPrimaryButton(text: action, onPressed: onAction),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
