# MedHelp Backend

API REST para MedHelp — aplicación móvil de gestión y seguimiento de consumo de medicamentos. Construida con Spring Boot 4.0 y Java 21.

## Requisitos

| Herramienta | Versión mínima |
|-------------|----------------|
| Java JDK    | 21             |
| Maven       | 3.9+ (incluye wrapper `mvnw`) |
| PostgreSQL  | 15+            |
| Git         | 2.40+          |

## Stack

- **Framework:** Spring Boot 4.0.6
- **Seguridad:** Spring Security + JWT (jjwt 0.12.6)
- **Persistencia:** Spring Data JPA + Hibernate
- **Base de datos:** PostgreSQL
- **Utilidades:** Lombok, BCrypt, Bean Validation

## Configuración inicial

### 1. Clonar y ubicarse en el proyecto

```bash
git clone <repo-url>
cd MedHelp/medhelp-backend
```

### 2. Crear la base de datos

```sql
CREATE DATABASE medhelp_db;
```

Ejecutar el esquema inicial (desde la raíz del proyecto):

```bash
psql -U postgres -d medhelp_db -f ../medhelp_schema.sql
```

### 3. Configurar variables de entorno

El archivo `src/main/resources/application.yaml` contiene valores por defecto para desarrollo local. Las credenciales de base de datos y claves JWT deben configurarse vía entorno en producción:

| Variable | Default (desarrollo) | Descripción |
|----------|---------------------|-------------|
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://localhost:5432/medhelp_db` | URL de conexión |
| `SPRING_DATASOURCE_USERNAME` | `postgres` | Usuario de BD |
| `SPRING_DATASOURCE_PASSWORD` | `admin` | Contraseña de BD |
| `APP_JWT_SECRET` | (definido en yaml) | Clave Base64 para firma HMAC-SHA256 |
| `APP_JWT_EXPIRATION_MS` | `86400000` | Expiración del token (24 h) |

### 4. Compilar y ejecutar

```bash
# Compilar
./mvnw clean compile

# Ejecutar en modo desarrollo (con DevTools hot-reload)
./mvnw spring-boot:run

# Empaquetar JAR
./mvnw clean package
```

La API arranca en `http://localhost:8080`.

## Estructura del proyecto

```
medhelp-backend/
├── pom.xml
├── mvnw / mvnw.cmd            # Maven wrapper (no requiere Maven instalado)
└── src/
    ├── main/
    │   ├── java/cl/ufro/medhelp/
    │   │   ├── MedhelpBackendApplication.java   # Punto de entrada
    │   │   ├── config/                           # Beans de configuración
    │   │   ├── controller/                       # Endpoints REST
    │   │   │   └── AuthController.java           # /api/auth/*
    │   │   ├── dto/                              # Objetos de transferencia
    │   │   │   ├── RegisterRequest.java
    │   │   │   ├── LoginRequest.java
    │   │   │   ├── AuthResponse.java
    │   │   │   └── ApiResponse.java
    │   │   ├── entity/                           # Entidades JPA
    │   │   │   ├── User.java
    │   │   │   ├── UserRole.java
    │   │   │   └── TokenBlacklist.java
    │   │   ├── exception/                        # Manejo global de errores
    │   │   │   └── GlobalExceptionHandler.java
    │   │   ├── repository/                       # Interfaces JPA
    │   │   │   ├── UserRepository.java
    │   │   │   └── TokenBlacklistRepository.java
    │   │   ├── security/                         # Spring Security + JWT
    │   │   │   ├── SecurityConfig.java
    │   │   │   ├── JwtUtil.java
    │   │   │   └── JwtAuthenticationFilter.java
    │   │   └── service/                          # Lógica de negocio
    │   │       └── AuthService.java
    │   └── resources/
    │       └── application.yaml                  # Configuración de la aplicación
    └── test/
        └── java/cl/ufro/medhelp/
            └── MedhelpBackendApplicationTests.java
```

## Endpoints implementados

### Authentication — `/api/auth`

| Método | Ruta | Auth | Códigos |
|--------|------|:----:|---------|
| `POST` | `/api/auth/register` | No | `201`, `422` |
| `POST` | `/api/auth/login` | No | `200`, `401` |
| `POST` | `/api/auth/logout` | Bearer | `200` |

## Base de datos

Hibernate está configurado con `ddl-auto: update`, por lo que las entidades nuevas generan sus tablas automáticamente. Para desarrollo local esto es suficiente. En producción debe usarse `validate` o `none` con migraciones versionadas (Flyway/Liquibase).

La tabla `token_blacklist` (usada para invalidar tokens en logout) es creada automáticamente por Hibernate aunque no esté en el esquema SQL inicial.