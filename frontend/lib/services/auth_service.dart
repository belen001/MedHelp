import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import 'api_service.dart';

/// Servicio de autenticación (gestor de estado de usuario y token)
class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthService(this._apiService);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Realiza login del usuario
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _apiService.login(email: email, password: password);
      _currentUser = user;
      // Set token in ApiService and persist session
      _apiService.setToken(user.token);
      await _saveSession(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Realiza registro del usuario
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _currentUser = user;
      // Set token and persist
      _apiService.setToken(user.token);
      await _saveSession(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Realiza logout (cierra sesión)
  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.logout();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      await _clearSession();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guarda sesión en SharedPreferences
  Future<void> _saveSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', user.token);
      await prefs.setInt('user_id', user.id);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_role', user.role);
    } catch (e) {
      if (kDebugMode) print('Error saving session: $e');
    }
  }

  /// Limpia sesión persistente
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
    } catch (e) {
      if (kDebugMode) print('Error clearing session: $e');
    }
  }

  /// Restaura sesión desde almacenamiento persistente
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;

      final id = prefs.getInt('user_id');
      final email = prefs.getString('user_email');
      final name = prefs.getString('user_name');
      final role = prefs.getString('user_role');

      if (id == null || email == null || name == null || role == null) return;

      _apiService.setToken(token);
      _currentUser = User(id: id, email: email, name: name, role: role, token: token);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error restoring session: $e');
    }
  }
}
