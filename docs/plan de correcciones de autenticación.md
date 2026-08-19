# MedHelp — Plan de Correcciones de Autenticación

> **Basado en:** Análisis de adecuación SRS IEEE 830-1998 Rev 1.6 vs. implementación actual  
> **Fecha:** 2026-06-30  
> **Directorio de trabajo:** `medhelp-backend/`  
> **Branch:** `feature/backend-authentication`

---

## Resumen de hallazgos

La implementación actual de autenticación cumple ~65% de lo especificado en el SRS. Este plan corrige 6 brechas ordenadas por criticidad y dependencias.

| # | Corrección | Criticidad | Depende de |
|---|-----------|------------|------------|
| 1 | Consentimiento explícito en registro | Crítico | — |
| 2 | Renombrar roles alineados al SRS | Alto | — |
| 3 | Cifrado de datos de salud en BD | Alto | — |
| 4 | Rate limiting en auth endpoints | Medio | — |
| 5 | Auditoría de eventos de autenticación | Medio | 1, 2, 3 |
| 6 | Refresh tokens + rotación | Bajo (MVP futuro) | 1 |

---

## Paso 1 — Consentimiento explícito en el registro

**Archivos a modificar:** 2  
**Referencia SRS:** Sección 2.2, 2.3 (Usuario Reportante), Ley 21.719

### 1.1 Agregar campo `consentDataProcessing` al DTO

**Archivo:** `src/main/java/cl/ufro/medhelp/dto/RegisterRequest.java`

```java
// Agregar campo al final de la clase:
@NotNull(message = "Debe aceptar el consentimiento de tratamiento de datos.")
@AssertTrue(message = "Debe aceptar el consentimiento de tratamiento de datos.")
private Boolean consentDataProcessing;
```

### 1.2 Leer el consentimiento en el servicio en lugar de forzarlo

**Archivo:** `src/main/java/cl/ufro/medhelp/service/AuthService.java`

Cambiar en el método `register()`:
```java
// Antes (incorrecto):
.consentDataProcessing(true)

// Después (correcto):
.consentDataProcessing(request.getConsentDataProcessing())
```

### 1.3 Actualizar Postman (documentación)

Agregar al body del endpoint `POST /api/auth/register`:
```json
"consent_data_processing": true
```

### 1.4 Validación del comportamiento esperado

| Escenario | Request | Response esperado |
|-----------|---------|-------------------|
| Consentimiento `true` | `{..., "consent_data_processing": true}` | `201 Created` |
| Consentimiento `false` | `{..., "consent_data_processing": false}` | `422 — "Debe aceptar el consentimiento"` |
| Consentimiento ausente | `{...}` (sin el campo) | `422 — "Debe aceptar el consentimiento"` |

---

## Paso 2 — Renombrar roles alineados al SRS

**Archivos a modificar:** 6  
**Referencia SRS:** Sección 2.3 (Características de los usuarios)

### 2.1 Cambiar el enum UserRole

**Archivo:** `src/main/java/cl/ufro/medhelp/entity/UserRole.java`

```java
public enum UserRole {
    reportante,   // antes: user      (paciente que toma medicamentos)
    monitor,      // antes: monitor   (familiar/cuidador que supervisa)
    admin         // sin cambio       (administrador del sistema)
}
```

### 2.2 Actualizar User.java

**Archivo:** `src/main/java/cl/ufro/medhelp/entity/User.java`

```java
// Cambiar la anotación @Builder.Default en el campo 'role':
@Builder.Default
private UserRole role = UserRole.reportante;  // antes: UserRole.user
```

### 2.3 Actualizar la base de datos

Ejecutar contra PostgreSQL:
```sql
-- Agregar el nuevo valor al enum y migrar datos existentes
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'reportante';

-- Migrar usuarios existentes
UPDATE users SET role = 'reportante' WHERE role = 'user';

-- Opcional: si no hay datos de prueba, recrear el enum
-- (PostgreSQL no permite DROP VALUE de un enum, requiere recreación)
```

### 2.4 Actualizar el schema SQL para futuras instalaciones

**Archivo:** `medhelp_schema.sql`
```sql
-- Cambiar línea 39:
CREATE TYPE user_role AS ENUM ('reportante', 'monitor', 'admin');
--                                ↑ antes decía 'user'
```

### 2.5 Actualizar Postman (documentación)

