import 'package:pozzo/features/notifications/domain/notifications.dart';
import 'package:pozzo/features/notifications/infrastructure/local/notice_preferences.dart';
import 'package:pozzo/features/notifications/infrastructure/remote/notifications_api.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({required this.api, required this.preferences});

  final NotificationsApi api;
  final NoticePreferences preferences;

  @override
  Future<List<Notice>> getMyNotices() async {
    final notices = await api.getMyNotices();
    return notices..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  @override
  Future<ReminderPlan> getReminderPlan(String groupId) => api.getReminderPlan(groupId);

  @override
  Future<ReminderPlan> saveReminderPlan(ReminderPlan plan) => api.saveReminderPlan(plan);

  @override
  Future<DateTime?> lastSeenAt() => preferences.lastSeenAt();

  @override
  Future<void> markSeen(DateTime until) => preferences.saveLastSeenAt(until);
}
