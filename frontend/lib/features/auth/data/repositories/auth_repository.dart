import 'package:qa_insight_hub/core/services/api_service.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/core/services/session_storage.dart';

class AuthRepository {
  AuthRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final SessionStorage _sessionStorage = SessionStorage();

  Future<AuthSession> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Username and password are required');
    }
    final session = await _apiService.login(username: username, password: password);
    await _sessionStorage.saveSession(session);
    return session;
  }

  Future<void> logout(AuthSession session) async {
    await _apiService.logout(session.token);
    await _sessionStorage.clearSession();
  }

  Future<AuthSession?> getSavedSession() async {
    return _sessionStorage.getSession();
  }

  Future<Map<String, dynamic>> getBackendStatus() async {
    return _apiService.getHealth();
  }

  Future<void> clearSession() async {
    await _sessionStorage.clearSession();
  }

  Future<void> saveSession(AuthSession session) async {
    await _sessionStorage.saveSession(session);
  }

  Future<AuthSession> loginWithDemoRole(String role) async {
    final credentials = switch (role) {
      'assembly_user' => ('assembly_user', 'assembly123'),
      'qa_representative' => ('qa_representative', 'qa123'),
      'management_viewer' => ('management_viewer', 'viewer123'),
      _ => ('admin', 'admin123'),
    };

    final session = await _apiService.login(
      username: credentials.$1,
      password: credentials.$2,
    );
    await _sessionStorage.saveSession(session);
    return session;
  }

  Future<AuthSession> refreshSessionOrThrow() async {
    final session = await getSavedSession();
    if (session == null) {
      throw Exception('No active session found');
    }
    return session;
  }
}
