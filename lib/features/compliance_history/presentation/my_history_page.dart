import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/compliance_history/domain/compliance.dart';
import 'package:pozzo/features/compliance_history/presentation/history_view_models.dart';
import 'package:pozzo/features/contributions/presentation/my_contributions/my_contributions_page.dart';

/// H2: "Mi historial".
class MyHistoryPage extends StatefulWidget {
  const MyHistoryPage({super.key, required this.showBack});

  final bool showBack;

  @override
  State<MyHistoryPage> createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage> {
  final MyHistoryViewModel viewModel = getIt<MyHistoryViewModel>();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final message = await viewModel.share();
    if (message == null) return;
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) showMessage(context, 'Enlace copiado. Pégalo donde quieras compartirlo.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi historial'), automaticallyImplyLeading: widget.showBack),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final history = state.history;
          if (history == null) {
            return LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load);
          }
          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryHero(summary: history.summary),
                const SectionTitle('Por junta'),
                if (history.groups.isEmpty)
                  Text(
                    'Aún no hay aportes registrados. Tu historial se arma con los aportes de tus juntas en curso.',
                    style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                  ),
                for (var i = 0; i < history.groups.length; i++) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyContributionsPage(groupId: history.groups[i].groupId)),
                    ),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: history.groups[i].completed
                          ? colors.surfaceContainerHighest
                          : colors.secondaryContainer,
                      child: const Icon(Icons.groups_outlined),
                    ),
                    title: Text(history.groups[i].groupName),
                    subtitle: Text(
                      '${history.groups[i].completed ? 'Cerrada' : 'En curso'} · ${history.groups[i].onTime} de '
                      '${history.groups[i].contributions} puntuales',
                    ),
                    trailing: const Icon(Icons.chevron_right, semanticLabel: 'Ver mis aportes'),
                  ),
                  if (i < history.groups.length - 1) Divider(height: 1, color: colors.outlineVariant),
                ],
                const SizedBox(height: 12),
                Text(
                  'Resumen generado por Pozzo a partir de los aportes registrados en tus juntas.',
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                ErrorText(state.errorMessage),
                const SizedBox(height: 16),
                PozzoPrimaryButton(
                  text: 'Compartir mi historial',
                  icon: Icons.ios_share,
                  onPressed: _share,
                  loading: state.isSharing,
                  enabled: history.summary.contributions > 0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.summary});

  final ComplianceSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    final onHero = colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aportes puntuales', style: text.titleSmall?.copyWith(color: onHero)),
          Text(
            summary.punctuality == null ? 'Nuevo' : '${summary.punctuality} %',
            style: text.displayMedium?.copyWith(color: onHero),
          ),
          Text(
            summary.contributions == 0
                ? 'Todavía no tienes aportes registrados'
                : '${summary.onTime} de ${summary.contributions} aportes en todas tus juntas',
            style: text.bodyLarge?.copyWith(color: onHero),
          ),
          if (summary.contributions > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(
                  text: '${summary.onTime} puntuales',
                  background: status.successContainer,
                  foreground: status.onSuccessContainer,
                ),
                if (summary.late > 0)
                  StatusChip(
                    text: summary.late == 1 ? '1 atrasado' : '${summary.late} atrasados',
                    background: colors.surfaceContainerLowest,
                    foreground: colors.onSurface,
                  ),
                if (summary.covered > 0)
                  StatusChip(
                    text: summary.covered == 1 ? '1 cubierto' : '${summary.covered} cubiertos',
                    background: colors.surfaceContainerLowest,
                    foreground: colors.onSurface,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
