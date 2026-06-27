import 'package:flutter/foundation.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/features/auth/data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  AuthSession? _session;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthSession? get session => _session;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _session = null;
    notifyListeners();

    try {
      _session = await _repository.login(username, password);
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> quickDemoLogin(String role) async {
    _isLoading = true;
    _errorMessage = null;
    _session = null;
    notifyListeners();
    try {
      _session = await _repository.loginWithDemoRole(role);
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
