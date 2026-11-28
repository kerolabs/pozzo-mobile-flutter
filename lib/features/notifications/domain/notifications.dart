enum NotificationKind { reminder, alert }

/// A notice of the inbox: a reminder before the cutoff or something that happened in a group.
class Notice {
  const Notice({
    required this.id,
    required this.groupId,
    required this.kind,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.sentAt,
  });

  final String id;
  final String? groupId;
  final NotificationKind kind;
  final String title;
  final String body;

  /// The screen it opens, as "pozzo://groups/{id}/reviews".
  final String? deepLink;
  final DateTime sentAt;
}

/// When the reminders of a group are sent: days before the cutoff and the hour.
class ReminderPlan {
  const ReminderPlan({required this.groupId, required this.offsetsInDays, required this.sendHour, required this.enabled});

  final String groupId;
  final List<int> offsetsInDays;
  final int sendHour;
  final bool enabled;

  ReminderPlan copyWith({bool? enabled}) =>
      ReminderPlan(groupId: groupId, offsetsInDays: offsetsInDays, sendHour: sendHour, enabled: enabled ?? this.enabled);
}

abstract class NotificationRepository {
  Future<List<Notice>> getMyNotices();

  Future<ReminderPlan> getReminderPlan(String groupId);

  Future<ReminderPlan> saveReminderPlan(ReminderPlan plan);

  /// The newest notice the member already saw, kept on the phone.
  Future<DateTime?> lastSeenAt();

  Future<void> markSeen(DateTime until);
}
