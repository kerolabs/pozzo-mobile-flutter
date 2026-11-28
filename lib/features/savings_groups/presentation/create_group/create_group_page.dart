import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/create_group/create_group_state.dart';
import 'package:pozzo/features/savings_groups/presentation/create_group/create_group_view_model.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/invitation_page.dart';
import 'package:pozzo/features/savings_groups/presentation/widgets/plan_widgets.dart';

/// G2: "Nueva junta", or "Editar junta" when it receives the id of a group that has not started.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key, this.editingGroupId});

  final String? editingGroupId;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  late final CreateGroupViewModel viewModel = getIt<CreateGroupViewModel>(param1: widget.editingGroupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  void _back() {
    if (!viewModel.back()) Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (viewModel.state.isEditing) {
      final saved = await viewModel.save();
      if (saved && mounted) Navigator.pop(context, true);
      return;
    }
    final created = await viewModel.create();
    if (created == null || !mounted) return;
    final (group, invitation) = created;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => InvitationPage(group: group, invitation: invitation)),
    );
  }

  Future<void> _pickDate(CreateGroupState state) async {
    final today = Formats.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.firstContributionDate.isBefore(today) ? today : state.firstContributionDate,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      helpText: 'Primer aporte',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) viewModel.onFirstContributionDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        return PopScope(
          canPop: state.step == CreateGroupStep.rules,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) viewModel.back();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(state.isEditing ? 'Editar junta' : 'Nueva junta'),
              leading: IconButton(
                onPressed: _back,
                tooltip: state.step == CreateGroupStep.rules ? 'Cerrar' : 'Volver',
                icon: Icon(state.step == CreateGroupStep.rules ? Icons.close : Icons.arrow_back),
              ),
            ),
            body: state.isPreparing
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            StepProgress(
                              current: state.step.number,
                              total: CreateGroupStep.values.length,
                              label: state.step.label,
                            ),
                            const SizedBox(height: 20),
                            ...switch (state.step) {
                              CreateGroupStep.rules => _rules(state),
                              CreateGroupStep.dates => _dates(state),
                              CreateGroupStep.summary => _summary(state),
                            },
                            ErrorText(state.errorMessage),
                          ],
                        ),
                      ),
                      BottomActions(children: [_action(state)]),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _action(CreateGroupState state) {
    switch (state.step) {
      case CreateGroupStep.rules:
        return PozzoPrimaryButton(text: 'Continuar', onPressed: viewModel.next, enabled: state.rulesValid);
      case CreateGroupStep.dates:
        return PozzoPrimaryButton(text: 'Continuar', onPressed: viewModel.next, enabled: state.datesValid);
      case CreateGroupStep.summary:
        final label = state.isEditing
            ? (state.activatesPaidPlan ? 'Activar plan y guardar' : 'Guardar cambios')
            : (state.activatesPaidPlan ? 'Activar plan y crear junta' : 'Crear junta');
        return PozzoPrimaryButton(text: label, onPressed: _submit, loading: state.isLoading);
    }
  }

  List<Widget> _rules(CreateGroupState state) {
    final colors = Theme.of(context).colorScheme;
    final seatsHelp = state.minSeats > NewGroup.minSeats
        ? 'No puede ser menos que los ${state.minSeats} integrantes que ya tiene la junta.'
        : 'Entre ${NewGroup.minSeats} y ${NewGroup.maxSeats} integrantes. '
            'El plan gratuito llega hasta ${GroupPlan.freeMaxSeats}.';
    return [
      PozzoTextField(
        label: 'Nombre de la junta',
        value: state.name,
        onChanged: viewModel.onNameChanged,
        placeholder: 'Junta del barrio',
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 20),
      PozzoTextField(
        label: 'Aporte por integrante',
        value: state.amount,
        onChanged: viewModel.onAmountChanged,
        prefix: 'S/',
        placeholder: '300',
        supportingText: 'Monto fijo que cada integrante entrega en cada período.',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: 20),
      const FieldLabel('Periodicidad'),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final option in Periodicity.values) ...[
            if (option != Periodicity.values.first) const SizedBox(width: 8),
            Expanded(
              child: OptionChip(
                text: option.title,
                selected: state.periodicity == option,
                onTap: () => viewModel.onPeriodicityChanged(option),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 20),
      const FieldLabel('Número de integrantes'),
      const SizedBox(height: 8),
      NumberStepper(
        value: state.seats,
        onChanged: viewModel.onSeatsChanged,
        min: state.minSeats,
        max: NewGroup.maxSeats,
      ),
      const SizedBox(height: 8),
      Text(
        'El ciclo dura ${state.seats} períodos y cada integrante cobra una vez. $seatsHelp',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
    ];
  }

  List<Widget> _dates(CreateGroupState state) {
    final colors = Theme.of(context).colorScheme;
    final invalidPhone = state.destinationPhone.length == 9 && !PhoneNumbers.isValid(state.destinationPhone);
    final cutoff = GroupLabels.cutoff(state.periodicity, state.firstContributionDate).toLowerCase();
    return [
      const FieldLabel('Primer aporte'),
      const SizedBox(height: 8),
      InkWell(
        onTap: () => _pickDate(state),
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month_outlined)),
          child: Text(
            Formats.longDate(state.firstContributionDate),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Fecha límite del primer período. Corte: $cutoff.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      const FieldLabel('Destino de los aportes'),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final method in PaymentMethod.values) ...[
            SizedBox(
              width: 112,
              child: OptionChip(
                text: method.label,
                selected: state.paymentMethod == method,
                onTap: () => viewModel.onPaymentMethodChanged(method),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      const SizedBox(height: 20),
      PozzoTextField(
        label: 'Número del destino',
        value: state.destinationPhone,
        onChanged: viewModel.onDestinationPhoneChanged,
        prefix: '+51',
        placeholder: '999 000 123',
        keyboardType: TextInputType.phone,
        supportingText: 'Pozzo valida cada comprobante contra este número. No recibe ni retiene dinero.',
        errorText: invalidPhone ? 'Ingresa un celular de nueve dígitos que empiece con 9.' : null,
      ),
    ];
  }

  List<Widget> _summary(CreateGroupState state) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final amount = state.contributionAmount ?? 0;
    return [
      SummaryCard(
        rows: [
          ('Nombre', state.name.trim()),
          ('Aporte', Formats.soles(amount)),
          ('Periodicidad', state.periodicity.title),
          ('Integrantes', '${state.seats}'),
          ('Día de corte', GroupLabels.cutoff(state.periodicity, state.firstContributionDate)),
          ('Primer aporte', Formats.mediumDate(state.firstContributionDate)),
          ('Destino', '${state.paymentMethod.label} · ${PhoneNumbers.grouped(state.destinationPhone)}'),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pozo por turno', style: text.titleSmall?.copyWith(color: colors.onPrimaryContainer)),
            Text(
              Formats.soles(state.potAmount ?? amount),
              style: text.displayMedium?.copyWith(color: colors.onPrimaryContainer),
            ),
            Text(
              '${Formats.soles(amount)} × ${state.seats} integrantes',
              style: text.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const FieldLabel('Plan'),
      const SizedBox(height: 8),
      if (state.groupPlan == GroupPlan.paid)
        Text('${planTitle(GroupPlan.paid)}, ya activo.', style: text.bodyLarge)
      else
        PlanChoice(
          selected: state.effectivePlan,
          freeUnavailableReason: state.freePlanUnavailableReason,
          onSelect: viewModel.onPlanChanged,
        ),
      if (state.clearsTurns) ...[
        const SizedBox(height: 16),
        Text(
          'Cambiaste el número de integrantes: los turnos asignados se borran y tendrás que asignarlos de nuevo.',
          style: text.bodyMedium?.copyWith(color: colors.error),
        ),
      ],
      const SizedBox(height: 16),
      Text(
        'Podrás ajustar las reglas hasta que inicies la junta.',
        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    ];
  }
}
