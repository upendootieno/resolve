from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import get_current_patient
from app.database import get_db
from app.models import Alert, DeviceToken, Patient
from app.schemas import AlertListOut, AlertOut, DeviceTokenCreate

router = APIRouter(prefix="/patients/me", tags=["notifications"])


@router.post("/device-tokens", status_code=status.HTTP_201_CREATED)
def register_device_token(
    body: DeviceTokenCreate,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict:
    existing = db.execute(
        select(DeviceToken).where(
            DeviceToken.patient_id == current.patient_id,
            DeviceToken.token == body.token,
        )
    ).scalar_one_or_none()

    if not existing:
        dt = DeviceToken(patient_id=current.patient_id, token=body.token, platform=body.platform)
        db.add(dt)
        db.commit()

    return {"registered": True}


@router.get("/alerts", response_model=AlertListOut)
def list_alerts(
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> AlertListOut:
    rows = db.execute(
        select(Alert)
        .where(Alert.patient_id == current.patient_id)
        .order_by(Alert.created_at.desc())
    ).scalars().all()
    return AlertListOut(alerts=[AlertOut.model_validate(a) for a in rows])