La respuesta de Register/Login cambiará `"role": "user"` → `"role": "reportante"`.

### 2.6 Nota sobre el rol `admin`

El SRS no define el rol `admin`. Se mantiene como **necesidad operativa del backend**, pero debe documentarse como desviación del SRS. El rol `admin` no debe estar expuesto en el registro público — solo crearse manualmente en base de datos o mediante un endpoint protegido interno.

---

## Paso 3 — Cifrado de datos de salud en base de datos

**Archivos a modificar:** 3  
**Referencia SRS:** Sección 2.4 (Restricciones de seguridad), Ley 21.719

### 3.1 Agregar dependencia JASYPT para cifrado a nivel de aplicación

**Archivo:** `pom.xml`

```xml
<!-- JASYPT para cifrado de campos sensibles -->
<dependency>
    <groupId>com.github.ulisesbocchio</groupId>
    <artifactId>jasypt-spring-boot-starter</artifactId>
    <version>3.0.5</version>
</dependency>
```

### 3.2 Configurar la clave maestra de cifrado

**Archivo:** `src/main/resources/application.yaml`

```yaml
# Al final del archivo:
jasypt:
  encryptor:
    password: ${JASYPT_ENCRYPTOR_PASSWORD:medhelp-local-dev-key}
    algorithm: PBEWithHmacSHA512AndAES_256
    iv-generator-classname: org.jasypt.iv.RandomIvGenerator
```

> ⚠️ En producción, `JASYPT_ENCRYPTOR_PASSWORD` debe ser una variable de entorno, NUNCA hardcodeada.

### 3.3 Crear un AttributeEncryptor para JPA

**Archivo:** `src/main/java/cl/ufro/medhelp/config/SensitiveDataEncryptor.java`

```java
package cl.ufro.medhelp.config;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.jasypt.util.text.AES256TextEncryptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Converter
@Component
public class SensitiveDataEncryptor implements AttributeConverter<String, String> {

    private static AES256TextEncryptor encryptor;

    public SensitiveDataEncryptor(
            @Value("${jasypt.encryptor.password}") String password) {
        encryptor = new AES256TextEncryptor();
        encryptor.setPassword(password);
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null) return null;
        return encryptor.encrypt(attribute);
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null) return null;
        return encryptor.decrypt(dbData);
    }
}
```

### 3.4 Anotar los campos sensibles en User.java

**Archivo:** `src/main/java/cl/ufro/medhelp/entity/User.java`

Agregar la anotación en los campos de salud:
```java
@Convert(converter = SensitiveDataEncryptor.class)
@Column(columnDefinition = "TEXT")
private String allergies;

@Convert(converter = SensitiveDataEncryptor.class)
@Column(name = "medical_conditions", columnDefinition = "TEXT")
private String medicalConditions;

@Convert(converter = SensitiveDataEncryptor.class)
@Column(name = "blood_type", length = 5)
private String bloodType;
```

### 3.5 Migración de datos (si hay datos de prueba en texto plano)

Ejecutar un script único de migración que lea, encripte y reescriba los registros existentes:
```java
// Solo necesario si hay datos previos sin cifrar en la BD
```

---

## Paso 4 — Rate limiting en endpoints de autenticación

**Archivos a modificar:** 2  
**Referencia SRS:** Sección 3.3.2 (Seguridad — protección contra accesos maliciosos)

### 4.1 Crear un filtro de rate limiting simple

**Archivo:** `src/main/java/cl/ufro/medhelp/security/RateLimitFilter.java`

Usar `Bucket4j` o una implementación ligera con `ConcurrentHashMap` + ventana de tiempo:

