import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/presentation/widgets/contribution_widgets.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';

class ReviewsState {
  const ReviewsState({
    this.cycle,
    this.period,
    this.reviews = const [],
    this.reviewed = const [],
    this.photos = const {},
    this.isLoading = true,
    this.isSaving = false,
    this.reopening,
    this.errorMessage,
  });

  final Cycle? cycle;
  final Period? period;

  /// Contributions waiting for the organizer.
  final List<Contribution> reviews;

  /// Contributions already approved or rejected in this period, which can be reviewed again.
  final List<Contribution> reviewed;
  final Map<String, String> photos;
  final bool isLoading;
  final bool isSaving;
  final String? reopening;
  final String? errorMessage;

  ReviewsState copyWith({
    Cycle? cycle,
    Period? period,
    List<Contribution>? reviews,
    List<Contribution>? reviewed,
    Map<String, String>? photos,
    bool? isLoading,
    bool? isSaving,
    String? reopening,
    bool clearReopening = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReviewsState(
      cycle: cycle ?? this.cycle,
      period: period ?? this.period,
      reviews: reviews ?? this.reviews,
      reviewed: reviewed ?? this.reviewed,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      reopening: clearReopening ? null : reopening ?? this.reopening,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// C7: the receipts that did not match, for the organizer to approve or reject them.
class ReviewsViewModel extends ViewModel<ReviewsState> {
  ReviewsViewModel({
    required this.getPotState,
    required this.getPendingReviews,
    required this.reviewContribution,
    required this.getReviewed,
    required this.reopenReview,
    required this.getMemberPhotos,
    required this.groupId,
  }) : super(const ReviewsState()) {
    load();
  }

  final GetPotStateUseCase getPotState;
  final GetPendingReviewsUseCase getPendingReviews;
  final ReviewContributionUseCase reviewContribution;
  final GetReviewedContributionsUseCase getReviewed;
  final ReopenReviewUseCase reopenReview;
  final GetMemberPhotosUseCase getMemberPhotos;
  final String groupId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.period == null, clearError: true));
    try {
      final (cycle, period) = await getPotState.execute(groupId);
      List<Contribution> reviewed;
      try {
        reviewed = await getReviewed.execute(period.id);
      } catch (_) {
        reviewed = const [];
      }
      final reviews = await getPendingReviews.execute(period.id);
      emit(state.copyWith(cycle: cycle, period: period, reviews: reviews, reviewed: reviewed, isLoading: false));
      if (state.photos.isEmpty) emit(state.copyWith(photos: await getMemberPhotos.execute(groupId)));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  Future<void> reopen(String contributionId) async {
    if (state.reopening != null) return;
    emit(state.copyWith(reopening: contributionId, clearError: true));
    try {
      await reopenReview.execute(contributionId);
      emit(state.copyWith(clearReopening: true));
      await load();
    } catch (error) {
      emit(state.copyWith(clearReopening: true, errorMessage: userMessageOf(error)));
    }
  }

  /// True when the decision was saved.
  Future<bool> decide(String contributionId, ReviewDecision decision, String note) async {
    if (state.isSaving) return false;
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await reviewContribution.execute(contributionId, decision, note);
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}

String _issues(Contribution contribution) =>
    contribution.inconsistencies.map((item) => item.label.toLowerCase()).join(', ');

/// C7: "Aportes por revisar".
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  late final ReviewsViewModel viewModel = getIt<ReviewsViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _open(Contribution contribution) async {
    final wasLast = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ReviewDetailPage(viewModel: viewModel, contributionId: contribution.id)),
    );
    if (!mounted) return;
    // After the last review the organizer goes back to the pot.
    if (wasLast == true) {
      Navigator.pop(context);
    } else {
      viewModel.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Aportes por revisar')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final period = state.period;
          if (period == null) {
            return LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load);
          }
          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Estos comprobantes no coinciden con lo esperado. Revisa cada uno y decide si lo apruebas.',
                  style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (state.reviews.isEmpty)
                  InfoBanner(text: 'No hay aportes por revisar en el período ${period.turnNumber}.', icon: Icons.task_alt),
                ErrorText(state.errorMessage),
                for (final contribution in state.reviews)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      onTap: () => _open(contribution),
                      leading: InitialsAvatar(
                        name: contribution.memberName,
                        size: 40,
                        photoUrl: state.photos[contribution.membershipId],
                      ),
                      title: Text(contribution.memberName),
                      subtitle: Text('${Formats.soles(contribution.amount)} · ${_issues(contribution)}'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                if (state.reviewed.isNotEmpty) ...[
                  const SectionTitle('Ya revisados'),
                  for (final contribution in state.reviewed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(contribution.memberName),
                      subtitle: Text(
                        '${Formats.soles(contribution.amount)} · '
                        '${contribution.status == ContributionStatus.approved ? 'aprobado' : 'rechazado'}',
                      ),
                      trailing: TextButton(
                        onPressed: state.reopening == null ? () => viewModel.reopen(contribution.id) : null,
                        child: Text(state.reopening == contribution.id ? 'Volviendo…' : 'Volver a revisar'),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// C8: "Revisar aporte": what matches and what does not, the receipt and the decision. It shares the
/// view model of the list, so the list is up to date when it closes.
class ReviewDetailPage extends StatefulWidget {
  const ReviewDetailPage({super.key, required this.viewModel, required this.contributionId});

  final ReviewsViewModel viewModel;
  final String contributionId;

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  String note = '';

  Future<void> _decide(Contribution contribution, ReviewDecision decision) async {
    final viewModel = widget.viewModel;
    if (decision == ReviewDecision.approve) {
      final confirmed = await confirmAction(
        context,
        title: '¿Aprobar este aporte?',
        message: 'No coincide en: ${_issues(contribution)}. Contará como pagado por '
            '${contribution.memberName.split(' ').first}.',
        confirmLabel: 'Aprobar',
      );
      if (!confirmed) return;
    }
    final wasLast = viewModel.state.reviews.length <= 1;
    final saved = await viewModel.decide(contribution.id, decision, note);
    if (saved && mounted) Navigator.pop(context, wasLast);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar aporte')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          final contribution = state.reviews.where((item) => item.id == widget.contributionId).firstOrNull;
          if (contribution == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: InfoBanner(text: 'Este aporte ya fue revisado.'),
            );
          }
          final failed = {for (final item in contribution.inconsistencies) item.field};
          final receipt = contribution.receipt;
          final period = state.period;
          final cycle = state.cycle;
          final firstName = contribution.memberName.split(' ').first;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: InitialsAvatar(
                        name: contribution.memberName,
                        photoUrl: state.photos[contribution.membershipId],
                      ),
                      title: Text(contribution.memberName, style: text.titleMedium),
                      subtitle: Text(
                        'Período ${period?.turnNumber} · registrado el '
                        '${Formats.mediumDate(contribution.registeredAt.toLocal())}',
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _CheckRow(
                              title: 'Monto',
                              detail: '${Formats.soles(contribution.amount)} · esperado '
                                  '${period == null ? '' : Formats.soles(period.contributionAmount)}',
                              ok: !failed.contains('AMOUNT'),
                            ),
                            Divider(height: 1, color: colors.outlineVariant),
                            _CheckRow(
                              title: 'Enviado a',
                              detail: '${receipt?.payeeName ?? ''} · esperado ${cycle?.payeeName ?? ''}',
                              ok: !failed.contains('PAYEE'),
                            ),
                            Divider(height: 1, color: colors.outlineVariant),
                            _CheckRow(
                              title: 'Fecha',
                              detail: '${receipt == null ? '' : Formats.mediumDate(receipt.paidAt)} · corte '
                                  '${period == null ? '' : Formats.mediumDate(period.cutoffDate)}',
                              ok: !failed.contains('DATE'),
                            ),
                            Divider(height: 1, color: colors.outlineVariant),
                            _CheckRow(
                              title: 'N.º de operación',
                              detail: '${receipt?.operationNumber ?? ''} · no está repetido',
                              ok: true,
                            ),
                            for (final edit in contribution.inconsistencies.where((i) => i.field.startsWith('EDITED_')))
                              _CheckRow(
                                title: edit.label,
                                detail: 'Pozzo leyó ${edit.expected} · escribió ${edit.found}',
                                ok: false,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (contribution.hasReceiptImage) ...[
                      const SizedBox(height: 12),
                      PozzoOutlinedButton(
                        text: 'Ver comprobante',
                        icon: Icons.image_outlined,
                        onPressed: () => showReceiptImage(context, contribution.id),
                      ),
                    ],
                    const SizedBox(height: 16),
                    PozzoTextField(
                      label: 'Nota para $firstName (opcional)',
                      value: note,
                      maxLines: 3,
                      onChanged: (value) => setState(() => note = value.length > 200 ? value.substring(0, 200) : value),
                    ),
                    const SizedBox(height: 16),
                    InfoBanner(
                      text: 'Si lo apruebas, cuenta como aporte validado. Si lo rechazas, $firstName deberá registrarlo '
                          'de nuevo. Mientras no entregues el pozo, puedes volver a revisarlo.',
                    ),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  ErrorText(state.errorMessage),
                  Row(
                    children: [
                      Expanded(
                        child: PozzoOutlinedButton(
                          text: 'Rechazar',
                          enabled: !state.isSaving,
                          onPressed: () => _decide(contribution, ReviewDecision.reject),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PozzoOutlinedButton(
                          text: 'Aprobar',
                          enabled: !state.isSaving,
                          onPressed: () => _decide(contribution, ReviewDecision.approve),
                        ),
                      ),
                    ],
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

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.title, required this.detail, required this.ok});

  final String title;
  final String detail;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(ok ? Icons.check : Icons.close, color: ok ? status.success : colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                Text(detail, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          if (!ok)
            StatusChip(text: 'No coincide', background: colors.errorContainer, foreground: colors.onErrorContainer),
        ],
      ),
    );
  }
}
