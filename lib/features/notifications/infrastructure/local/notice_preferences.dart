import 'package:pozzo/core/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// The moment of the newest notice the member saw (table `cache`), to mark the new ones.
class NoticePreferences {
  const NoticePreferences({required this.appDatabase});

  final AppDatabase appDatabase;

  static const _key = 'notices/last_seen_at';

  Future<DateTime?> lastSeenAt() async {
    final Database database = await appDatabase.database;
    final rows = await database.query('cache', where: 'key = ?', whereArgs: [_key]);
    return rows.isEmpty ? null : DateTime.parse(rows.first['payload'] as String);
  }

  Future<void> saveLastSeenAt(DateTime at) async {
    final Database database = await appDatabase.database;
    await database.insert(
      'cache',
      {'key': _key, 'payload': at.toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
