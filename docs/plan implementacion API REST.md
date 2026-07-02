# Plan de Implementación — MedHelp API REST

> **Fuente:** Colección Postman v2.2, Esquema SQL, SRS IEEE 830-1998 Rev 1.6  
> **Directorio:** `medhelp-backend/`  
> **Estado actual:** Authentication implementada — 17 endpoints restantes por construir

---

## Resumen de endpoints

```
Total endpoints:        22
Implementados:           3  (Auth: register, login, logout)
Por implementar:        19  (en 5 fases)
Opcionales MVP:          2  (snooze dose, change-password)
```

| # | Fase | Endpoints | Entidades nuevas |
|---|------|-----------|------------------|
| — | **0. Auth** | 3 | User, TokenBlacklist |
| 1 | **User Profile** | 5 | UserPreferences |
| 2 | **Medications** | 6 | Medication, MedicationTime |
| 3 | **Contacts** | 4 | Contact |
| 4 | **Doses & History** | 6 | DoseLog, DoseSnooze |
| 5 | **Reminders** | 1 | (usa vista + entidades existentes) |

> La **Fase 0** ya está implementada. Las fases 1–3 pueden ejecutarse en paralelo. Las fases 4–5 dependen de la fase 2.

---

## Arquitectura por capas

Cada endpoint sigue el mismo patrón de capas ya establecido en Auth:

```
Controller  →  Service  →  Repository  →  Entity (JPA → PostgreSQL)
    │              │
    ▼              ▼
   DTO          Exception (→ GlobalExceptionHandler → ApiResponse)
```

### Reglas de implementación

1. **Toda respuesta** usa el wrapper `ApiResponse` con `{ success, data?, message?, errors? }`
2. **Errores de validación** retornan HTTP `422` con `errors: { campo: [mensaje] }`
3. **Errores de autorización** retornan HTTP `401` con `message`
4. **Recurso no encontrado** retorna HTTP `404` con `message`
5. **Conflictos** (dosis duplicada) retornan HTTP `409` con `message`
6. **Creación exitosa** retorna HTTP `201`
7. **Actualización/consulta exitosa** retorna HTTP `200`
8. **Todo endpoint** (excepto auth públicos) requiere `Authorization: Bearer <token>`
9. **El usuario solo accede a sus propios datos** — el `userId` se extrae del token JWT
10. **DTOs** usan `@Valid` + Bean Validation. Los campos snake_case del JSON se mapean con `@JsonProperty`

---

## Fase 1 — User Profile & Preferences

**Dependencia:** Fase 0 (Auth) ✅  
**Tablas:** `users`, `user_preferences`  
**Paquete:** `cl.ufro.medhelp.controller.user` / `.service` / `.dto`

### 1.1 GET /api/user/profile

Obtiene el perfil del usuario autenticado.

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `UserController.java` | `@GetMapping("/profile")` |
| Service | `UserService.java` | `getProfile(userId)` |
| Repository | `UserRepository.java` | Ya existe — agregar query si es necesario |
| DTO Response | `UserProfileResponse.java` | id, name, email, phone, birth_date, blood_type, allergies, medical_conditions |

```json
// GET /api/user/profile → 200
{
  "success": true,
  "data": {
    "id": 1, "name": "Usuario Test", "email": "usuario@example.com",
    "phone": "+56 9 6000 0000", "birth_date": "1980-01-01",
    "blood_type": "O+", "allergies": "Ninguna",
    "medical_conditions": "Hipertensión"
  }
}
```

### 1.2 PUT /api/user/profile

Actualiza perfil del usuario autenticado.

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `UserController.java` | `@PutMapping("/profile")` |
| Service | `UserService.java` | `updateProfile(userId, request)` |
| DTO Request | `UpdateProfileRequest.java` | name, phone, birth_date, blood_type, allergies, medical_conditions (todos opcionales) |

```json
// PUT /api/user/profile → 200
{ "success": true, "message": "Profile updated successfully", "data": { ... } }
```

### 1.3 GET /api/user/preferences

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `UserController.java` | `@GetMapping("/preferences")` |
| Service | `UserService.java` | `getPreferences(userId)` — si no existe, crear defaults |
| Repository | `UserPreferencesRepository.java` | Nuevo |
| Entity | `UserPreferences.java` | Nuevo (tabla `user_preferences`) |
| DTO Response | `UserPreferencesResponse.java` | push_notifications, alert_sound, font_size, language |

