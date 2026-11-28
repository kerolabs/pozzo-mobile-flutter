import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/presentation/my_contributions/my_contributions_view_model.dart';
import 'package:pozzo/features/contributions/presentation/widgets/contribution_widgets.dart';

String methodLabel(ContributionMethod method) => switch (method) {
  ContributionMethod.transfer => 'Transferencia',
  ContributionMethod.cash => 'Efectivo',
  ContributionMethod.coverage => 'Cubierto por otro integrante',
};

/// C3: "Mis aportes".
class MyContributionsPage extends StatefulWidget {
  const MyContributionsPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<MyContributionsPage> createState() => _MyContributionsPageState();
}

class _MyContributionsPageState extends State<MyContributionsPage> {
  late final MyContributionsViewModel viewModel =
      getIt<MyContributionsViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  static String _savedAgo(DateTime savedAt) {
    final elapsed = DateTime.now().difference(savedAt);
    if (elapsed.inMinutes < 1) return 'hace un momento';
    if (elapsed.inHours < 1) return 'hace ${elapsed.inMinutes} min';
    if (elapsed.inDays < 1) return 'hace ${elapsed.inHours} h';
    if (elapsed.inDays == 1) return 'hace 1 día';
    return 'hace ${elapsed.inDays} días';
  }

  void _openReceipt(MyPeriodContribution period) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ReceiptSheet(
        period: period,
        share: () => viewModel.shareText(period),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis aportes')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final data = state.contributions;
          if (data == null) {
            return LoadingOrError(
              loading: state.isLoading,
              error: state.errorMessage,
              onRetry: viewModel.load,
            );
          }
          final pending = data.pendingAmount > 0;
          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (data.isOffline) ...[
                  InfoBanner(
                    text:
                        'Sin conexión. Mostrando lo último guardado ${_savedAgo(data.savedAt)}.',
                  ),
                  const SizedBox(height: 12),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.groupName, style: text.headlineSmall),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Amount(
                              label: 'Aportado',
                              value: Formats.soles(data.contributedAmount),
                            ),
                            _Amount(
                              label: 'Pendiente',
                              value: Formats.soles(data.pendingAmount),
                              color: pending
                                  ? PozzoStatusColors.of(context)
                                        .onWarningContainer
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final period in data.periods) ...[
                  _PeriodRow(
                    period: period,
                    onTap: period.contribution == null
                        ? null
                        : () => _openReceipt(period),
                  ),
                  Divider(height: 1, color: colors.outlineVariant),
                ],
                const SizedBox(height: 12),
                Text(
                  'Toca un aporte para ver su comprobante.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: text.headlineMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period, required this.onTap});

  final MyPeriodContribution period;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final (icon, bg, fg) = switch (period.state) {
      ContributionState.validated => (
        Icons.receipt_long_outlined,
        status.successContainer,
        status.onSuccessContainer,
      ),
      ContributionState.inReview => (
        Icons.hourglass_top,
        status.warningContainer,
        status.onWarningContainer,
      ),
      ContributionState.pending => (
        Icons.schedule,
        status.warningContainer,
        status.onWarningContainer,
      ),
      ContributionState.late => (
        Icons.warning_amber,
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      ContributionState.covered => (
        Icons.volunteer_activism_outlined,
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    final contribution = period.contribution;
    final receipt = contribution?.receipt;
    final String detail;
    if (receipt != null) {
      detail =
          '${Formats.soles(period.amount)} · ${Formats.mediumDate(receipt.paidAt)}';
    } else if (contribution != null && period.state.isSettled) {
      detail =
          '${Formats.soles(period.amount)} · ${methodLabel(contribution.method)}';
    } else {
      detail =
          '${Formats.soles(period.amount)} · vence ${Formats.shortDate(period.cutoffDate)}';
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: bg,
        child: Icon(icon, color: fg),
      ),
      title: Text('Período ${period.turnNumber}'),
      subtitle: Text(detail),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ContributionStateChip(state: period.state, isMine: true),
          if (onTap != null)
            const Icon(Icons.chevron_right, semanticLabel: 'Ver comprobante'),
        ],
      ),
    );
  }
}

class _ReceiptSheet extends StatefulWidget {
  const _ReceiptSheet({required this.period, required this.share});

  final MyPeriodContribution period;
  final Future<String> Function() share;

  @override
  State<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<_ReceiptSheet> {
  bool sharing = false;
  String? error;

  Future<void> _share() async {
    setState(() {
      sharing = true;
      error = null;
    });

    try {
      final message = await widget.share();

      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          title: 'Compartir mi aporte',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (failure) {
      if (mounted) {
        setState(() => error = userMessageOf(failure));
      }
    } finally {
      if (mounted) {
        setState(() => sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final period = widget.period;
    final contribution = period.contribution!;
    final receipt = contribution.receipt;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Comprobante del período ${period.turnNumber}',
              style: text.titleLarge,
            ),
            Text(
              'Registrado el ${Formats.mediumDate(contribution.registeredAt.toLocal())}',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SummaryCard(
              rows: [
                ('Monto', Formats.soles(contribution.amount)),
                ('Forma', methodLabel(contribution.method)),
                if (receipt != null) ...[
                  ('Fecha del pago', Formats.mediumDate(receipt.paidAt)),
                  ('Enviado a', receipt.payeeName),
                  ('N.º de operación', receipt.operationNumber),
                  (
                    'Aplicación',
                    receipt.source == ReceiptSource.bank
                        ? 'Banco'
                        : receipt.source.label,
                  ),
                ],
              ],
            ),
            if (contribution.hasReceiptImage) ...[
              const SizedBox(height: 12),
              PozzoOutlinedButton(
                text: 'Ver imagen del comprobante',
                icon: Icons.image_outlined,
                onPressed: () => showReceiptImage(context, contribution.id),
              ),
            ],
            if (period.state.isSettled) ...[
              const SizedBox(height: 12),
              PozzoOutlinedButton(
                text: sharing
                    ? 'Preparando el enlace…'
                    : 'Compartir con enlace verificable',
                icon: Icons.share_outlined,
                enabled: !sharing,
                onPressed: _share,
              ),
              const SizedBox(height: 8),
              Text(
                'Quien lo abra ve la junta, el período, el monto y el final del número de operación, sin la imagen.',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              ErrorText(error),
            ],
          ],
        ),
      ),
    );
  }
}
