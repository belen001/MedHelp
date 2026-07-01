-- =========================================================
-- MedHelp - Esquema de Base de Datos PostgreSQL
-- Basado en SRS, historias de usuario y colección Postman corregida.
-- Objetivo: soportar autenticación, medicamentos, horarios,
-- confirmación de dosis, historial, contactos, preferencias,
-- recordatorios, alertas y reportes de farmacovigilancia.
-- =========================================================

-- Opcional: UUIDs si prefieren reemplazar BIGSERIAL por UUID.
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================================================
-- Limpieza segura para entorno de desarrollo
-- =========================================================
DROP TABLE IF EXISTS notification_events CASCADE;
DROP TABLE IF EXISTS dose_snoozes CASCADE;
DROP TABLE IF EXISTS adverse_reaction_reports CASCADE;
DROP TABLE IF EXISTS dose_logs CASCADE;
DROP TABLE IF EXISTS medication_times CASCADE;
DROP TABLE IF EXISTS medications CASCADE;
DROP TABLE IF EXISTS contacts CASCADE;
DROP TABLE IF EXISTS device_tokens CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS medication_status CASCADE;
DROP TYPE IF EXISTS dose_status CASCADE;
DROP TYPE IF EXISTS contact_relationship CASCADE;
DROP TYPE IF EXISTS contact_status CASCADE;
DROP TYPE IF EXISTS font_size_option CASCADE;
DROP TYPE IF EXISTS notification_status CASCADE;
DROP TYPE IF EXISTS notification_channel CASCADE;
DROP TYPE IF EXISTS reaction_severity CASCADE;

-- =========================================================
-- Tipos enumerados
-- =========================================================
CREATE TYPE user_role AS ENUM ('user', 'monitor', 'admin');

CREATE TYPE medication_status AS ENUM ('active', 'inactive', 'deleted');

CREATE TYPE dose_status AS ENUM ('pending', 'taken', 'skipped', 'missed');

CREATE TYPE contact_relationship AS ENUM (
    'caregiver',
    'family',
    'monitor',
    'patient',
    'other'
);

CREATE TYPE contact_status AS ENUM (
    'available',
    'do_not_disturb',
    'inactive'
);

CREATE TYPE font_size_option AS ENUM (
    'pequena',
    'normal',
    'grande'
);

CREATE TYPE notification_channel AS ENUM (
    'push',
    'email',
    'sms',
    'local'
);

CREATE TYPE notification_status AS ENUM (
    'pending',
    'sent',
    'failed',
    'read'
);

CREATE TYPE reaction_severity AS ENUM (
    'mild',
    'moderate',
    'severe',
    'unknown'
);

-- =========================================================
-- Usuarios
-- Cubre: Register, Login, Profile, Change Password
-- =========================================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'user',

    phone VARCHAR(30),
    birth_date DATE,
    blood_type VARCHAR(5),
    allergies TEXT,
    medical_conditions TEXT,

    consent_data_processing BOOLEAN NOT NULL DEFAULT FALSE,
    consent_given_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT users_email_format_chk
        CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$')
);

-- =========================================================
-- Preferencias de usuario
-- Cubre: GET/PUT /api/user/preferences
-- =========================================================
CREATE TABLE user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

    push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    alert_sound VARCHAR(80) NOT NULL DEFAULT 'campana_suave',
    font_size font_size_option NOT NULL DEFAULT 'normal',
    language VARCHAR(10) NOT NULL DEFAULT 'es',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- Tokens de dispositivo para notificaciones push
-- Útil para HU-03, HU-05, HU-08 y recordatorios.
-- =========================================================
CREATE TABLE device_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    platform VARCHAR(20) NOT NULL, -- android | ios
    token TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT device_tokens_platform_chk
        CHECK (platform IN ('android', 'ios')),
    CONSTRAINT device_tokens_token_unique UNIQUE (token)
);

-- =========================================================
-- Medicamentos
-- Cubre: CRUD /api/medications y carga de foto
-- =========================================================
CREATE TABLE medications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name VARCHAR(160) NOT NULL,
    dosage VARCHAR(80) NOT NULL,
    frequency VARCHAR(120) NOT NULL,
    quantity VARCHAR(80) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,

    special_instructions TEXT,
    photo_url TEXT,
    status medication_status NOT NULL DEFAULT 'active',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT medications_date_range_chk
        CHECK (end_date IS NULL OR end_date >= start_date)
);

-- =========================================================
-- Horarios de cada medicamento
-- Cubre: times: ["08:00", "16:00"]
-- =========================================================
CREATE TABLE medication_times (
    id BIGSERIAL PRIMARY KEY,
    medication_id BIGINT NOT NULL REFERENCES medications(id) ON DELETE CASCADE,

    dose_time TIME NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT medication_times_unique UNIQUE (medication_id, dose_time)
);

-- =========================================================
-- Registro de dosis
-- Cubre: Confirm Dose, Skip Dose, History, Stats
-- Regla clave: una dosis por medicamento + fecha + hora.
-- =========================================================
CREATE TABLE dose_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    medication_id BIGINT NOT NULL REFERENCES medications(id) ON DELETE CASCADE,

    dose_date DATE NOT NULL,
    dose_time TIME NOT NULL,
    status dose_status NOT NULL DEFAULT 'pending',

    taken_at TIMESTAMP,
    skip_reason TEXT,
    missed_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT dose_logs_unique UNIQUE (medication_id, dose_date, dose_time),
    CONSTRAINT dose_logs_taken_at_chk
        CHECK (
            (status = 'taken' AND taken_at IS NOT NULL)
            OR (status <> 'taken')
        )
);