```json
// GET /api/user/preferences → 200
{
  "success": true,
  "data": {
    "push_notifications": true, "alert_sound": "campana_suave",
    "font_size": "grande", "language": "es"
  }
}
```

### 1.4 PUT /api/user/preferences

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `UserController.java` | `@PutMapping("/preferences")` |
| Service | `UserService.java` | `updatePreferences(userId, request)` |
| DTO Request | `UpdatePreferencesRequest.java` | push_notifications, alert_sound, font_size, language |

```json
// PUT /api/user/preferences → 200
{ "success": true, "message": "Preferences updated successfully", "data": { ... } }
```

### 1.5 POST /api/user/change-password 🔵 Opcional MVP

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `UserController.java` | `@PostMapping("/change-password")` |
| Service | `UserService.java` | Validar current_password, hashear nueva |
| DTO Request | `ChangePasswordRequest.java` | current_password, new_password, new_password_confirmation |

```json
// POST /api/user/change-password → 200
{ "success": true, "message": "Password changed successfully" }
```

---

## Fase 2 — Medications CRUD

**Dependencia:** Fase 0 (Auth) ✅  
**Tablas:** `medications`, `medication_times`  
**Paquete:** `cl.ufro.medhelp.controller.medication` / `.service` / `.dto`

### 2.1 Entidades nuevas

**`Medication.java`** — mapea tabla `medications`:
- `id`, `userId` (FK users), `name`, `dosage`, `frequency`, `quantity`, `startDate`, `endDate`, `specialInstructions`, `photoUrl`, `status` (enum: active/inactive/deleted), `createdAt`, `updatedAt`
- Relación `@OneToMany` con `MedicationTime` (cascade ALL, orphanRemoval)

**`MedicationTime.java`** — mapea tabla `medication_times`:
- `id`, `medicationId` (FK medications), `doseTime` (LocalTime)

**`MedicationStatus.java`** — enum: `active`, `inactive`, `deleted`

### 2.2 GET /api/medications?status=active

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `MedicationController.java` | `@GetMapping` |
| Service | `MedicationService.java` | `getMedications(userId, status)` |
| Repository | `MedicationRepository.java` | `findByUserIdAndStatus(userId, status)` |
| DTO Response | `MedicationResponse.java` | Incluye `times: ["08:00", "16:00"]` |

```json
// GET /api/medications?status=active → 200
{
  "success": true,
  "data": [{
    "id": 1, "name": "Lisinopril", "dosage": "10mg",
    "frequency": "1 vez al día", "quantity": "1 pastilla",
    "times": ["08:00"], "start_date": "2026-10-01",
    "special_instructions": "Tomar con agua",
    "photo_url": "/storage/medications/lisinopril.jpg", "status": "active"
  }]
}
```

### 2.3 GET /api/medications/today?date=2026-10-24

Usa la vista `v_medication_schedule` + `dose_logs` para armar el horario del día con estado de cada dosis.

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `MedicationController.java` | `@GetMapping("/today")` |
| Service | `MedicationService.java` | `getTodaySchedule(userId, date)` |
| Repository | `MedicationRepository.java` | Query nativa sobre `v_medication_schedule` + LEFT JOIN `dose_logs` |

El response agrupa dosis por hora:
```json
{
  "success": true,
  "data": {
    "date": "2026-10-24", "total": 3, "completed": 1,
    "schedule": {
      "08:00": [{
        "medication_id": 1, "name": "Lisinopril", "dosage": "10mg",
        "quantity": "1 pastilla", "status": "taken",
        "taken_at": "2026-10-24 08:05:00"
      }],
      "16:00": [{
        "medication_id": 6, "name": "Paracetamol", "dosage": "500mg",
        "quantity": "1 pastilla", "status": "pending", "taken_at": null
      }]
    }
  }
}
```

### 2.4 POST /api/medications

