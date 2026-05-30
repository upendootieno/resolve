-- Eye Resolve — PostgreSQL Schema
-- Run: psql -U postgres -d eyeresolve -f schema.sql

-- ── Extensions ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Doctors ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS doctors (
  doctor_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name    TEXT NOT NULL,
  specialty    TEXT,
  clinic_name  TEXT,
  avatar_url   TEXT,
  clinic_lat   DOUBLE PRECISION,
  clinic_lon   DOUBLE PRECISION
);

-- ── Patients ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS patients (
  patient_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email             TEXT UNIQUE NOT NULL,
  password_hash     TEXT NOT NULL,
  full_name         TEXT NOT NULL,
  phone_number      TEXT,
  avatar_url        TEXT,
  date_of_birth     DATE,
  diagnosis         TEXT,
  diagnosis_date    DATE,
  primary_doctor_id UUID REFERENCES doctors(doctor_id),
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- ── Refresh Tokens ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
  token_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  token_hash  TEXT UNIQUE NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Pressure Readings ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pressure_readings (
  reading_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id   UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  value_mmhg   DOUBLE PRECISION NOT NULL,
  eye          TEXT CHECK (eye IN ('left','right','both')) DEFAULT 'both',
  recorded_at  TIMESTAMPTZ NOT NULL,
  device       TEXT,
  notes        TEXT,
  is_flagged   BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- ── Clinics ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clinics (
  clinic_id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  osm_id                      TEXT UNIQUE,
  name                        TEXT NOT NULL,
  phone                       TEXT,
  email                       TEXT,
  website                     TEXT,
  standard_checkup_price_usd  DOUBLE PRECISION,
  currency                    TEXT DEFAULT 'USD',
  accepted_specialties        TEXT,        -- JSON array
  average_wait_minutes        INTEGER,
  rating                      DOUBLE PRECISION,
  review_count                INTEGER DEFAULT 0,
  is_network_partner          BOOLEAN DEFAULT false,
  opening_hours_json          TEXT,        -- JSON object
  latitude                    DOUBLE PRECISION,
  longitude                   DOUBLE PRECISION
);

-- ── Appointments ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS appointments (
  appointment_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id       UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  doctor_id        UUID REFERENCES doctors(doctor_id),
  clinic_id        UUID REFERENCES clinics(clinic_id),
  scheduled_at     TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER DEFAULT 30,
  type             TEXT CHECK (type IN ('checkup','follow_up','procedure','emergency')),
  status           TEXT CHECK (status IN ('confirmed','pending','cancelled','completed')) DEFAULT 'pending',
  notes            TEXT
);

-- ── Medications ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS medications (
  medication_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id       UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  generic_name     TEXT,
  schedule         TEXT CHECK (schedule IN ('once_daily','twice_daily','nightly','as_needed')),
  schedule_label   TEXT,
  dose_instruction TEXT,
  eye              TEXT,
  prescribed_by    UUID REFERENCES doctors(doctor_id),
  started_on       DATE,
  refill_due_on    DATE,
  is_active        BOOLEAN DEFAULT true
);

-- ── Dose Logs ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dose_logs (
  log_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(medication_id),
  logged_at     TIMESTAMPTZ NOT NULL,
  status        TEXT CHECK (status IN ('taken','missed','skipped')) DEFAULT 'taken',
  notes         TEXT
);

-- ── Refill Alerts ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refill_alerts (
  alert_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(medication_id),
  remind_on     DATE NOT NULL,
  channel       TEXT CHECK (channel IN ('push','sms','email')) NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- ── Groups ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS groups (
  group_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  description     TEXT,
  member_count    INTEGER DEFAULT 0,
  next_session_at TIMESTAMPTZ,
  is_featured     BOOLEAN DEFAULT false
);

-- ── Messages ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  message_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id        UUID NOT NULL,
  sender_id        UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  recipient_id     UUID,
  group_id         UUID REFERENCES groups(group_id),
  category         TEXT CHECK (category IN ('medical','community','alert')) DEFAULT 'medical',
  subject          TEXT NOT NULL,
  body             TEXT NOT NULL,
  sent_at          TIMESTAMPTZ DEFAULT now(),
  is_read          BOOLEAN DEFAULT false,
  sender_name      TEXT,
  sender_avatar_url TEXT
);

-- ── Alerts ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS alerts (
  alert_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  severity   TEXT CHECK (severity IN ('info','warning','critical')) DEFAULT 'info',
  created_at TIMESTAMPTZ DEFAULT now(),
  is_read    BOOLEAN DEFAULT false
);

-- ── Device Tokens ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS device_tokens (
  token_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  token      TEXT NOT NULL,
  platform   TEXT CHECK (platform IN ('android','ios')) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (patient_id, token)
);

-- ── Indexes ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pressure_patient  ON pressure_readings(patient_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_appt_patient_time ON appointments(patient_id, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_dose_patient_med  ON dose_logs(patient_id, medication_id, logged_at);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_patient    ON alerts(patient_id, created_at DESC);
