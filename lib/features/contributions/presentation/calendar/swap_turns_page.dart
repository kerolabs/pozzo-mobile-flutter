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
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

class SwapTurnsState {
  const SwapTurnsState({
    this.cycle,
    this.turns = const [],
    this.selected = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  final Cycle? cycle;

  /// The turns that have not started yet: only those can change.
  final List<Turn> turns;
  final List<String> selected;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  SwapTurnsState copyWith({
    Cycle? cycle,
    List<Turn>? turns,
    List<String>? selected,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SwapTurnsState(
      cycle: cycle ?? this.cycle,
      turns: turns ?? this.turns,
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// C5: two members who agreed to change their turns.
class SwapTurnsViewModel extends ViewModel<SwapTurnsState> {
  SwapTurnsViewModel({
    required this.getCycleOfGroup,
    required this.getTurns,
    required this.swapTurns,
    required this.groupId,
  }) : super(const SwapTurnsState()) {
    load();
  }

  final GetCycleOfGroupUseCase getCycleOfGroup;
  final GetTurnsUseCase getTurns;
  final SwapTurnsUseCase swapTurns;
  final String groupId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final cycle = await getCycleOfGroup.execute(groupId);
      final calendar = await getTurns.execute(groupId);
      final turns = calendar.turns.where((turn) => turn.turnNumber > cycle.currentTurn).toList();
      emit(state.copyWith(isLoading: false, cycle: cycle, turns: turns));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  /// Selects two members; a third replaces the first one chosen.
  void toggle(String membershipId) {
    final selected = state.selected;
    final List<String> next;
    if (selected.contains(membershipId)) {
      next = selected.where((id) => id != membershipId).toList();
    } else if (selected.length < 2) {
      next = [...selected, membershipId];
    } else {
      next = [...selected.skip(1), membershipId];
    }
    emit(state.copyWith(selected: next, clearError: true));
  }

  Future<bool> swap() async {
    final cycle = state.cycle;
    if (cycle == null || state.selected.length != 2 || state.isSaving) return false;
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await swapTurns.execute(cycle.id, state.selected[0], state.selected[1]);
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: userMessageOf(error)));
      return false;
    }
  }
}

/// C5: "Intercambiar turnos".
class SwapTurnsPage extends StatefulWidget {
  const SwapTurnsPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<SwapTurnsPage> createState() => _SwapTurnsPageState();
}

class _SwapTurnsPageState extends State<SwapTurnsPage> {
  late final SwapTurnsViewModel viewModel = getIt<SwapTurnsViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _swap() async {
    final swapped = await viewModel.swap();
    if (!swapped || !mounted) return;
    showMessage(context, 'Turnos intercambiados.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intercambiar turnos')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          if (state.cycle == null) {
            return LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load);
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Text(
                      'Elige a los dos integrantes que acordaron cambiar de turno.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (state.turns.length < 2) ...[
                      const SizedBox(height: 12),
                      const InfoBanner(
                        text: 'Quedan menos de dos turnos sin empezar, así que no hay nada que intercambiar.',
                      ),
                    ],
                    for (final turn in state.turns)
                      MemberOption(
                        name: turn.displayName,
                        subtitle: 'Turno ${turn.turnNumber} · corte ${Formats.mediumDate(turn.cutoffDate)}',
                        isMe: turn.isMe,
                        selected: state.selected.contains(turn.membershipId),
                        photoUrl: turn.photoUrl,
                        onTap: () => viewModel.toggle(turn.membershipId),
                      ),
                    const SizedBox(height: 12),
                    const InfoBanner(text: 'A los dos les llega un aviso con su nuevo turno.'),
                    ErrorText(state.errorMessage),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Intercambiar turnos',
                    icon: Icons.swap_vert,
                    onPressed: _swap,
                    enabled: state.selected.length == 2,
                    loading: state.isSaving,
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
