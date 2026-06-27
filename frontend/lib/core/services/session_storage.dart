import 'dart:convert';

import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _sessionKey = 'qa_insight_session';

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<AuthSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) {
      return null;
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AuthSession.fromJson(map);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
