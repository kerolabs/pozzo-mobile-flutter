import 'dart:convert';

import 'package:pozzo/core/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// The last answer of "my contributions" of each group (table `cache`), to show it without signal.
class MyContributionsDao {
  const MyContributionsDao({required this.appDatabase});

  final AppDatabase appDatabase;

  static String _key(String groupId) => 'my_contributions/$groupId';

  /// The JSON kept and when it was saved, or null.
  Future<(Map<String, dynamic>, DateTime)?> find(String groupId) async {
    final Database database = await appDatabase.database;
    final rows = await database.query('cache', where: 'key = ?', whereArgs: [_key(groupId)]);
    if (rows.isEmpty) return null;
    final payload = jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
    return (payload['json'] as Map<String, dynamic>, DateTime.parse(payload['savedAt'] as String));
  }

  Future<void> upsert(String groupId, Map<String, dynamic> json, DateTime savedAt) async {
    final Database database = await appDatabase.database;
    await database.insert(
      'cache',
      {
        'key': _key(groupId),
        'payload': jsonEncode({'json': json, 'savedAt': savedAt.toIso8601String()}),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAll() async {
    final Database database = await appDatabase.database;
    await database.delete('cache', where: 'key like ?', whereArgs: ['my_contributions/%']);
  }
}
