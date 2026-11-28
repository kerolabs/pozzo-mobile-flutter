import 'dart:convert';

import 'package:pozzo/core/app_database.dart';
import 'package:pozzo/features/savings_groups/infrastructure/remote/group_dtos.dart';
import 'package:sqflite/sqflite.dart';

/// The groups of the member kept on the phone (table `my_groups`), newest first.
class GroupDao {
  const GroupDao({required this.appDatabase});

  final AppDatabase appDatabase;

  Future<List<GroupDto>> getAll() async {
    final Database database = await appDatabase.database;
    final rows = await database.query('my_groups', orderBy: 'created_at desc');
    return rows.map((row) => GroupDto.fromJson(jsonDecode(row['payload'] as String) as Map<String, dynamic>)).toList();
  }

  Future<void> upsert(GroupDto group) async {
    final Database database = await appDatabase.database;
    await database.insert('my_groups', _row(group), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> replaceAll(List<GroupDto> groups) async {
    final Database database = await appDatabase.database;
    await database.transaction((txn) async {
      await txn.delete('my_groups');
      for (final group in groups) {
        await txn.insert('my_groups', _row(group));
      }
    });
  }

  Future<void> deleteById(String groupId) async {
    final Database database = await appDatabase.database;
    await database.delete('my_groups', where: 'id = ?', whereArgs: [groupId]);
  }

  Future<void> deleteAll() async {
    final Database database = await appDatabase.database;
    await database.delete('my_groups');
  }

  Map<String, Object?> _row(GroupDto group) =>
      {'id': group.id, 'created_at': group.createdAt, 'payload': jsonEncode(group.json)};
}