```java
package cl.ufro.medhelp.security;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitFilter implements Filter {

    private final Map<String, RateLimitEntry> attempts = new ConcurrentHashMap<>();
    private static final int MAX_ATTEMPTS = 10;     // máximo de intentos
    private static final long WINDOW_MS = 600_000;   // ventana de 10 minutos

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String path = httpRequest.getRequestURI();

        // Solo aplicar a endpoints de auth
        if (path.equals("/api/auth/login") || path.equals("/api/auth/register")) {
            String clientIp = getClientIp(httpRequest);
            String key = path + ":" + clientIp;

            RateLimitEntry entry = attempts.computeIfAbsent(
                key, k -> new RateLimitEntry(System.currentTimeMillis(), 0)
            );

            long now = System.currentTimeMillis();

            // Resetear ventana si expiró
            if (now - entry.windowStart > WINDOW_MS) {
                entry.windowStart = now;
                entry.count = 0;
            }

            entry.count++;

            if (entry.count > MAX_ATTEMPTS) {
                httpResponse.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                httpResponse.setContentType("application/json");
                httpResponse.getWriter().write(
                    "{\"success\":false,\"message\":\"Demasiados intentos. Intente más tarde.\"}"
                );
                return;
            }
        }

        chain.doFilter(request, response);
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        return (xForwarded != null) ? xForwarded.split(",")[0].trim()
                                    : request.getRemoteAddr();
    }

    private static class RateLimitEntry {
        long windowStart;
        int count;

        RateLimitEntry(long windowStart, int count) {
            this.windowStart = windowStart;
            this.count = count;
        }
    }
}
```

### 4.2 Agregar el filtro a SecurityConfig

**Archivo:** `src/main/java/cl/ufro/medhelp/security/SecurityConfig.java`

```java
// Agregar el filtro antes del JWT filter:
private final RateLimitFilter rateLimitFilter;  // nuevo campo

// En securityFilterChain, agregar antes del jwt filter:
.addFilterBefore(rateLimitFilter, JwtAuthenticationFilter.class)
```

> **Alternativa más robusta:** Usar Bucket4j + Redis para entornos con múltiples instancias. La solución con `ConcurrentHashMap` es suficiente para MVP con instancia única.

---

## Paso 5 — Auditoría de eventos de autenticación

**Archivos a modificar:** 3  
**Referencia SRS:** Sección 3.3.2 (Seguridad — logs de actividad)

### 5.1 Crear entidad de auditoría

**Archivo:** `src/main/java/cl/ufro/medhelp/entity/AuthAuditLog.java`

```java
package cl.ufro.medhelp.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "auth_audit_log")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class AuthAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private AuthEvent event;  // LOGIN_SUCCESS, LOGIN_FAILED, REGISTER, LOGOUT

    @Column(name = "user_id")
    private Long userId;

    @Column(length = 160)
    private String email;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent", length = 512)
    private String userAgent;

    @Column(columnDefinition = "TEXT")
    private String details;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum AuthEvent {
        LOGIN_SUCCESS,
        LOGIN_FAILED,
        REGISTER,
        LOGOUT,
        PASSWORD_CHANGED
    }
}
```

### 5.2 Crear repositorio

**Archivo:** `src/main/java/cl/ufro/medhelp/repository/AuthAuditLogRepository.java`

```java
package cl.ufro.medhelp.repository;

import cl.ufro.medhelp.entity.AuthAuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AuthAuditLogRepository extends JpaRepository<AuthAuditLog, Long> {
}
```

### 5.3 Crear servicio de auditoría

**Archivo:** `src/main/java/cl/ufro/medhelp/service/AuditService.java`

```java
package cl.ufro.medhelp.service;

import cl.ufro.medhelp.entity.AuthAuditLog;
import cl.ufro.medhelp.entity.AuthAuditLog.AuthEvent;
import cl.ufro.medhelp.repository.AuthAuditLogRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuthAuditLogRepository auditLogRepository;
    private final HttpServletRequest httpServletRequest;  // inyectado por Spring

    public void log(AuthEvent event, Long userId, String email, String details) {
        AuthAuditLog log = AuthAuditLog.builder()
                .event(event)
                .userId(userId)
                .email(email)
                .ipAddress(getClientIp())
                .userAgent(httpServletRequest.getHeader("User-Agent"))
                .details(details)
                .build();
        auditLogRepository.save(log);
    }

    private String getClientIp() {
        String xForwarded = httpServletRequest.getHeader("X-Forwarded-For");
        return (xForwarded != null) ? xForwarded.split(",")[0].trim()
                                    : httpServletRequest.getRemoteAddr();
    }
}
```

### 5.4 Integrar auditoría en AuthService

**Archivo:** `src/main/java/cl/ufro/medhelp/service/AuthService.java`

Agregar `AuditService auditService` como dependencia y registrar eventos:

```java
// En register():
auditService.log(AuthEvent.REGISTER, user.getId(), user.getEmail(), "User registered");

// En login() — éxito:
auditService.log(AuthEvent.LOGIN_SUCCESS, user.getId(), user.getEmail(), "Login successful");

// En login() — capturar fallos en el catch de InvalidCredentialsException:
// (mover la llamada al audit antes de lanzar la excepción)

// En logout():
auditService.log(AuthEvent.LOGOUT, userId, email, "Token invalidated");
```