Crea medicamento + sus `medication_times`. El request incluye `times: ["08:00", "16:00"]`.

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `MedicationController.java` | `@PostMapping` |
| Service | `MedicationService.java` | `create(userId, request)` — crea Medication + MedicationTime en cascada |
| DTO Request | `CreateMedicationRequest.java` | name, dosage, frequency, quantity, times (array de HH:mm), start_date, special_instructions, photo (opcional) |

Validaciones:
- `name` requerido, `dosage` requerido, `times` al menos 1 horario
- `start_date` formato `YYYY-MM-DD`
- Errores → `422`

```json
// POST /api/medications → 201
{
  "success": true, "message": "Medication registered successfully",
  "data": { "id": 6, "name": "Paracetamol", "times": ["08:00","16:00","00:00"], ... }
}
```

### 2.5 PUT /api/medications/{id}

Actualiza medicamento y reemplaza sus horarios (delete old `medication_times` + insert new).

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `MedicationController.java` | `@PutMapping("/{id}")` |
| Service | `MedicationService.java` | `update(userId, medicationId, request)` |
| DTO Request | `UpdateMedicationRequest.java` | Mismos campos que Create (todos opcionales en teoría, pero name/dosage/times requeridos) |

Validación adicional: `404` si medication no existe o no pertenece al usuario.

```json
// PUT /api/medications/1 → 200
{ "success": true, "message": "Medication updated successfully", "data": { ... } }
// PUT /api/medications/999 → 404
{ "success": false, "message": "Medication not found" }
```

### 2.6 DELETE /api/medications/{id}

Soft-delete: cambia `status` a `'deleted'`. No borra físicamente.

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `MedicationController.java` | `@DeleteMapping("/{id}")` |
| Service | `MedicationService.java` | `delete(userId, medicationId)` — set status=deleted |

```json
// DELETE /api/medications/1 → 200
{ "success": true, "message": "Medication deleted successfully" }
```

### 2.7 POST /api/medications/{id}/photo

Sube archivo de imagen (multipart/form-data). Opcional en MVP.

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `MedicationController.java` | `@PostMapping("/{id}/photo")` — recibe `@RequestParam("photo") MultipartFile` |
| Service | `MedicationService.java` | Guarda archivo en `src/main/resources/static/storage/medications/`, actualiza `photo_url` |

```json
// POST /api/medications/1/photo → 200
{ "success": true, "message": "Photo uploaded successfully",
  "photo_url": "/storage/medications/photo_1_12345.jpg" }
```

---

## Fase 3 — Contacts CRUD

**Dependencia:** Fase 0 (Auth) ✅  
**Tabla:** `contacts`  
**Paquete:** `cl.ufro.medhelp.controller.contact`

### 3.1 Entidad

**`Contact.java`** — mapea tabla `contacts`:
- `id`, `userId` (FK users), `name`, `phone`, `email`, `relationship` (enum: caregiver/family/monitor/patient/other), `status` (enum: available/do_not_disturb/inactive)

**Enums:** `ContactRelationship`, `ContactStatus`

### 3.2 GET /api/contacts?relationship=caregiver

| Capa | Archivo |
|------|---------|
| Controller | `ContactController.java` |
| Service | `ContactService.java` |
| Repository | `ContactRepository.java` — `findByUserId(userId)` + filtrar por relationship |

### 3.3 POST /api/contacts

Request: name, phone, email, relationship, status.  
Validación: phone o email requerido (al menos un canal de contacto).

### 3.4 PUT /api/contacts/{id}

### 3.5 DELETE /api/contacts/{id}

Hard-delete (borrado físico).

---

## Fase 4 — Doses & History

**Dependencia:** Fase 2 (Medications) — necesita `medications` y `medication_times`  
**Tablas:** `dose_logs`, `dose_snoozes`

### 4.1 Entidades

**`DoseLog.java`** — tabla `dose_logs`:
- `id`, `userId`, `medicationId`, `doseDate` (LocalDate), `doseTime` (LocalTime), `status` (enum: pending/taken/skipped/missed), `takenAt`, `skipReason`, `missedAt`

**`DoseStatus.java`** — enum

### 4.2 POST /api/doses/confirm

Marca una dosis como `taken`. Request: medication_id, dose_date, dose_time, taken_at (timestamp opcional).

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `DoseController.java` | `@PostMapping("/confirm")` |
| Service | `DoseService.java` | Busca o crea DoseLog, set status=taken. Si ya está taken → `409` |

