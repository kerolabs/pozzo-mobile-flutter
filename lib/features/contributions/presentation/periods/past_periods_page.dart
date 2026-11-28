import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/presentation/widgets/contribution_widgets.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';

class PastPeriodsState {
  const PastPeriodsState({
    this.cycle,
    this.periods = const [],
    this.photos = const {},
    this.isLoading = true,
    this.errorMessage,
  });

  final Cycle? cycle;
  final List<Period> periods;
  final Map<String, String> photos;
  final bool isLoading;
  final String? errorMessage;
}

/// C6: the periods whose pot was already delivered, newest first.
class PastPeriodsViewModel extends ViewModel<PastPeriodsState> {
  PastPeriodsViewModel({required this.getCycleHistory, required this.getMemberPhotos, required this.groupId})
      : super(const PastPeriodsState()) {
    load();
  }

  final GetCycleHistoryUseCase getCycleHistory;
  final GetMemberPhotosUseCase getMemberPhotos;
  final String groupId;

  Future<void> load() async {
    emit(const PastPeriodsState());
    try {
      final (cycle, periods) = await getCycleHistory.execute(groupId);
      final delivered = periods.where((period) => period.state == PeriodState.delivered).toList()
        ..sort((a, b) => b.turnNumber.compareTo(a.turnNumber));
      emit(PastPeriodsState(cycle: cycle, periods: delivered, isLoading: false));
      final photos = await getMemberPhotos.execute(groupId);
      emit(PastPeriodsState(cycle: cycle, periods: delivered, photos: photos, isLoading: false));
    } catch (error) {
      emit(PastPeriodsState(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }
}

/// C6: "Períodos anteriores".
class PastPeriodsPage extends StatefulWidget {
  const PastPeriodsPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<PastPeriodsPage> createState() => _PastPeriodsPageState();
}

class _PastPeriodsPageState extends State<PastPeriodsPage> {
  late final PastPeriodsViewModel viewModel = getIt<PastPeriodsViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Períodos anteriores')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          if (state.cycle == null) {
            return LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.periods.isEmpty) const InfoBanner(text: 'Aún no se entrega ningún pozo en este ciclo.'),
              for (final period in state.periods) ...[
                _PeriodCard(period: period, photos: state.photos),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, required this.photos});

  final Period period;
  final Map<String, String> photos;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final deliveredAt = period.deliveredAt;
    final detail = StringBuffer('Recibió ${Formats.soles(period.payoutAmount)}');
    if (period.auctionDiscount > 0) {
      detail.write(' (descuento de subasta ${Formats.soles(period.auctionDiscount)})');
    }
    if (deliveredAt != null) detail.write(' · entregado el ${Formats.mediumDate(deliveredAt.toLocal())}');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Período ${period.turnNumber} · cobró ${period.payoutMemberName}', style: text.titleMedium),
            Text(detail.toString(), style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            for (final member in period.members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    InitialsAvatar(name: member.displayName, size: 28, photoUrl: photos[member.membershipId]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        member.isMe ? '${member.displayName} (tú)' : member.displayName,
                        style: text.bodyLarge,
                      ),
                    ),
                    ContributionStateChip(state: member.state, isMine: member.isMe),
                  ],
                ),
              ),
            if (period.hasPayoutProof) ...[
              const SizedBox(height: 8),
              PozzoOutlinedButton(
                text: 'Ver la transferencia del pozo',
                icon: Icons.image_outlined,
                onPressed: () => showPayoutProof(context, period.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
