"""Pydantic v2 request / response schemas."""
from __future__ import annotations

from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, EmailStr, Field, field_validator


# ── Shared helpers ─────────────────────────────────────────────────────────────
class OrmModel(BaseModel):
    model_config = {"from_attributes": True}


# ── Auth ───────────────────────────────────────────────────────────────────────
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str
    date_of_birth: date | None = None
    phone_number: str | None = None
    avatar_url: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    patient_id: str
    email: str
    full_name: str
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int


class AccessTokenResponse(BaseModel):
    access_token: str
    expires_in: int


# ── Doctor (embedded) ─────────────────────────────────────────────────────────
class DoctorOut(OrmModel):
    doctor_id: str
    full_name: str
    specialty: str | None = None
    clinic_name: str | None = None
    avatar_url: str | None = None
    clinic_latitude: float | None = Field(None, alias="clinic_lat")
    clinic_longitude: float | None = Field(None, alias="clinic_lon")

    model_config = {"from_attributes": True, "populate_by_name": True}


# ── Patient profile ────────────────────────────────────────────────────────────
class PatientOut(OrmModel):
    patient_id: str
    full_name: str
    first_name: str = ""
    email: str
    phone_number: str | None = None
    avatar_url: str | None = None
    date_of_birth: date | None = None
    diagnosis: str | None = None
    diagnosis_date: date | None = None
    primary_doctor: DoctorOut | None = Field(None, alias="primary_doctor_rel")

    model_config = {"from_attributes": True, "populate_by_name": True}

    @field_validator("first_name", mode="before")
    @classmethod
    def derive_first_name(cls, v: Any, info: Any) -> str:
        if v:
            return v
        # info.data may not have full_name yet in v2; fall back gracefully
        return ""


class PatientPatchRequest(BaseModel):
    full_name: str | None = None
    phone_number: str | None = None
    avatar_url: str | None = None


# ── Pressure Readings ──────────────────────────────────────────────────────────
class PressureReadingCreate(BaseModel):
    value_mmhg: float
    eye: str = "both"
    recorded_at: datetime
    device: str | None = None
    notes: str | None = None


class PressureReadingOut(OrmModel):
    reading_id: str
    value_mmhg: float
    eye: str
    recorded_at: datetime
    device: str | None = None
    notes: str | None = None
    is_flagged: bool


class PressureReadingListOut(BaseModel):
    total: int
    readings: list[PressureReadingOut]


class DailyValue(BaseModel):
    date: str
    avg_mmhg: float


class LatestReading(BaseModel):
    value_mmhg: float
    recorded_at: datetime
    status: str  # "normal" | "elevated" | "high"


class PressureSummaryOut(BaseModel):
    latest: LatestReading | None = None
    seven_day_avg_mmhg: float | None = None
    seven_day_change_percent: float | None = None
    daily_values: list[DailyValue] = []


# ── Appointments ───────────────────────────────────────────────────────────────
class AppointmentCreate(BaseModel):
    doctor_id: str | None = None
    clinic_id: str | None = None
    scheduled_at: datetime
    duration_minutes: int = 30
    type: str = "checkup"
    notes: str | None = None


class AppointmentPatch(BaseModel):
    status: str | None = None
    scheduled_at: datetime | None = None
    notes: str | None = None


class AppointmentDoctorOut(OrmModel):
    doctor_id: str
    full_name: str
    specialty: str | None = None
    clinic_name: str | None = None
    avatar_url: str | None = None
    clinic_latitude: float | None = Field(None, alias="clinic_lat")
    clinic_longitude: float | None = Field(None, alias="clinic_lon")

    model_config = {"from_attributes": True, "populate_by_name": True}


class AppointmentOut(OrmModel):
    appointment_id: str
    scheduled_at: datetime
    duration_minutes: int
    type: str | None = None
    status: str
    notes: str | None = None
    doctor: AppointmentDoctorOut | None = None

    model_config = {"from_attributes": True}


class AppointmentListOut(BaseModel):
    total: int
    appointments: list[AppointmentOut]


# ── Clinics ────────────────────────────────────────────────────────────────────
class ClinicLocationIn(BaseModel):
    osm_id: str | None = None
    latitude: float
    longitude: float


class ClinicEnrichRequest(BaseModel):
    locations: list[ClinicLocationIn]


class OpeningDayHours(BaseModel):
    open: str
    close: str


class ClinicEnrichedOut(BaseModel):
    osm_id: str | None = None
    clinic_id: str
    name: str
    phone: str | None = None
    email: str | None = None
    website: str | None = None
    standard_checkup_price_usd: float | None = None
    currency: str = "USD"
    accepted_specialties: list[str] = []
    average_wait_minutes: int | None = None
    rating: float | None = None
    review_count: int = 0
    is_network_partner: bool = False
    opening_hours_structured: dict[str, OpeningDayHours | None] | None = None


class ClinicEnrichResponse(BaseModel):
    enriched: list[ClinicEnrichedOut]


# ── Medications ────────────────────────────────────────────────────────────────
class MedicationOut(OrmModel):
    medication_id: str
    name: str
    generic_name: str | None = None
    schedule: str | None = None
    schedule_label: str | None = None
    dose_instruction: str | None = None
    eye: str | None = None
    refill_due_on: date | None = None
    days_remaining: int | None = None
    is_active: bool


class MedicationListOut(BaseModel):
    medications: list[MedicationOut]


# ── Dose Logs ──────────────────────────────────────────────────────────────────
class DoseLogCreate(BaseModel):
    medication_id: str
    logged_at: datetime
    status: str = "taken"
    notes: str | None = None


class DoseLogOut(OrmModel):
    log_id: str
    medication_id: str
    logged_at: datetime
    status: str
    notes: str | None = None


class PerMedicationCompliance(BaseModel):
    medication_id: str
    name: str
    doses_expected: int
    doses_taken: int
    compliance_percent: float


class WeeklyComplianceOut(BaseModel):
    period_start: date
    period_end: date
    doses_expected: int
    doses_taken: int
    compliance_percent: float
    streak_days: int
    per_medication: list[PerMedicationCompliance]


# ── Refill Alerts ──────────────────────────────────────────────────────────────
class RefillAlertCreate(BaseModel):
    medication_id: str
    remind_on: date
    channel: str


# ── Messages ───────────────────────────────────────────────────────────────────
class MessageCreate(BaseModel):
    recipient_id: str
    category: str = "medical"
    subject: str
    body: str


class MessageOut(OrmModel):
    message_id: str
    thread_id: str
    category: str
    subject: str
    body: str
    sent_at: datetime
    is_read: bool
    sender_name: str | None = None
    sender_avatar_url: str | None = None


class MessageListOut(BaseModel):
    total: int
    messages: list[MessageOut]


# ── Groups ─────────────────────────────────────────────────────────────────────
class GroupOut(OrmModel):
    group_id: str
    name: str
    description: str | None = None
    member_count: int
    next_session_at: datetime | None = None
    is_featured: bool


class GroupListOut(BaseModel):
    groups: list[GroupOut]


# ── Alerts ─────────────────────────────────────────────────────────────────────
class AlertOut(OrmModel):
    alert_id: str
    type: str
    title: str
    body: str
    severity: str
    created_at: datetime
    is_read: bool


class AlertListOut(BaseModel):
    alerts: list[AlertOut]


# ── Device Tokens ──────────────────────────────────────────────────────────────
class DeviceTokenCreate(BaseModel):
    token: str
    platform: str
