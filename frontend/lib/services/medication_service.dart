import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'api_service.dart';

/// Servicio de medicamentos (gestión de CRUD)
class MedicationService extends ChangeNotifier {
  final ApiService _apiService;
  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _errorMessage;

  MedicationService(this._apiService);

  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga lista de medicamentos desde API
  Future<void> loadMedications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _medications = await _apiService.getMedications();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega nuevo medicamento
  Future<bool> addMedication(Medication medication) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createMedication(medication);
      _medications.add(created);
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

  /// Actualiza un medicamento existente
  Future<bool> updateMedication(String id, Medication medication) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateMedication(id, medication);
      final index = _medications.indexWhere((m) => m.id == id);
      if (index >= 0) {
        _medications[index] = medication;
      }
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

  /// Elimina un medicamento
  Future<bool> deleteMedication(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteMedication(id);
      _medications.removeWhere((m) => m.id == id);
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
