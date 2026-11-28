import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// The local database of the application (sqflite), the counterpart of Room in the Kotlin version.
///
/// - `session`: the token and what is shown without a request (name, theme, photo), as key and value.
/// - `my_groups`: the groups of the member, so the list opens at once and works without signal.
/// - `cache`: other answers kept to show them offline, such as the contributions of the member.
class AppDatabase {
  Future<Database>? _database;

  Future<Database> get database => _database ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final path = join(await getDatabasesPath(), 'pozzo.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('create table session (key text primary key, value text)');
        await db.execute('create table my_groups (id text primary key, created_at text, payload text not null)');
        await db.execute('create table cache (key text primary key, payload text not null)');
      },
    );
  }
}
