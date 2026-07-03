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

/// Servicio base de API REST
/// Simula conexión con backend Spring Boot en http://localhost:8080
/// En producción, configurar baseUrl desde environment/config.
class ApiService {
  // Base API URL. Override at build time with --dart-define, e.g.:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080/api');
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

  /// POST /api/auth/logout
  /// Cierra sesión en el backend
  Future<void> logout() async {
    try {
      if (_token == null) {
        if (kDebugMode) print('⚠ No hay token para logout');
        clearToken();
        return;
      }

      if (kDebugMode) {
        print(' REQUEST: POST $baseUrl/auth/logout');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw ApiException(
          message: 'Tiempo de conexión agotado',
        ),
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      // Esperar JSON: { success: true, message: "..." }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          if (json['success'] == true) {
            clearToken();
            if (kDebugMode) print('Logout exitoso');
            return;
          } else {
            // Aunque backend indique failure, limpiar token localmente
            clearToken();
            if (kDebugMode) print('Logout fallido: ${json['message']}');
            return;
          }
        } catch (_) {
          // Respuesta no JSON válida, igual limpiar token
          clearToken();
          return;
        }
      }

      // En otros casos, limpiar token localmente
      clearToken();
    } catch (e) {
      if (kDebugMode) print(' Error logout: $e');
      // Limpiar token de todas formas
      clearToken();
    }
  }

  // ============= AUTH ENDPOINTS =============

  /// POST /api/auth/login
  /// Retorna User con token según contrato:
  /// { success: true, token: "...", user: { id, name, email, role }, message?: "..." }
  Future<User> login({required String email, required String password}) async {
    try {
      final body = jsonEncode({'email': email, 'password': password});

      if (kDebugMode) {
        print('🌐 REQUEST: POST $baseUrl/auth/login');
        print('📤 Body: $body');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw ApiException(
          message: 'Tiempo de conexión agotado. Intente nuevamente',
        ),
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final token = json['token'] as String;
          final userObj = json['user'] as Map<String, dynamic>;
          final user = User.fromJson(userObj, token: token);
          setToken(token);
          if (kDebugMode) print('Login exitoso para ${user.email}');
          return user;
        }

        throw ApiException(
          message: json['message'] ?? 'Login fallido',
          statusCode: response.statusCode,
        );
      }

      //  Credenciales incorrectas (401)
      if (response.statusCode == 401) {
        throw ApiException(
          message: 'Email o contraseña incorrectos',
          statusCode: 401,
        );
      }

      //  Datos inválidos (400)
      if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ApiException(
          message: error['message'] ?? 'Datos inválidos',
          statusCode: 400,
        );
      }

      //  Otros errores HTTP
      throw ApiException(
        message: 'Error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) print(' Error login: $e');
      throw ApiException(
        message: 'Error de conexión: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// POST /api/auth/register
  /// Body exacto:
  /// { "name": "Juan Pérez", "email": "juan@mail.com", "password": "123456", "password_confirmation": "123456" }
  /// Respuesta: { success: true, token: "...", user: { id, name, email, role }, message?: "..." }
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final body = jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      if (kDebugMode) {
        print(' REQUEST: POST $baseUrl/auth/register');
        print(' Body: $body');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw ApiException(
          message: 'Tiempo de conexión agotado. Intente nuevamente',
        ),
      );

      if (kDebugMode) {
        print(' Response Status: ${response.statusCode}');
        print(' Response Body: ${response.body}');
      }

      if (response.statusCode == 201 || (response.statusCode >= 200 && response.statusCode < 300)) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final token = json['token'] as String;
          final userObj = json['user'] as Map<String, dynamic>;
          final user = User.fromJson(userObj, token: token);
          setToken(token);
          if (kDebugMode) print(' Registro exitoso para ${user.email}');
          return user;
        }

        throw ApiException(
          message: json['message'] ?? 'Registro fallido',
          statusCode: response.statusCode,
        );
      }

      //  Datos inválidos (400)
      if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ApiException(
          message: error['message'] ?? 'Datos inválidos',
          statusCode: 400,
        );
      }

      //  Email ya existe (409)
      if (response.statusCode == 409) {
        throw ApiException(
          message: 'Este email ya está registrado',
          statusCode: 409,
        );
      }

      //  Otros errores
      throw ApiException(
        message: 'Error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) print(' Error registro: $e');
      throw ApiException(
        message: 'Error de conexión: ${e.toString()}',
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
