import 'package:pozzo/core/network/api_client.dart';
import 'package:pozzo/features/notifications/domain/notifications.dart';

/// Endpoints of Notifications: the inbox of the member and the reminder plan of each group.
class NotificationsApi {
  const NotificationsApi({required this.client});

  final ApiClient client;

  static ReminderPlan _plan(Map<String, dynamic> json) => ReminderPlan(
        groupId: json['groupId'] as String,
        offsetsInDays: ((json['offsetsInDays'] as List? ?? []).cast<int>().toList())..sort((a, b) => b.compareTo(a)),
        sendHour: json['sendHour'] as int? ?? 9,
        enabled: json['enabled'] as bool? ?? false,
      );

  Future<List<Notice>> getMyNotices() async {
    final list = (await client.get('members/me/notifications') as List).cast<Map<String, dynamic>>();
    return [
      for (final item in list)
        Notice(
          id: item['id'] as String,
          groupId: item['groupId'] as String?,
          kind: item['kind'] == 'REMINDER' ? NotificationKind.reminder : NotificationKind.alert,
          title: item['title'] as String? ?? '',
          body: item['body'] as String? ?? '',
          deepLink: item['deepLink'] as String?,
          sentAt: DateTime.parse(item['sentAt'] as String),
        ),
    ];
  }

  Future<ReminderPlan> getReminderPlan(String groupId) async =>
      _plan(await client.get('groups/$groupId/reminder-plan') as Map<String, dynamic>);

  Future<ReminderPlan> saveReminderPlan(ReminderPlan plan) async => _plan(
        await client.put(
          'groups/${plan.groupId}/reminder-plan',
          body: {'offsetsInDays': plan.offsetsInDays, 'sendHour': plan.sendHour, 'enabled': plan.enabled},
        ) as Map<String, dynamic>,
      );
}