-- =========================================================
-- Posposición de recordatorios
-- Cubre: POST /api/doses/snooze
-- =========================================================
CREATE TABLE dose_snoozes (
    id BIGSERIAL PRIMARY KEY,
    dose_log_id BIGINT REFERENCES dose_logs(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    medication_id BIGINT NOT NULL REFERENCES medications(id) ON DELETE CASCADE,

    dose_date DATE NOT NULL,
    dose_time TIME NOT NULL,
    minutes INTEGER NOT NULL,
    new_reminder_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT dose_snoozes_minutes_chk CHECK (minutes > 0 AND minutes <= 240)
);

-- =========================================================
-- Contactos externos / cuidadores
-- Cubre: CRUD /api/contacts
-- =========================================================
CREATE TABLE contacts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name VARCHAR(120) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(160),
    relationship contact_relationship NOT NULL DEFAULT 'caregiver',
    status contact_status NOT NULL DEFAULT 'available',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT contacts_email_format_chk
        CHECK (email IS NULL OR email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT contacts_has_channel_chk
        CHECK (phone IS NOT NULL OR email IS NOT NULL)
);

-- =========================================================
-- Eventos de notificación
-- Cubre: recordatorios pendientes y alertas a contactos externos
-- =========================================================
CREATE TABLE notification_events (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    medication_id BIGINT REFERENCES medications(id) ON DELETE SET NULL,
    dose_log_id BIGINT REFERENCES dose_logs(id) ON DELETE SET NULL,
    contact_id BIGINT REFERENCES contacts(id) ON DELETE SET NULL,

    channel notification_channel NOT NULL DEFAULT 'push',
    status notification_status NOT NULL DEFAULT 'pending',

    title VARCHAR(160) NOT NULL,
    message TEXT NOT NULL,

    scheduled_at TIMESTAMP NOT NULL,
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    failure_reason TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- Reportes de farmacovigilancia
-- Cubre funcionalidad del SRS: reportar síntomas o reacciones adversas.
-- Aunque no aparece en la colección Postman actual, queda preparada.
-- =========================================================
CREATE TABLE adverse_reaction_reports (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    medication_id BIGINT REFERENCES medications(id) ON DELETE SET NULL,

    symptom TEXT NOT NULL,
    description TEXT,
    severity reaction_severity NOT NULL DEFAULT 'unknown',
    occurred_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- Índices recomendados
-- =========================================================
CREATE INDEX idx_medications_user_status
    ON medications(user_id, status);

CREATE INDEX idx_medication_times_medication_time
    ON medication_times(medication_id, dose_time);

CREATE INDEX idx_dose_logs_user_date
    ON dose_logs(user_id, dose_date);

CREATE INDEX idx_dose_logs_medication_date_time
    ON dose_logs(medication_id, dose_date, dose_time);

CREATE INDEX idx_contacts_user_relationship
    ON contacts(user_id, relationship);

CREATE INDEX idx_notification_events_user_status_schedule
    ON notification_events(user_id, status, scheduled_at);

CREATE INDEX idx_adverse_reports_user_medication
    ON adverse_reaction_reports(user_id, medication_id);

-- =========================================================
-- Trigger para updated_at
-- =========================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_preferences_updated_at
BEFORE UPDATE ON user_preferences
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_device_tokens_updated_at
BEFORE UPDATE ON device_tokens
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_medications_updated_at
BEFORE UPDATE ON medications
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_dose_logs_updated_at
BEFORE UPDATE ON dose_logs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_contacts_updated_at
BEFORE UPDATE ON contacts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_notification_events_updated_at
BEFORE UPDATE ON notification_events
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_adverse_reaction_reports_updated_at
BEFORE UPDATE ON adverse_reaction_reports
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- Vista útil para /api/medications/today y /api/reminders/pending
-- Genera agenda diaria combinando medicamentos activos + horarios.
-- El backend puede filtrar por user_id y date.
-- =========================================================
CREATE OR REPLACE VIEW v_medication_schedule AS
SELECT
    m.user_id,
    m.id AS medication_id,
    m.name,
    m.dosage,
    m.quantity,
    m.frequency,
    m.special_instructions,
    m.start_date,
    m.end_date,
    m.status AS medication_status,
    mt.dose_time
FROM medications m
INNER JOIN medication_times mt ON mt.medication_id = m.id
WHERE m.status = 'active';

-- =========================================================
-- Datos mínimos de prueba opcionales
-- Contraseña: guardar hash real desde backend, no texto plano.
-- =========================================================
INSERT INTO users (
    name,
    email,
    password_hash,
    role,
    phone,
    birth_date,
    blood_type,
    allergies,
    medical_conditions,
    consent_data_processing,
    consent_given_at
) VALUES (
    'Usuario Test',
    'usuario@example.com',
    '$2y$10$replace_with_real_hash',
    'user',
    '+56 9 6000 0000',
    '1980-01-01',
    'O+',
    'Ninguna',
    'Hipertensión',
    TRUE,
    CURRENT_TIMESTAMP
);

INSERT INTO user_preferences (user_id, push_notifications, alert_sound, font_size, language)
VALUES (1, TRUE, 'campana_suave', 'grande', 'es');

INSERT INTO medications (
    user_id,
    name,
    dosage,
    frequency,
    quantity,
    start_date,
    special_instructions,
    photo_url,
    status
) VALUES (
    1,
    'Lisinopril',
    '10mg',
    '1 vez al día',
    '1 pastilla',
    '2026-10-01',
    'Tomar con agua',
    '/storage/medications/lisinopril.jpg',
    'active'
);

INSERT INTO medication_times (medication_id, dose_time)
VALUES (1, '08:00');

INSERT INTO contacts (
    user_id,
    name,
    phone,
    email,
    relationship,
    status
) VALUES (
    1,
    'Maria Gómez',
    '+56 9 6000 1234',
    'maria@example.com',
    'caregiver',
    'available'
);
