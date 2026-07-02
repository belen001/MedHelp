import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'api_service.dart';

/// Servicio de tomas de medicamentos (dosis)
class DoseService extends ChangeNotifier {
  final ApiService _apiService;
  List<Dose> _dosesForToday = [];
  bool _isLoading = false;
  String? _errorMessage;

  DoseService(this._apiService);

  List<Dose> get dosesForToday => _dosesForToday;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga tomas de hoy agrupadas por período del día
  Future<void> loadTodaysDoses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dosesForToday = await _apiService.getDosesForDate(DateTime.now());
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirma que una toma fue completada
  Future<bool> confirmDose(String doseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.confirmDose(doseId);
      final index = _dosesForToday.indexWhere((d) => d.id == doseId);
      if (index >= 0) {
        _dosesForToday[index] = updated;
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

  /// Pospone una toma 15 minutos (o X minutos)
  Future<bool> postponeDose(String doseId, {int minutes = 15}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.postponeDose(doseId, minutes: minutes);
      final index = _dosesForToday.indexWhere((d) => d.id == doseId);
      if (index >= 0) {
        _dosesForToday[index] = updated;
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

  /// Agrupa tomas por período del día (Mañana/Tarde/Noche)
  Map<String, List<Dose>> getDosesByTimeOfDay() {
    final grouped = <String, List<Dose>>{};
    for (var dose in _dosesForToday) {
      final timeLabel = Dose.getTimeOfDayLabel(dose.scheduledTime);
      grouped.putIfAbsent(timeLabel, () => []);
      grouped[timeLabel]!.add(dose);
    }
    return grouped;
  }
}
