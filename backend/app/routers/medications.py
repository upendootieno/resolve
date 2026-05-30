from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import get_current_patient
from app.database import get_db
from app.models import Medication, Patient
from app.schemas import MedicationListOut, MedicationOut

router = APIRouter(prefix="/patients/me/medications", tags=["medications"])


def _days_remaining(refill_due_on: date | None) -> int | None:
    if refill_due_on is None:
        return None
    delta = refill_due_on - datetime.now(timezone.utc).date()
    return max(delta.days, 0)


@router.get("", response_model=MedicationListOut)
def list_medications(
    is_active: bool = Query(True),
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> MedicationListOut:
    q = select(Medication).where(Medication.patient_id == current.patient_id)
    if is_active:
        q = q.where(Medication.is_active.is_(True))
    rows = db.execute(q).scalars().all()

    meds = []
    for m in rows:
        out = MedicationOut.model_validate(m)
        out.days_remaining = _days_remaining(m.refill_due_on)
        meds.append(out)

    return MedicationListOut(medications=meds)


@router.get("/{medication_id}", response_model=MedicationOut)
def get_medication(
    medication_id: str,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> MedicationOut:
    med = db.execute(
        select(Medication).where(
            Medication.medication_id == medication_id,
            Medication.patient_id == current.patient_id,
        )
    ).scalar_one_or_none()
    if not med:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medication not found")
    out = MedicationOut.model_validate(med)
    out.days_remaining = _days_remaining(med.refill_due_on)
    return out


