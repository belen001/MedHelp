import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/index.dart';

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Servicio base de API REST — conectado al backend Spring Boot real
/// en http://10.0.2.2:8080/api (alias del emulador Android hacia el
/// localhost del PC). cambiar de acuerdo a la config de cada entorno
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );
  String? _token;

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  /// Decodifica una respuesta ApiResponse {success, message, data, errors}
  Map<String, dynamic> _decodeApiResponse(http.Response response) {
    late Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'Respuesta inválida del servidor',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    // Errores de validación traen {errors: {campo: [mensajes]}}
    if (json['errors'] != null) {
      final errors = json['errors'] as Map<String, dynamic>;
      final firstField = errors.values.first;
      final firstMessage = (firstField as List).first as String;
      throw ApiException(message: firstMessage, statusCode: response.statusCode);
    }

    throw ApiException(
      message: json['message'] as String? ??
          'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      statusCode: response.statusCode,
    );
  }

  Future<http.Response> _get(String path) {
    if (kDebugMode) print('🌐 GET $baseUrl$path');
    return http
        .get(Uri.parse('$baseUrl$path'), headers: _getHeaders())
        .timeout(const Duration(seconds: 10),
            onTimeout: () => throw ApiException(
                message:
                    'No fue posible conectarse con el servidor. Intente nuevamente más tarde'));
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    if (kDebugMode) print('🌐 POST $baseUrl$path -> ${jsonEncode(body)}');
    return http
        .post(Uri.parse('$baseUrl$path'),
            headers: _getHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10),
            onTimeout: () => throw ApiException(
                message:
                    'No fue posible conectarse con el servidor. Intente nuevamente más tarde'));
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) {
    if (kDebugMode) print('🌐 PUT $baseUrl$path -> ${jsonEncode(body)}');
    return http
        .put(Uri.parse('$baseUrl$path'),
            headers: _getHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10),
            onTimeout: () => throw ApiException(
                message:
                    'No fue posible conectarse con el servidor. Intente nuevamente más tarde'));
  }

  Future<http.Response> _delete(String path) {
    if (kDebugMode) print('🌐 DELETE $baseUrl$path');
    return http
        .delete(Uri.parse('$baseUrl$path'), headers: _getHeaders())
        .timeout(const Duration(seconds: 10),
            onTimeout: () => throw ApiException(
                message:
                    'No fue posible conectarse con el servidor. Intente nuevamente más tarde'));
  }

  // ============= AUTH ENDPOINTS =============

  Future<void> logout() async {
    try {
      if (_token == null) {
        clearToken();
        return;
      }
      final response = await _post('/auth/logout', {});
      if (kDebugMode) print('📥 Logout status: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('Error logout: $e');
    } finally {
      clearToken();
    }
  }

  Future<User> login({required String email, required String password}) async {
    final response =
        await _post('/auth/login', {'email': email, 'password': password});
    final json = _decodeApiResponse(response);
    final token = json['token'] as String;
    final user = User.fromJson(json['user'] as Map<String, dynamic>, token: token);
    setToken(token);
    return user;
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    final json = _decodeApiResponse(response);
    final token = json['token'] as String;
    final user = User.fromJson(json['user'] as Map<String, dynamic>, token: token);
    setToken(token);
    return user;
  }

  // ============= MEDICATIONS ENDPOINTS =============

  Future<List<Medication>> getMedications({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await _get('/medications$query');
    final json = _decodeApiResponse(response);
    final data = json['data'] as List<dynamic>;
    return data
        .map((item) => Medication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Medication> createMedication(Medication medication) async {
    final response = await _post('/medications', medication.toRequestJson());
    final json = _decodeApiResponse(response);
    return Medication.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Medication> updateMedication(int id, Medication medication) async {
    final response = await _put('/medications/$id', medication.toRequestJson());
    final json = _decodeApiResponse(response);
    return Medication.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMedication(int id) async {
    final response = await _delete('/medications/$id');
    _decodeApiResponse(response);
  }

  // ============= DOSES / TODAY SCHEDULE ENDPOINTS =============

  /// GET /api/medications/today — trae el schedule agrupado por horario
  /// y lo aplana a una lista de [Dose] (una por medicamento+horario).
  Future<List<Dose>> getTodaySchedule({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = Dose.formatDate(targetDate);
    final response = await _get('/medications/today?date=$dateStr');
    final json = _decodeApiResponse(response);
    final data = json['data'] as Map<String, dynamic>;
    final schedule = data['schedule'] as Map<String, dynamic>;

    final doses = <Dose>[];
    schedule.forEach((timeKey, items) {
      for (final item in (items as List<dynamic>)) {
        doses.add(Dose.fromScheduleItem(
          date: targetDate,
          timeKey: timeKey,
          json: item as Map<String, dynamic>,
        ));
      }
    });

    // Ordenar por hora para que el agrupamiento Mañana/Tarde/Noche
    // muestre las dosis en orden cronológico dentro de cada grupo.
    doses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return doses;
  }

  /// POST /api/doses/confirm
  Future<void> confirmDose(Dose dose) async {
    final response = await _post('/doses/confirm', {
      'medication_id': dose.medicationId,
      'dose_date': dose.doseDateStr,
      'dose_time': dose.doseTimeStr,
    });
    _decodeApiResponse(response);
  }

  /// POST /api/doses/skip
  Future<void> skipDose(Dose dose, {String? reason}) async {
    final response = await _post('/doses/skip', {
      'medication_id': dose.medicationId,
      'dose_date': dose.doseDateStr,
      'dose_time': dose.doseTimeStr,
      if (reason != null) 'reason': reason,
    });
    _decodeApiResponse(response);
  }

  /// POST /api/doses/snooze
  Future<void> snoozeDose(Dose dose, {int minutes = 15}) async {
    final response = await _post('/doses/snooze', {
      'medication_id': dose.medicationId,
      'dose_date': dose.doseDateStr,
      'dose_time': dose.doseTimeStr,
      'minutes': minutes,
    });
    _decodeApiResponse(response);
  }

  // ============= CONTACTS ENDPOINTS =============

  Future<List<Contact>> getContacts({String? relationship}) async {
    final query = relationship != null ? '?relationship=$relationship' : '';
    final response = await _get('/contacts$query');
    final json = _decodeApiResponse(response);
    final data = json['data'] as List<dynamic>;
    return data
        .map((item) => Contact.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Contact> createContact(Contact contact) async {
    final response = await _post('/contacts', contact.toRequestJson());
    final json = _decodeApiResponse(response);
    return Contact.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Contact> updateContact(int id, Contact contact) async {
    final response = await _put('/contacts/$id', contact.toRequestJson());
    final json = _decodeApiResponse(response);
    return Contact.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteContact(int id) async {
    final response = await _delete('/contacts/$id');
    _decodeApiResponse(response);
  }
}
