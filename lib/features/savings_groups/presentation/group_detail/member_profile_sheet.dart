import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/compliance_history/application/compliance_use_cases.dart';
import 'package:pozzo/features/compliance_history/domain/compliance.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

/// The profile of a member of the group: their turn, their phone and how they pay in Pozzo. The
/// organizer receives the actions on them in [actions].
Future<void> showMemberProfile(BuildContext context, Member member, {List<Widget> actions = const []}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _MemberProfileSheet(member: member, actions: actions),
  );
}

class _MemberProfileSheet extends StatefulWidget {
  const _MemberProfileSheet({required this.member, required this.actions});

  final Member member;
  final List<Widget> actions;

  @override
  State<_MemberProfileSheet> createState() => _MemberProfileSheetState();
}

class _MemberProfileSheetState extends State<_MemberProfileSheet> {
  ComplianceSummary? summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  /// Only members who use the app have a history; without it the sheet shows the rest.
  Future<void> _loadSummary() async {
    final accountId = widget.member.accountId;
    if (accountId == null) return;
    try {
      final loaded = await getIt<GetMemberSummaryUseCase>().execute(accountId);
      if (mounted) setState(() => summary = loaded);
    } catch (_) {
      // The summary is optional.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    final member = widget.member;
    final current = summary;
    final rows = <(String, String)>[
      if (member.turnNumber != null) ('Turno de cobro', 'Turno ${member.turnNumber}'),
      if (member.phoneNumber != null) ('Celular', PhoneNumbers.display(member.phoneNumber!)),
      if (current != null) ...[
        ('Aportes puntuales', current.punctuality == null ? 'Nuevo, sin aportes' : '${current.punctuality} %'),
        if (current.contributions > 0) ('Aportes registrados', '${current.onTime} de ${current.contributions} a tiempo'),
        ('Ciclos completados', '${current.cyclesCompleted}'),
        if (current.dropouts > 0) ('Juntas abandonadas', '${current.dropouts}'),
      ],
    ];
    final (chip, chipBg, chipFg) = member.isOrganizer
        ? ('Cabeza de junta', colors.secondaryContainer, colors.onSecondaryContainer)
        : member.kind == MembershipKind.app
            ? ('Usa Pozzo', colors.surfaceContainerHighest, colors.onSurfaceVariant)
            : ('Sin la app', status.warningContainer, status.onWarningContainer);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: InitialsAvatar(name: member.displayName, size: 80, photoUrl: member.photoUrl)),
            const SizedBox(height: 12),
            Text(
              member.isMe ? '${member.displayName} (tú)' : member.displayName,
              textAlign: TextAlign.center,
              style: text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Center(child: StatusChip(text: chip, background: chipBg, foreground: chipFg)),
            const SizedBox(height: 16),
            if (rows.isNotEmpty) SummaryCard(rows: rows),
            if (current != null) ...[
              const SizedBox(height: 8),
              Text(
                'La puntualidad cuenta los aportes en todas sus juntas de Pozzo.',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            for (final action in widget.actions) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }
}
