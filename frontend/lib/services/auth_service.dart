import 'package:flutter/foundation.dart';
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
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _apiService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      _currentUser = user;
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

  /// Limpia la sesión del usuario (logout)
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    _apiService.clearToken();
    notifyListeners();
  }

  /// Restaura sesión desde almacenamiento persistente (implementar con SharedPreferences)
  Future<void> restoreSession() async {
    // TODO: Implementar con SharedPreferences para persistencia
    // Por ahora no hace nada
  }
}
