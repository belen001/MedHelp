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

  Future<void> loadMedications({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _medications = await _apiService.getMedications(status: status);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<bool> updateMedication(int id, Medication medication) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateMedication(id, medication);
      final index = _medications.indexWhere((m) => m.id == id);
      if (index >= 0) {
        _medications[index] = updated;
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

  Future<bool> deleteMedication(int id) async {
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
