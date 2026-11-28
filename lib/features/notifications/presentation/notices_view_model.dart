import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/notifications/application/notification_use_cases.dart';
import 'package:pozzo/features/notifications/domain/notifications.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

class ReminderSettings {
  const ReminderSettings({required this.groupId, required this.groupName, required this.plan, this.isSaving = false});

  final String groupId;
  final String groupName;
  final ReminderPlan plan;
  final bool isSaving;
}

/// The member already paid this period: Pozzo stops reminding them.
class StoppedReminders {
  const StoppedReminders({required this.groupId, required this.groupName, required this.turnNumber});

  final String groupId;
  final String groupName;
  final int turnNumber;
}

class NoticesState {
  const NoticesState({
    this.notices = const [],
    this.unseenAfter,
    this.reminders = const [],
    this.stopped = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<Notice> notices;
  final DateTime? unseenAfter;
  final List<ReminderSettings> reminders;
  final List<StoppedReminders> stopped;
  final bool isLoading;
  final String? errorMessage;

  bool isUnseen(Notice notice) => unseenAfter == null || notice.sentAt.isAfter(unseenAfter!);

  NoticesState copyWith({
    List<Notice>? notices,
    DateTime? unseenAfter,
    List<ReminderSettings>? reminders,
    List<StoppedReminders>? stopped,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NoticesState(
      notices: notices ?? this.notices,
      unseenAfter: unseenAfter ?? this.unseenAfter,
      reminders: reminders ?? this.reminders,
      stopped: stopped ?? this.stopped,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// N1: the inbox of the member, the reminders of the groups they organize and the ones already stopped.
class NoticesViewModel extends ViewModel<NoticesState> {
  NoticesViewModel({
    required this.getMyNotices,
    required this.getLastSeen,
    required this.markSeen,
    required this.getLocalGroups,
    required this.getReminderPlan,
    required this.saveReminderPlan,
    required this.getPotState,
  }) : super(const NoticesState()) {
    load();
  }

  final GetMyNoticesUseCase getMyNotices;
  final GetLastSeenNoticeUseCase getLastSeen;
  final MarkNoticesSeenUseCase markSeen;
  final GetLocalGroupsUseCase getLocalGroups;
  final GetReminderPlanUseCase getReminderPlan;
  final SaveReminderPlanUseCase saveReminderPlan;
  final GetPotStateUseCase getPotState;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.notices.isEmpty && state.reminders.isEmpty, clearError: true));
    final started = (await getLocalGroups.execute()).where((group) => group.status == GroupStatus.started).toList();
    final reminders = await Future.wait([
      for (final group in started.where((group) => group.isOrganizer))
        getReminderPlan
            .execute(group.id)
            .then<ReminderSettings?>((plan) => ReminderSettings(groupId: group.id, groupName: group.name, plan: plan))
            .catchError((_) => null),
    ]);
    final stopped = await Future.wait([
      for (final group in started)
        getPotState.execute(group.id).then<StoppedReminders?>((pot) {
          final period = pot.$2;
          return period.myState?.isSettled == true
              ? StoppedReminders(groupId: group.id, groupName: group.name, turnNumber: period.turnNumber)
              : null;
        }).catchError((_) => null),
    ]);
    final lastSeen = await getLastSeen.execute();
    try {
      final notices = await getMyNotices.execute();
      emit(
        state.copyWith(
          notices: notices,
          unseenAfter: state.notices.isEmpty ? lastSeen : state.unseenAfter,
          reminders: reminders.nonNulls.toList(),
          stopped: stopped.nonNulls.toList(),
          isLoading: false,
        ),
      );
      if (notices.isNotEmpty) await markSeen.execute(notices.first.sentAt);
    } catch (error) {
      emit(
        state.copyWith(
          reminders: reminders.nonNulls.toList(),
          stopped: stopped.nonNulls.toList(),
          isLoading: false,
          errorMessage: userMessageOf(error),
        ),
      );
    }
  }

  Future<void> setRemindersEnabled(String groupId, bool enabled) async {
    final settings = state.reminders.where((item) => item.groupId == groupId).firstOrNull;
    if (settings == null) return;
    _update(groupId, ReminderSettings(groupId: groupId, groupName: settings.groupName, plan: settings.plan.copyWith(enabled: enabled), isSaving: true));
    try {
      final saved = await saveReminderPlan.execute(settings.plan.copyWith(enabled: enabled));
      _update(groupId, ReminderSettings(groupId: groupId, groupName: settings.groupName, plan: saved));
    } catch (error) {
      _update(groupId, settings);
      emit(state.copyWith(errorMessage: userMessageOf(error)));
    }
  }

  void _update(String groupId, ReminderSettings settings) => emit(
        state.copyWith(reminders: [for (final item in state.reminders) item.groupId == groupId ? settings : item]),
      );
}
