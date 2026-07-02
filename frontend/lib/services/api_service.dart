import 'dart:convert';
import 'package:flutter/foundation.dart';
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

/// Servicio base de API REST
/// Simula conexión con backend Spring Boot en http://localhost:8080
/// En producción, configurar baseUrl desde environment/config.
class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  String? _token; // JWT token almacenado

  /// Obtiene el header Authorization si hay token disponible
  // ignore: unused_element
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

  /// Establece el token JWT (después de login)
  void setToken(String token) {
    _token = token;
  }

  /// Limpia el token (logout)
  void clearToken() {
    _token = null;
  }

  // ============= AUTH ENDPOINTS =============

  /// POST /api/auth/login
  /// Retorna User con token
  Future<User> login({required String email, required String password}) async {
    try {
      // ignore: unused_local_variable
      final body = jsonEncode({'email': email, 'password': password});

      // Simulación para demo; en producción usar http.post()
      if (kDebugMode) {
        // Simular respuesta exitosa de login
        await Future.delayed(const Duration(milliseconds: 500));
        final mockResponse = {
          'id': 'user_1',
          'email': 'user@example.com',
          'fullName': 'Juan Pérez',
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock',
          'profileImageUrl': null,
        };
        final user = User.fromJson(mockResponse);
        setToken(user.token);
        return user;
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error en login',
        originalError: e,
      );
    }
  }

  /// POST /api/auth/register
  /// Retorna User con token
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // ignore: unused_local_variable
      final body = jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
      });

      // Simulación para demo
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        final mockResponse = {
          'id': 'user_new_1',
          'email': email,
          'fullName': fullName,
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock',
          'profileImageUrl': null,
        };
        final user = User.fromJson(mockResponse);
        setToken(user.token);
        return user;
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error en registro',
        originalError: e,
      );
    }
  }

  // ============= MEDICATIONS ENDPOINTS =============

  /// GET /api/medications
  /// Retorna lista de medicamentos del usuario
  Future<List<Medication>> getMedications() async {
    try {
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        final mockResponse = <Map<String, dynamic>>[
          {
            'id': 'med_1',
            'name': 'Ibuprofeno',
            'dosage': '200 mg',
            'frequency': 'daily',
            'startDate': '2024-01-01T00:00:00',
            'endDate': null,
            'instructions': 'Tomar después de las comidas',
            'timeOfDay': 'morning',
            'customTime': null,
            'createdAt': '2024-01-01T00:00:00',
            'updatedAt': '2024-01-01T00:00:00',
          },
          {
            'id': 'med_2',
            'name': 'Metformina',
            'dosage': '500 mg',
            'frequency': 'twiceeday',
            'startDate': '2024-01-01T00:00:00',
            'endDate': null,
            'instructions': 'Con agua',
            'timeOfDay': 'custom',
            'customTime': '08:00',
            'createdAt': '2024-01-01T00:00:00',
            'updatedAt': '2024-01-01T00:00:00',
          },
        ];
        return mockResponse.map((json) => Medication.fromJson(json)).toList();
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al obtener medicamentos',
        originalError: e,
      );
    }
  }

  /// POST /api/medications
  /// Crea un nuevo medicamento
  Future<Medication> createMedication(Medication medication) async {
    try {
      // ignore: unused_local_variable
      final body = jsonEncode(medication.toJson());

      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 400));
        return medication;
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al crear medicamento',
        originalError: e,
      );
    }
  }

  /// PUT /api/medications/{id}
  /// Actualiza un medicamento existente
  Future<Medication> updateMedication(String id, Medication medication) async {
    try {
      // ignore: unused_local_variable
      final body = jsonEncode(medication.toJson());

      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 400));
        return medication;
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al actualizar medicamento',
        originalError: e,
      );
    }
  }

  /// DELETE /api/medications/{id}
  /// Elimina un medicamento
  Future<void> deleteMedication(String id) async {
    try {
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        return;
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al eliminar medicamento',
        originalError: e,
      );
    }
  }

  // ============= DOSES ENDPOINTS =============

  /// GET /api/doses?date=YYYY-MM-DD
  /// Retorna tomas programadas para un día específico
  Future<List<Dose>> getDosesForDate(DateTime date) async {
    try {
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        final mockResponse = <Map<String, dynamic>>[
          {
            'id': 'dose_1',
            'medicationId': 'med_1',
            'medicationName': 'Ibuprofeno',
            'dosage': '200 mg',
            'scheduledTime': '2024-07-02T08:00:00',
            'completedTime': null,
            'status': 'pending',
            'notes': null,
          },
          {
            'id': 'dose_2',
            'medicationId': 'med_2',
            'medicationName': 'Metformina',
            'dosage': '500 mg',
            'scheduledTime': '2024-07-02T14:00:00',
            'completedTime': '2024-07-02T14:05:00',
            'status': 'completed',
            'notes': null,
          },
        ];
        return mockResponse.map((json) => Dose.fromJson(json)).toList();
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al obtener tomas del día',
        originalError: e,
      );
    }
  }

  /// POST /api/doses/confirm
  /// Confirma que una toma fue completada
  Future<Dose> confirmDose(String doseId) async {
    try {
      // ignore: unused_local_variable
      final body = jsonEncode({'doseId': doseId});

      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        // Retornar una dosis con estado actualizado
        return Dose(
          id: doseId,
          medicationId: 'med_1',
          medicationName: 'Ibuprofeno',
          dosage: '200 mg',
          scheduledTime: DateTime.now(),
          completedTime: DateTime.now(),
          status: DoseStatus.completed,
        );
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al confirmar toma',
        originalError: e,
      );
    }
  }

  /// POST /api/doses/postpone
  /// Pospone una toma X minutos
  Future<Dose> postponeDose(String doseId, {int minutes = 15}) async {
    try {
      // ignore: unused_local_variable
      final body = jsonEncode({'doseId': doseId, 'minutes': minutes});

      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        final newTime = DateTime.now().add(Duration(minutes: minutes));
        return Dose(
          id: doseId,
          medicationId: 'med_1',
          medicationName: 'Ibuprofeno',
          dosage: '200 mg',
          scheduledTime: newTime,
          status: DoseStatus.postponed,
        );
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al posponer toma',
        originalError: e,
      );
    }
  }

  // ============= CONTACTS ENDPOINTS =============

  /// GET /api/contacts
  /// Retorna lista de contactos de emergencia del usuario
  Future<List<Contact>> getContacts() async {
    try {
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        final mockResponse = <Map<String, dynamic>>[
          {
            'id': 'contact_1',
            'name': 'Dr. García',
            'phone': '+34 666 777 888',
            'email': 'garcia@hospital.com',
            'specialty': 'Cardiólogo',
            'type': 'doctor',
            'createdAt': '2024-01-01T00:00:00',
          },
        ];
        return mockResponse.map((json) => Contact.fromJson(json)).toList();
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al obtener contactos',
        originalError: e,
      );
    }
  }

  /// POST /api/contacts
  /// Crea un nuevo contacto de emergencia
  Future<Contact> createContact(Contact contact) async {
    try {
      // ignore: unused_local_variable
      final body = jsonEncode(contact.toJson());

      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        return contact;
      }

      throw ApiException(
        message: 'No fue posible conectarse con el servidor. Intente nuevamente más tarde',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error al crear contacto',
        originalError: e,
      );
    }
  }
}
