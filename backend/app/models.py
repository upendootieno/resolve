"""SQLAlchemy ORM models — SQLite Cloud compatible."""
from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Double,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


# ── Doctors ───────────────────────────────────────────────────────────────────
class Doctor(Base):
    __tablename__ = "doctors"

    doctor_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    full_name: Mapped[str] = mapped_column(Text, nullable=False)
    specialty: Mapped[str | None] = mapped_column(Text)
    clinic_name: Mapped[str | None] = mapped_column(Text)
    avatar_url: Mapped[str | None] = mapped_column(Text)
    clinic_lat: Mapped[float | None] = mapped_column(Double)
    clinic_lon: Mapped[float | None] = mapped_column(Double)

    patients: Mapped[list[Patient]] = relationship("Patient", back_populates="primary_doctor_rel", foreign_keys="Patient.primary_doctor_id")
    appointments: Mapped[list[Appointment]] = relationship("Appointment", back_populates="doctor")
    medications: Mapped[list[Medication]] = relationship("Medication", back_populates="prescriber")


# ── Patients ──────────────────────────────────────────────────────────────────
class Patient(Base):
    __tablename__ = "patients"

    patient_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    email: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    full_name: Mapped[str] = mapped_column(Text, nullable=False)
    phone_number: Mapped[str | None] = mapped_column(Text)
    avatar_url: Mapped[str | None] = mapped_column(Text)
    date_of_birth: Mapped[date | None] = mapped_column(Date)
    diagnosis: Mapped[str | None] = mapped_column(Text)
    diagnosis_date: Mapped[date | None] = mapped_column(Date)
    primary_doctor_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("doctors.doctor_id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    primary_doctor_rel: Mapped[Doctor | None] = relationship("Doctor", back_populates="patients", foreign_keys=[primary_doctor_id])
    pressure_readings: Mapped[list[PressureReading]] = relationship("PressureReading", back_populates="patient", cascade="all, delete-orphan")
    appointments: Mapped[list[Appointment]] = relationship("Appointment", back_populates="patient", cascade="all, delete-orphan")
    medications: Mapped[list[Medication]] = relationship("Medication", back_populates="patient", cascade="all, delete-orphan")
    dose_logs: Mapped[list[DoseLog]] = relationship("DoseLog", back_populates="patient", cascade="all, delete-orphan")
    messages_sent: Mapped[list[Message]] = relationship("Message", back_populates="sender", foreign_keys="Message.sender_id", cascade="all, delete-orphan")
    alerts: Mapped[list[Alert]] = relationship("Alert", back_populates="patient", cascade="all, delete-orphan")
    device_tokens: Mapped[list[DeviceToken]] = relationship("DeviceToken", back_populates="patient", cascade="all, delete-orphan")
    refresh_tokens: Mapped[list[RefreshToken]] = relationship("RefreshToken", back_populates="patient", cascade="all, delete-orphan")


# ── Refresh Tokens ────────────────────────────────────────────────────────────
class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    token_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    token_hash: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    patient: Mapped[Patient] = relationship("Patient", back_populates="refresh_tokens")


# ── Pressure Readings ─────────────────────────────────────────────────────────
class PressureReading(Base):
    __tablename__ = "pressure_readings"

    reading_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    value_mmhg: Mapped[float] = mapped_column(Double, nullable=False)
    eye: Mapped[str] = mapped_column(String(10), default="both")
    recorded_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    device: Mapped[str | None] = mapped_column(Text)
    notes: Mapped[str | None] = mapped_column(Text)
    is_flagged: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    patient: Mapped[Patient] = relationship("Patient", back_populates="pressure_readings")


# ── Appointments ──────────────────────────────────────────────────────────────
class Appointment(Base):
    __tablename__ = "appointments"

    appointment_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    doctor_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("doctors.doctor_id"))
    clinic_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("clinics.clinic_id"))
    scheduled_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, default=30)
    type: Mapped[str | None] = mapped_column(String(20))
    status: Mapped[str] = mapped_column(String(20), default="pending")
    notes: Mapped[str | None] = mapped_column(Text)

    patient: Mapped[Patient] = relationship("Patient", back_populates="appointments")
    doctor: Mapped[Doctor | None] = relationship("Doctor", back_populates="appointments")
    clinic: Mapped[Clinic | None] = relationship("Clinic", back_populates="appointments")


