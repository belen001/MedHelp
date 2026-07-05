import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'api_service.dart';

/// Servicio de tomas de medicamentos (dosis), basado en
/// GET /api/medications/today.
class DoseService extends ChangeNotifier {
  final ApiService _apiService;
  List<Dose> _dosesForToday = [];
  bool _isLoading = false;
  String? _errorMessage;

  DoseService(this._apiService);

  List<Dose> get dosesForToday => _dosesForToday;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga las tomas de hoy
  Future<void> loadTodaysDoses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dosesForToday = await _apiService.getTodaySchedule(date: DateTime.now());
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirma una toma y refresca la lista para reflejar el estado real
  Future<bool> confirmDose(Dose dose) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.confirmDose(dose);
      await loadTodaysDoses(); // re-sincroniza con el backend
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Marca una toma como omitida
  Future<bool> skipDose(Dose dose, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.skipDose(dose, reason: reason);
      await loadTodaysDoses();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Pospone una toma X minutos. el backend no cambia el status
  /// de la dosis al posponer, solo agenda un recordatorio nuevo — así
  /// que la dosis sigue apareciendo "Pendiente" después de esto.
  Future<bool> postponeDose(Dose dose, {int minutes = 15}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.snoozeDose(dose, minutes: minutes);
      await loadTodaysDoses();
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
