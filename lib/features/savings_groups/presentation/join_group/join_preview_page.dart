import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_page.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/join_view_models.dart';

/// G5: "Revisar la junta" before joining it.
class JoinPreviewPage extends StatefulWidget {
  const JoinPreviewPage({super.key, required this.code});

  final String code;

  @override
  State<JoinPreviewPage> createState() => _JoinPreviewPageState();
}

class _JoinPreviewPageState extends State<JoinPreviewPage> {
  late final JoinPreviewViewModel viewModel = getIt<JoinPreviewViewModel>(param1: widget.code);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _join(GroupPreview preview) async {
    final joined = await viewModel.join();
    if (!joined || !mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => JoinedPage(preview: preview)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar la junta')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final preview = state.preview;
          if (preview == null) {
            return LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load);
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _PreviewCard(preview: preview),
                    const SizedBox(height: 16),
                    InfoBanner(
                      text: 'Pozzo no maneja el dinero. Los aportes se transfieren directamente a '
                          '${preview.organizerName.split(' ').first}.',
                    ),
                    ErrorText(state.errorMessage),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Unirme a la junta',
                    onPressed: () => _join(preview),
                    enabled: preview.freeSeats > 0,
                    loading: state.isJoining,
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ahora no')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final GroupPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    Widget metric(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
              Text(value, style: text.headlineSmall),
            ],
          ),
        );
    Widget detail(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text(label, style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(width: 12),
              Expanded(child: Text(value, textAlign: TextAlign.end, style: text.titleMedium)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(preview.name, style: text.headlineSmall)),
                if (preview.freeSeats > 0)
                  StatusChip(
                    text: 'Por iniciar',
                    background: status.warningContainer,
                    foreground: status.onWarningContainer,
                  )
                else
                  StatusChip(
                    text: 'Completa',
                    background: colors.surfaceContainerHighest,
                    foreground: colors.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                InitialsAvatar(name: preview.organizerName),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preview.organizerName, style: text.titleMedium),
                    Text('Cabeza de junta', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            Divider(height: 32, color: colors.outlineVariant),
            Row(
              children: [
                metric('Aporte', Formats.soles(preview.contributionAmount)),
                metric('Periodicidad', preview.periodicity.title),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                metric('Integrantes', '${preview.membersCount} de ${preview.seats}'),
                metric('Pozo por turno', Formats.soles(preview.potAmount)),
              ],
            ),
            const SizedBox(height: 8),
            detail('Fecha de corte', GroupLabels.cutoff(preview.periodicity, preview.firstContributionDate)),
            detail('Primer aporte', Formats.mediumDate(preview.firstContributionDate)),
          ],
        ),
      ),
    );
  }
}

/// G6: "Ya eres parte de la junta".
class JoinedPage extends StatelessWidget {
  const JoinedPage({super.key, required this.preview});

  final GroupPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: ResultBadge(icon: Icons.check_circle)),
              const SizedBox(height: 24),
              Text('Ya eres parte de la junta', textAlign: TextAlign.center, style: text.headlineMedium),
              const SizedBox(height: 12),
              Text(
                '${preview.organizerName.split(' ').first} asignará los turnos antes de iniciar. Te avisaremos '
                'cuando la junta empiece.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: InitialsAvatar(
                    name: preview.name,
                    background: status.successContainer,
                    foreground: status.onSuccessContainer,
                  ),
                  title: Text(preview.name, style: text.titleMedium),
                  subtitle: Text('Participante · ${preview.membersCount + 1} de ${preview.seats} integrantes'),
                ),
              ),
              const Spacer(flex: 2),
              PozzoPrimaryButton(
                text: 'Ver mi junta',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GroupDetailPage(groupId: preview.groupId)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
