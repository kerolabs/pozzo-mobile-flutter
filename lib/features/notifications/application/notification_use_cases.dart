import 'package:pozzo/features/notifications/domain/notifications.dart';

class GetMyNoticesUseCase {
  const GetMyNoticesUseCase({required this.repository});

  final NotificationRepository repository;

  Future<List<Notice>> execute() => repository.getMyNotices();
}

class GetReminderPlanUseCase {
  const GetReminderPlanUseCase({required this.repository});

  final NotificationRepository repository;

  Future<ReminderPlan> execute(String groupId) => repository.getReminderPlan(groupId);
}

class SaveReminderPlanUseCase {
  const SaveReminderPlanUseCase({required this.repository});

  final NotificationRepository repository;

  Future<ReminderPlan> execute(ReminderPlan plan) => repository.saveReminderPlan(plan);
}

/// How many notices arrived after the last one the member saw: the dot of the "Avisos" tab.
class CountUnseenNoticesUseCase {
  const CountUnseenNoticesUseCase({required this.repository});

  final NotificationRepository repository;

  Future<int> execute() async {
    final lastSeen = await repository.lastSeenAt();
    final notices = await repository.getMyNotices();
    return notices.where((notice) => lastSeen == null || notice.sentAt.isAfter(lastSeen)).length;
  }
}

class GetLastSeenNoticeUseCase {
  const GetLastSeenNoticeUseCase({required this.repository});

  final NotificationRepository repository;

  Future<DateTime?> execute() => repository.lastSeenAt();
}

class MarkNoticesSeenUseCase {
  const MarkNoticesSeenUseCase({required this.repository});

  final NotificationRepository repository;

  Future<void> execute(DateTime until) => repository.markSeen(until);
}
