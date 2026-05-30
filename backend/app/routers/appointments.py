from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.auth import get_current_patient
from app.database import get_db
from app.models import Appointment, Patient
from app.schemas import (
    AppointmentCreate,
    AppointmentListOut,
    AppointmentOut,
    AppointmentPatch,
)

router = APIRouter(prefix="/patients/me/appointments", tags=["appointments"])


@router.get("/next", response_model=AppointmentOut)
def get_next_appointment(
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> AppointmentOut:
    now = datetime.now(timezone.utc)
    appt = db.execute(
        select(Appointment)
        .options(selectinload(Appointment.doctor))
        .where(
            Appointment.patient_id == current.patient_id,
            Appointment.scheduled_at >= now,
            Appointment.status.in_(["confirmed", "pending"]),
        )
        .order_by(Appointment.scheduled_at)
        .limit(1)
    ).scalar_one_or_none()
    if not appt:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No upcoming appointments")
    return AppointmentOut.model_validate(appt)


@router.get("", response_model=AppointmentListOut)
def list_appointments(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    appt_status: str | None = Query(None, alias="status"),
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> AppointmentListOut:
    q = (
        select(Appointment)
        .options(selectinload(Appointment.doctor))
        .where(Appointment.patient_id == current.patient_id)
    )
    if appt_status:
        q = q.where(Appointment.status == appt_status)

    total = db.execute(select(func.count()).select_from(q.subquery())).scalar_one()
    rows = db.execute(q.order_by(Appointment.scheduled_at.desc()).limit(limit).offset(offset)).scalars().all()

    return AppointmentListOut(
        total=total,
        appointments=[AppointmentOut.model_validate(a) for a in rows],
    )


@router.post("", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
def book_appointment(
    body: AppointmentCreate,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> AppointmentOut:
    appt = Appointment(
        patient_id=current.patient_id,
        doctor_id=body.doctor_id,
        clinic_id=body.clinic_id,
        scheduled_at=body.scheduled_at,
        duration_minutes=body.duration_minutes,
        type=body.type,
        status="pending",
        notes=body.notes,
    )
    db.add(appt)
    db.commit()
    db.refresh(appt)
    appt = db.execute(
        select(Appointment).options(selectinload(Appointment.doctor)).where(Appointment.appointment_id == appt.appointment_id)
    ).scalar_one()
    return AppointmentOut.model_validate(appt)


@router.patch("/{appointment_id}", response_model=AppointmentOut)
def patch_appointment(
    appointment_id: str,
    body: AppointmentPatch,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> AppointmentOut:
    appt = db.execute(
        select(Appointment)
        .options(selectinload(Appointment.doctor))
        .where(Appointment.appointment_id == appointment_id, Appointment.patient_id == current.patient_id)
    ).scalar_one_or_none()
    if not appt:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")

    if body.status is not None:
        appt.status = body.status
    if body.scheduled_at is not None:
        appt.scheduled_at = body.scheduled_at
    if body.notes is not None:
        appt.notes = body.notes

    db.commit()
    db.refresh(appt)
    appt = db.execute(
        select(Appointment).options(selectinload(Appointment.doctor)).where(Appointment.appointment_id == appt.appointment_id)
    ).scalar_one()
    return AppointmentOut.model_validate(appt)

