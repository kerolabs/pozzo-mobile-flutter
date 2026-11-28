import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

String planTitle(GroupPlan plan) => switch (plan) {
      GroupPlan.free => 'Plan gratuito',
      GroupPlan.paid => 'Plan de pago · ${Formats.soles(GroupPlan.paidPrice)} por junta',
    };

String planDescription(GroupPlan plan) => switch (plan) {
      GroupPlan.free => 'Una junta activa de hasta ${GroupPlan.freeMaxSeats} integrantes, con turnos por sorteo u '
          'orden acordado.',
      GroupPlan.paid => 'Más de ${GroupPlan.freeMaxSeats} integrantes, varias juntas a la vez y subasta de turnos. '
          'Se paga una vez y cubre todo el ciclo.',
    };

const String planDemoNotice = 'Versión de demostración: al activar el plan de pago no se hace ningún cobro.';

/// The two plans to choose from; the free one is disabled with its reason when it does not apply.
class PlanChoice extends StatelessWidget {
  const PlanChoice({super.key, required this.selected, required this.freeUnavailableReason, required this.onSelect});

  final GroupPlan selected;
  final String? freeUnavailableReason;
  final ValueChanged<GroupPlan> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final plan in GroupPlan.values) ...[
          _PlanOption(
            plan: plan,
            selected: selected == plan,
            enabled: plan == GroupPlan.paid || freeUnavailableReason == null,
            note: plan == GroupPlan.free ? freeUnavailableReason : null,
            onTap: () => onSelect(plan),
          ),
          const SizedBox(height: 8),
        ],
        Text(planDemoNotice, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.enabled,
    required this.note,
    required this.onTap,
  });

  final GroupPlan plan;
  final bool selected;
  final bool enabled;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final content = enabled ? colors.onSurface : colors.onSurface.withValues(alpha: 0.38);
    return Material(
      color: selected ? colors.secondaryContainer : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? colors.primary : colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: enabled ? colors.primary : content,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planTitle(plan), style: text.titleMedium?.copyWith(color: content)),
                    Text(planDescription(plan), style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                    if (note != null) Text(note!, style: text.bodySmall?.copyWith(color: colors.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks before activating the paid plan of a group. Returns true when the organizer accepts.
Future<bool> confirmPaidPlan(BuildContext context, String reason) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Activar el plan de pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reason),
          const SizedBox(height: 8),
          Text(planDescription(GroupPlan.paid)),
          const SizedBox(height: 8),
          Text(planDemoNotice, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ahora no')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Activar por ${Formats.soles(GroupPlan.paidPrice)}'),
        ),
      ],
    ),
  );
  return result ?? false;
}
