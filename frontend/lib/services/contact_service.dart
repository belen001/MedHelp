import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'api_service.dart';

/// Servicio de contactos de emergencia
class ContactService extends ChangeNotifier {
  final ApiService _apiService;
  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  ContactService(this._apiService);

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga contactos desde API
  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contacts = await _apiService.getContacts();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega nuevo contacto
  Future<bool> addContact(Contact contact) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createContact(contact);
      _contacts.add(created);
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
}
