import 'package:flutter/foundation.dart';
import 'package:pozzo/core/app_database.dart';
import 'package:pozzo/core/network/access_token_provider.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:sqflite/sqflite.dart';

enum SessionStatus { unknown, signedIn, signedOut }

/// Keeps the session on the phone (table `session` of sqflite): the token, the name of the member,
/// their visual theme and their photo. It is a [ChangeNotifier], so the root of the app moves between
/// the welcome and the groups when the session opens or closes, and repaints when the theme changes.
class SessionManager extends ChangeNotifier implements AccessTokenProvider {
  SessionManager({required this.appDatabase});

  final AppDatabase appDatabase;

  SessionStatus _status = SessionStatus.unknown;
  String? _token;
  String? _displayName;
  ThemePreference _theme = ThemePreference.system;
  String? _photoUrl;

  /// The member asked to join a group with a code before signing in; it opens once they are in.
  bool joinAfterSignIn = false;

  SessionStatus get status => _status;
  String? get displayName => _displayName;
  ThemePreference get theme => _theme;
  String? get photoUrl => _photoUrl;

  @override
  String? get currentToken => _token;

  /// Reads the session kept on the phone when the app starts.
  Future<void> load() async {
    final Database database = await appDatabase.database;
    final rows = await database.query('session');
    final values = {for (final row in rows) row['key'] as String: row['value'] as String?};
    _token = values['token'];
    _displayName = values['display_name'];
    _theme = ThemePreference.of(values['theme']);
    _photoUrl = values['photo_url'];
    _status = _token == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    notifyListeners();
  }

  Future<void> save(String token, String displayName, String theme) async {
    await _write({'token': token, 'display_name': displayName, 'theme': theme});
    _token = token;
    _displayName = displayName;
    _theme = ThemePreference.of(theme);
    _status = SessionStatus.signedIn;
    notifyListeners();
  }

  /// Keeps what is shown without a request: name, theme and photo.
  Future<void> updateProfile(String displayName, String theme, String? photoUrl) async {
    await _write({'display_name': displayName, 'theme': theme, 'photo_url': photoUrl});
    _displayName = displayName;
    _theme = ThemePreference.of(theme);
    _photoUrl = photoUrl;
    notifyListeners();
  }

  Future<void> clear() async {
    final Database database = await appDatabase.database;
    await database.delete('session');
    _token = null;
    _displayName = null;
    _photoUrl = null;
    _theme = ThemePreference.system;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  @override
  void onUnauthorized() {
    clear();
  }

  Future<void> _write(Map<String, String?> values) async {
    final Database database = await appDatabase.database;
    final batch = database.batch();
    for (final entry in values.entries) {
      batch.insert('session', {'key': entry.key, 'value': entry.value}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
