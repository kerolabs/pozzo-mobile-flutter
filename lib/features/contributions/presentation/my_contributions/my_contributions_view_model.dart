import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';

class MyContributionsState {
  const MyContributionsState({this.contributions, this.isLoading = true, this.errorMessage});

  final MyContributions? contributions;
  final bool isLoading;
  final String? errorMessage;
}

/// C3: what the member contributed and what they owe in the cycle; it works without signal with the
/// last copy kept on the phone.
class MyContributionsViewModel extends ViewModel<MyContributionsState> {
  MyContributionsViewModel({required this.getMyContributions, required this.shareContribution, required this.groupId})
      : super(const MyContributionsState()) {
    load();
  }

  final GetMyContributionsUseCase getMyContributions;
  final ShareContributionUseCase shareContribution;
  final String groupId;

  Future<void> load() async {
    emit(MyContributionsState(contributions: state.contributions));
    try {
      emit(MyContributionsState(contributions: await getMyContributions.execute(groupId), isLoading: false));
    } catch (error) {
      emit(MyContributionsState(contributions: state.contributions, isLoading: false, errorMessage: userMessageOf(error)));
    }
  }

  /// The message with the verifiable link of a contribution, to paste in a chat.
  Future<String> shareText(MyPeriodContribution period) async {
    final contribution = period.contribution!;
    final url = await shareContribution.execute(contribution.id);
    final groupName = state.contributions?.groupName ?? '';
    return 'Mi aporte de ${Formats.soles(contribution.amount)} a $groupName, período ${period.turnNumber}, '
        'quedó registrado en Pozzo. Puedes verificarlo aquí: $url';
  }
}