```json
// POST /api/doses/confirm → 200
{ "success": true, "message": "Dose confirmed",
  "data": { "medication_id": 1, "dose_date": "2026-10-24", "dose_time": "08:00",
            "taken_at": "2026-10-24 08:05:00", "status": "taken" } }
// Ya confirmada → 409
{ "success": false, "message": "Dose already confirmed for this date and time" }
```

### 4.3 POST /api/doses/skip

Request: medication_id, dose_date, dose_time, reason (opcional).

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `DoseController.java` | `@PostMapping("/skip")` |
| Service | `DoseService.java` | status=skipped, guarda skip_reason |

### 4.4 POST /api/doses/snooze 🔵 Opcional MVP

Request: medication_id, dose_date, dose_time, minutes.  
Crea registro en `dose_snoozes` con `new_reminder_at = now + minutes`.  
Validación: minutes entre 1 y 240.

### 4.5 GET /api/history?start_date=...&end_date=...

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `HistoryController.java` | `@GetMapping` |
| Service | `HistoryService.java` | Agrupa `dose_logs` por fecha, cuenta total/taken/skipped/pending |
| Repository | `DoseLogRepository.java` | `findByUserIdAndDoseDateBetween(userId, start, end)` |

### 4.6 GET /api/history/stats?period=30

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `HistoryController.java` | `@GetMapping("/stats")` |
| Service | `HistoryService.java` | Calcula tasa de adherencia: `taken / total * 100`, desglose por medicamento |

---

## Fase 5 — Reminders

**Dependencia:** Fases 2 + 4  
**Usa:** Vista `v_medication_schedule` + `dose_logs`

### 5.1 GET /api/reminders/pending?date=...&now=HH:mm

Devuelve medicamentos cuya `dose_time <= now` y no tienen `dose_log` con status `taken` o `skipped` para ese día.

| Capa | Archivo | Notas |
|------|---------|-------|
| Controller | `ReminderController.java` | `@GetMapping("/pending")` |
| Service | `ReminderService.java` | JOIN `v_medication_schedule` con `dose_logs` filtrando pendientes |
| Repository | `DoseLogRepository.java` | Query personalizada |

---

## Orden de implementación

```
Fase 0 (Auth) ✅ ya completada
     │
     ├──► Fase 1 (User Profile)    ── 5 endpoints ── independiente
     │
     ├──► Fase 3 (Contacts)        ── 4 endpoints ── independiente
     │
     └──► Fase 2 (Medications)     ── 6 endpoints ── independiente
              │
              └──► Fase 4 (Doses & History) ── 6 endpoints
                       │
                       └──► Fase 5 (Reminders) ── 1 endpoint
```

**En paralelo:** Fases 1, 2 y 3 (no dependen entre sí).  
**En secuencia:** Fase 4 depende de 2. Fase 5 depende de 2 + 4.

### Resumen de archivos por fase

| Fase | Controller | Service | Repository | Entity | DTO |
|------|-----------|---------|------------|--------|-----|
| 1 | 1 | 1 | 1 nuevo | 1 nuevo (UserPreferences) | 5 |
| 2 | 1 | 1 | 1 nuevo | 2 nuevos (Medication, MedicationTime) + 1 enum | 3 |
| 3 | 1 | 1 | 1 nuevo | 1 nuevo (Contact) + 2 enums | 2 |
| 4 | 2 | 2 | 1 nuevo | 2 nuevos (DoseLog, DoseSnooze) + 1 enum | 4 |
| 5 | 1 | 1 | — | — | 1 |

---

## Sección ideal — Más allá de esta entrega

Lo que está en la colección Postman representa el **MVP funcional** para la entrega actual. A continuación se describe lo que sería una implementación completa y robusta para producción.

### 1. Seguridad

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Refresh tokens | Rotación de access tokens con refresh tokens almacenados en BD. Access token 1h, refresh 7d. | Alta |
| CSRF para web | Si se expone versión web, habilitar CSRF protection con token header. | Media |
| Rate limiting distribuido | Migrar de `ConcurrentHashMap` local a Bucket4j + Redis para soportar múltiples instancias. | Media |
| CORS restrictivo | Configurar orígenes explícitos en lugar de permitir todos. | Alta |
| API keys para terceros | Si la app se integra con sistemas clínicos, autenticación adicional via API keys. | Baja |