# ── Clinics ───────────────────────────────────────────────────────────────────
class Clinic(Base):
    __tablename__ = "clinics"

    clinic_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    osm_id: Mapped[str | None] = mapped_column(Text, unique=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    phone: Mapped[str | None] = mapped_column(Text)
    email: Mapped[str | None] = mapped_column(Text)
    website: Mapped[str | None] = mapped_column(Text)
    standard_checkup_price_usd: Mapped[float | None] = mapped_column(Double)
    currency: Mapped[str] = mapped_column(String(10), default="USD")
    accepted_specialties: Mapped[str | None] = mapped_column(Text)
    average_wait_minutes: Mapped[int | None] = mapped_column(Integer)
    rating: Mapped[float | None] = mapped_column(Double)
    review_count: Mapped[int] = mapped_column(Integer, default=0)
    is_network_partner: Mapped[bool] = mapped_column(Boolean, default=False)
    opening_hours_json: Mapped[str | None] = mapped_column(Text)
    latitude: Mapped[float | None] = mapped_column(Double)
    longitude: Mapped[float | None] = mapped_column(Double)

    appointments: Mapped[list[Appointment]] = relationship("Appointment", back_populates="clinic")


# ── Medications ───────────────────────────────────────────────────────────────
class Medication(Base):
    __tablename__ = "medications"

    medication_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(Text, nullable=False)
    generic_name: Mapped[str | None] = mapped_column(Text)
    schedule: Mapped[str | None] = mapped_column(String(20))
    schedule_label: Mapped[str | None] = mapped_column(Text)
    dose_instruction: Mapped[str | None] = mapped_column(Text)
    eye: Mapped[str | None] = mapped_column(String(10))
    prescribed_by: Mapped[str | None] = mapped_column(String(36), ForeignKey("doctors.doctor_id"))
    started_on: Mapped[date | None] = mapped_column(Date)
    refill_due_on: Mapped[date | None] = mapped_column(Date)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    patient: Mapped[Patient] = relationship("Patient", back_populates="medications")
    prescriber: Mapped[Doctor | None] = relationship("Doctor", back_populates="medications")
    dose_logs: Mapped[list[DoseLog]] = relationship("DoseLog", back_populates="medication")


# ── Dose Logs ─────────────────────────────────────────────────────────────────
class DoseLog(Base):
    __tablename__ = "dose_logs"

    log_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    medication_id: Mapped[str] = mapped_column(String(36), ForeignKey("medications.medication_id"))
    logged_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    status: Mapped[str] = mapped_column(String(10), default="taken")
    notes: Mapped[str | None] = mapped_column(Text)

    patient: Mapped[Patient] = relationship("Patient", back_populates="dose_logs")
    medication: Mapped[Medication] = relationship("Medication", back_populates="dose_logs")


# ── Messages ──────────────────────────────────────────────────────────────────
class Message(Base):
    __tablename__ = "messages"

    message_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    thread_id: Mapped[str] = mapped_column(String(36), nullable=False)
    sender_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    recipient_id: Mapped[str | None] = mapped_column(String(36))
    group_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("groups.group_id"))
    category: Mapped[str] = mapped_column(String(20), default="medical")
    subject: Mapped[str] = mapped_column(Text, nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    sent_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    sender_name: Mapped[str | None] = mapped_column(Text)
    sender_avatar_url: Mapped[str | None] = mapped_column(Text)

    sender: Mapped[Patient] = relationship("Patient", back_populates="messages_sent", foreign_keys=[sender_id])
    group: Mapped[Group | None] = relationship("Group", back_populates="messages")


# ── Groups ────────────────────────────────────────────────────────────────────
class Group(Base):
    __tablename__ = "groups"

    group_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    member_count: Mapped[int] = mapped_column(Integer, default=0)
    next_session_at: Mapped[datetime | None] = mapped_column(DateTime)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)

    messages: Mapped[list[Message]] = relationship("Message", back_populates="group")


# ── Alerts ────────────────────────────────────────────────────────────────────
class Alert(Base):
    __tablename__ = "alerts"

    alert_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    type: Mapped[str] = mapped_column(String(40), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[str] = mapped_column(String(10), default="info")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)

    patient: Mapped[Patient] = relationship("Patient", back_populates="alerts")


# ── Device Tokens ─────────────────────────────────────────────────────────────
class DeviceToken(Base):
    __tablename__ = "device_tokens"

    token_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    token: Mapped[str] = mapped_column(Text, nullable=False)
    platform: Mapped[str] = mapped_column(String(10), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    patient: Mapped[Patient] = relationship("Patient", back_populates="device_tokens")


# ── Refill Alerts ─────────────────────────────────────────────────────────────
class RefillAlert(Base):
    __tablename__ = "refill_alerts"

    alert_id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String(36), ForeignKey("patients.patient_id", ondelete="CASCADE"))
    medication_id: Mapped[str] = mapped_column(String(36), ForeignKey("medications.medication_id"))
    remind_on: Mapped[date] = mapped_column(Date, nullable=False)
    channel: Mapped[str] = mapped_column(String(10), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

