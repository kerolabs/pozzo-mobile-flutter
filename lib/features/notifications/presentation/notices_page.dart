import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/main/deep_links.dart';
import 'package:pozzo/features/notifications/domain/notifications.dart';
import 'package:pozzo/features/notifications/presentation/notices_view_model.dart';

/// N1: "Avisos", the third tab.
class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  final NoticesViewModel viewModel = getIt<NoticesViewModel>();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _open(Notice notice) async {
    final link = notice.deepLink;
    if (link == null) return;
    await openDeepLink(context, link);
    viewModel.load();
  }

  static String _dayLabel(DateTime day) {
    final today = Formats.today();
    if (day == today) return 'Hoy';
    if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
    return Formats.shortDate(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          final byDay = <DateTime, List<Notice>>{};
          for (final notice in state.notices) {
            final local = notice.sentAt.toLocal();
            byDay.putIfAbsent(DateTime(local.year, local.month, local.day), () => []).add(notice);
          }
          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final settings in state.reminders) ...[
                  _ReminderCard(
                    settings: settings,
                    showGroupName: state.reminders.length > 1,
                    onToggle: (enabled) => viewModel.setRemindersEnabled(settings.groupId, enabled),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final stopped in state.stopped) ...[
                  _StoppedCard(stopped: stopped, showGroupName: state.stopped.length > 1),
                  const SizedBox(height: 12),
                ],
                ErrorText(state.errorMessage),
                if (state.notices.isEmpty)
                  const EmptyState(
                    icon: Icons.notifications_none,
                    title: 'Aún no tienes avisos',
                    message: 'Aquí verás los recordatorios antes del corte y lo que pase en tus juntas.',
                  ),
                for (final entry in byDay.entries) ...[
                  SectionTitle(_dayLabel(entry.key)),
                  for (final notice in entry.value)
                    _NoticeRow(notice: notice, unseen: state.isUnseen(notice), onTap: () => _open(notice)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.settings, required this.showGroupName, required this.onToggle});

  final ReminderSettings settings;
  final bool showGroupName;
  final ValueChanged<bool> onToggle;

  static String _offset(int days) => switch (days) {
        0 => 'El día del corte',
        1 => '1 día antes',
        _ => '$days días antes',
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final enabled = settings.plan.enabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recordatorios automáticos', style: text.titleMedium),
                      if (showGroupName)
                        Text(settings.groupName, style: text.labelLarge?.copyWith(color: colors.primary)),
                      Text(
                        'Se envían antes de la fecha de corte a quien aún no aportó.',
                        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: settings.isSaving ? null : onToggle),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in settings.plan.offsetsInDays)
                  StatusChip(
                    text: _offset(days),
                    background: enabled ? colors.secondaryContainer : colors.surfaceContainerHighest,
                    foreground: enabled ? colors.onSecondaryContainer : colors.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoppedCard extends StatelessWidget {
  const _StoppedCard({required this.stopped, required this.showGroupName});

  final StoppedReminders stopped;
  final bool showGroupName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Recordatorios del período ${stopped.turnNumber}', style: text.titleMedium)),
                StatusChip(
                  text: 'Detenidos',
                  background: status.successContainer,
                  foreground: status.onSuccessContainer,
                  icon: Icons.check,
                ),
              ],
            ),
            if (showGroupName) Text(stopped.groupName, style: text.labelLarge?.copyWith(color: colors.primary)),
            const SizedBox(height: 4),
            Text(
              'Tu aporte quedó validado. Pozzo ya no te enviará recordatorios de este período.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice, required this.unseen, required this.onTap});

  final Notice notice;
  final bool unseen;
  final VoidCallback onTap;

  String? get _action {
    final link = notice.deepLink;
    if (link == null) return null;
    if (link.endsWith('/reviews')) return 'Revisar comprobante';
    if (notice.kind == NotificationKind.reminder) return 'Registrar aporte';
    if (notice.title.toLowerCase().contains('rechaz')) return 'Volver a registrar';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    final (icon, bg, fg) = notice.kind == NotificationKind.reminder
        ? (Icons.notifications_active_outlined, status.warningContainer, status.onWarningContainer)
        : notice.deepLink?.endsWith('/reviews') == true
            ? (Icons.receipt_long_outlined, status.warningContainer, status.onWarningContainer)
            : notice.title.toLowerCase().contains('rechaz')
                ? (Icons.error_outline, colors.errorContainer, colors.onErrorContainer)
                : (Icons.check_circle_outline, status.successContainer, status.onSuccessContainer);
    final action = _action;
    return InkWell(
      onTap: notice.deepLink == null ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: action == null
            ? null
            : BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 22, backgroundColor: bg, child: Icon(icon, color: fg)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notice.title, style: text.titleMedium),
                  Text(notice.body, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                  Text(Formats.time(notice.sentAt), style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  if (action != null) ...[
                    const SizedBox(height: 8),
                    PozzoOutlinedButton(text: action, onPressed: onTap),
                  ],
                ],
              ),
            ),
            if (unseen)
              Container(
                margin: const EdgeInsets.only(top: 8, left: 8),
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