### 2. Calidad de datos y validación

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Migraciones versionadas | Remplazar `ddl-auto: update` por Flyway o Liquibase con migraciones SQL versionadas. | Alta |
| Soft delete universal | Establecer política: medicamentos, contactos y dosis usan soft delete (`deleted_at`). | Media |
| Validación de horarios | Validar que `dose_time` no colisione con otro medicamento del mismo usuario (opcional, solo advertencia). | Baja |
| Validación de fechas | `end_date >= start_date`, `start_date` no en el pasado lejano, etc. | Media |

### 3. Escalabilidad y rendimiento

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Paginación | `GET /api/medications` y `GET /api/history` deben soportar paginación (`?page=0&size=20`). | Alta |
| Caché | Cachear `user/preferences` y `medications?status=active` con Spring Cache + Redis. | Media |
| Carga de fotos asíncrona | Procesar upload de fotos en background con `@Async` + thumbnail generation. | Media |
| Índices adicionales | Revisar query plan y agregar índices compuestos donde `EXPLAIN ANALYZE` muestre seq scan. | Media |

### 4. Notificaciones (más allá del MVP actual)

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Push notifications reales | Integrar Firebase Cloud Messaging (FCM) para enviar notificaciones al dispositivo cuando `GET /reminders/pending` detecta dosis vencidas. | Alta |
| Recordatorios programados | Scheduled task (`@Scheduled`) que evalúa `dose_logs` cada minuto y dispara notificaciones push para dosis en ventana de tiempo. | Alta |
| Notificaciones a contactos | Cuando el usuario no confirma una dosis en N minutos, enviar push/email/SMS al contacto designado. | Alta |
| Canales múltiples | Soporte para push + email + SMS usando patrón Strategy por canal. | Media |

### 5. Observabilidad

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Logging estructurado | JSON logs con SLF4J + Logback, incluyendo `requestId`, `userId`, `endpoint`. | Alta |
| Health checks | Actuator endpoints (`/actuator/health`, `/actuator/metrics`) para monitoreo. | Alta |
| Trazabilidad | `X-Request-Id` header propagado en todas las responses y logs. | Media |
| Métricas de negocio | Tasa de adherencia agregada, usuarios activos, medicamentos más frecuentes → expuestos como métricas. | Baja |

### 6. Despliegue y DevOps

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Docker | `Dockerfile` multi-stage build + `docker-compose.yml` con PostgreSQL y la app. | Alta |
| CI/CD | GitHub Actions: build → test → package → deploy. | Alta |
| Variables de entorno | Externalizar TODA configuración sensible (`application.yaml` solo defaults de desarrollo). | Alta |
| Tests de integración | `@SpringBootTest` con Testcontainers PostgreSQL para tests de endpoints. | Media |
| Tests de contrato | Contratos entre frontend y backend (Spring Cloud Contract o similar). | Baja |

### 7. Dominio y negocio

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Farmacovigilancia | Endpoint `POST /api/reports/adverse-reaction` usando la tabla `adverse_reaction_reports` ya definida en el schema. | Alta |
| Recordatorios personalizados | El usuario puede configurar ventana de recordatorio (ej. "avisarme 15 min antes"). | Baja |
| Exportar historial | `GET /api/history/export?format=pdf|csv` para compartir con el médico. | Baja |
| Recordatorios recurrentes | Soporte para medicamentos con frecuencia "cada N días" o "días específicos de la semana". | Media |
| Historial de cambios | Auditoría de quién modificó qué medicamento y cuándo (tabla `entity_audit_log`). | Media |

---

## Checklist de verificación por fase

Al terminar cada fase, ejecutar y validar:

```bash
cd medhelp-backend
./mvnw clean compile     # compilación sin errores
./mvnw spring-boot:run   # levantar servidor
```

Probar con Postman todos los escenarios definidos en la colección:

- [ ] Happy path (200/201)
- [ ] Validación (422)
- [ ] No encontrado (404)
- [ ] Conflicto (409, donde aplique)
- [ ] No autorizado sin token (401)
- [ ] Usuario solo accede a sus propios datos (403 o 404)