### 5.5 Agregar manejo de login fallido

Modificar `AuthService.login()` para auditar intentos fallidos:

```java
public AuthResponse login(LoginRequest request) {
    User user = userRepository.findByEmail(request.getEmail()).orElse(null);

    if (user == null) {
        auditService.log(AuthEvent.LOGIN_FAILED, null, request.getEmail(),
                         "User not found");
        throw new InvalidCredentialsException("Invalid email or password");
    }

    if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
        auditService.log(AuthEvent.LOGIN_FAILED, user.getId(), request.getEmail(),
                         "Wrong password");
        throw new InvalidCredentialsException("Invalid email or password");
    }

    auditService.log(AuthEvent.LOGIN_SUCCESS, user.getId(), user.getEmail(),
                     "Login successful");
    String token = jwtUtil.generateToken(user.getId(), user.getEmail(), user.getRole().name());
    return buildAuthResponse(user, token);
}
```

---

## Paso 6 (Futuro) — Refresh tokens y rotación

**Estado:** Postergado para iteración post-MVP  
**Referencia:** No exigido explícitamente por el SRS, pero mejora la seguridad de datos sensibles

### Diseño propuesto (no implementar ahora)

```
POST /api/auth/refresh
Body: { "refresh_token": "..." }
Response: { "success": true, "token": "nuevo_access_token", "refresh_token": "nuevo_refresh_token" }
```

- Access token: expira en 1 hora
- Refresh token: expira en 7 días, rotación en cada uso
- Almacenar hash del refresh token en BD (`refresh_token_hash` en tabla `users`)
- Invalidar refresh token anterior al usarlo (protege contra replay)

---

## Orden de implementación recomendado

```
Paso 1 (consentimiento) ──┐
                           ├──► Paso 5 (auditoría) ──► Tests de integración
Paso 2 (roles) ────────────┘
                           │
Paso 3 (cifrado) ─────────► Paso 5 (auditoría)
                           │
Paso 4 (rate limiting) ───┘
```

- Los pasos **1, 2, 3 y 4** son independientes entre sí y pueden implementarse en paralelo.
- El paso **5** (auditoría) depende de 1 y 2 porque registra eventos cuyos datos (rol, consentimiento) deben estar ya corregidos.
- El paso **6** es para una iteración futura.

---

## Verificación final

Al completar los pasos 1–5, ejecutar:

```bash
cd medhelp-backend
./mvnw clean test        # pruebas unitarias (si existen)
./mvnw clean compile     # verificar compilación
```

Probar con Postman todos los escenarios de la sección Authentication de la colección:

- [ ] Register sin consentimiento → `422`
- [ ] Register con consentimiento → `201` + token + `"role": "reportante"`
- [ ] Login credenciales correctas → `200` + token
- [ ] Login credenciales incorrectas → `401` (auditado como `LOGIN_FAILED`)
- [ ] Login repetido >10 veces en 10 min → `429 Too Many Requests`
- [ ] Logout → `200` (token en blacklist, auditado como `LOGOUT`)
- [ ] Usar token post-logout → `401`
- [ ] Verificar que `allergies`, `medical_conditions`, `blood_type` se cifran en BD
- [ ] Verificar logs de auditoría en tabla `auth_audit_log`

---

## Riesgos y notas

| Riesgo | Mitigación |
|--------|-----------|
| Migración de enum `user_role` en PostgreSQL | PostgreSQL no soporta `DROP VALUE` de enum. Si hay datos, usar `ALTER TYPE ... ADD VALUE`. Si es desarrollo, recrear el enum con `DROP TYPE ... CASCADE` y volver a crear las tablas. |
| Datos existentes en texto plano (Paso 3) | Si hay registros previos sin cifrar, ejecutar script de migración antes de activar el cifrado. |
| Clave JASYPT en variable de entorno | En desarrollo local usar valor por defecto. En producción, settear `JASYPT_ENCRYPTOR_PASSWORD` como variable de entorno o secret. |
| Rate limiting en clúster | La implementación con `ConcurrentHashMap` solo funciona en instancia única. Para múltiples instancias migrar a Bucket4j + Redis. |
