from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.auth import get_current_patient
from app.database import get_db
from app.models import Patient
from app.schemas import PatientOut, PatientPatchRequest

router = APIRouter(prefix="/patients", tags=["patients"])


@router.get("/me", response_model=PatientOut)
def get_me(
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> PatientOut:
    patient = db.execute(
        select(Patient)
        .options(selectinload(Patient.primary_doctor_rel))
        .where(Patient.patient_id == current.patient_id)
    ).scalar_one()
    first = patient.full_name.split()[0] if patient.full_name else ""
    out = PatientOut.model_validate(patient)
    out.first_name = first
    return out


@router.patch("/me", response_model=PatientOut)
def update_me(
    body: PatientPatchRequest,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> PatientOut:
    patient = db.execute(
        select(Patient)
        .options(selectinload(Patient.primary_doctor_rel))
        .where(Patient.patient_id == current.patient_id)
    ).scalar_one()

    if body.full_name is not None:
        patient.full_name = body.full_name
    if body.phone_number is not None:
        patient.phone_number = body.phone_number
    if body.avatar_url is not None:
        patient.avatar_url = body.avatar_url

    db.commit()
    db.refresh(patient)

    first = patient.full_name.split()[0] if patient.full_name else ""
    out = PatientOut.model_validate(patient)
    out.first_name = first
    return out

