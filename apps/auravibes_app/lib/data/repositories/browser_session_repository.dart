import 'dart:convert';

import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class const BrowserSessionRepository(final SharedPreferences _preferences) {
  Future<BrowserSessionState> load(String sessionId) async {
    final stored = _preferences.getString(_key(sessionId));
    if (stored == null) return BrowserSessionState.initial();

    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, dynamic>) {
        return BrowserSessionState.initial();
      }

      return BrowserSessionState.fromJson(decoded);
    } on FormatException catch (_) {
      return BrowserSessionState.initial();
    }
  }

  Future<void> save(String sessionId, BrowserSessionState session) async {
    final saved = await _preferences.setString(
      _key(sessionId),
      jsonEncode(session.toJson()),
    );
    if (!saved) throw StateError('Could not persist browser tabs.');
  }

  String _key(String sessionId) => 'browser_session_$sessionId';
}
