from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.auth import get_current_patient
from app.database import get_db
from app.models import Patient, PressureReading
from app.schemas import (
    DailyValue,
    LatestReading,
    PressureReadingCreate,
    PressureReadingListOut,
    PressureReadingOut,
    PressureSummaryOut,
)

router = APIRouter(prefix="/patients/me/pressure-readings", tags=["pressure"])


def _iop_status(value: float) -> str:
    if value <= 21:
        return "normal"
    if value <= 25:
        return "elevated"
    return "high"


@router.get("", response_model=PressureReadingListOut)
def list_readings(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    from_date: datetime | None = None,
    to_date: datetime | None = None,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> PressureReadingListOut:
    q = select(PressureReading).where(PressureReading.patient_id == current.patient_id)
    if from_date:
        q = q.where(PressureReading.recorded_at >= from_date)
    if to_date:
        q = q.where(PressureReading.recorded_at <= to_date)

    total = db.execute(select(func.count()).select_from(q.subquery())).scalar_one()
    rows = db.execute(q.order_by(PressureReading.recorded_at.desc()).limit(limit).offset(offset)).scalars().all()

    return PressureReadingListOut(
        total=total,
        readings=[PressureReadingOut.model_validate(r) for r in rows],
    )


@router.post("", response_model=PressureReadingOut, status_code=status.HTTP_201_CREATED)
def create_reading(
    body: PressureReadingCreate,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> PressureReadingOut:
    reading = PressureReading(
        patient_id=current.patient_id,
        value_mmhg=body.value_mmhg,
        eye=body.eye,
        recorded_at=body.recorded_at,
        device=body.device,
        notes=body.notes,
        is_flagged=body.value_mmhg > 21,
    )
    db.add(reading)
    db.commit()
    db.refresh(reading)
    return PressureReadingOut.model_validate(reading)


@router.get("/summary", response_model=PressureSummaryOut)
def get_summary(
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> PressureSummaryOut:
    # Latest reading
    latest_row = db.execute(
        select(PressureReading)
        .where(PressureReading.patient_id == current.patient_id)
        .order_by(PressureReading.recorded_at.desc())
        .limit(1)
    ).scalar_one_or_none()

    latest = None
    if latest_row:
        latest = LatestReading(
            value_mmhg=latest_row.value_mmhg,
            recorded_at=latest_row.recorded_at,
            status=_iop_status(latest_row.value_mmhg),
        )

    # 7-day window
    now = datetime.now(timezone.utc)
    seven_days_ago = now - timedelta(days=7)
    fourteen_days_ago = now - timedelta(days=14)

    def _avg(start: datetime, end: datetime) -> float | None:
        return db.execute(
            select(func.avg(PressureReading.value_mmhg)).where(
                PressureReading.patient_id == current.patient_id,
                PressureReading.recorded_at >= start,
                PressureReading.recorded_at <= end,
            )
        ).scalar_one_or_none()

    current_avg = _avg(seven_days_ago, now)
    prev_avg = _avg(fourteen_days_ago, seven_days_ago)

    change_pct: float | None = None
    if current_avg is not None and prev_avg and prev_avg != 0:
        change_pct = round(((current_avg - prev_avg) / prev_avg) * 100, 2)

    # Daily averages for chart
    daily_rows = db.execute(
        select(
            func.date(PressureReading.recorded_at).label("day"),
            func.avg(PressureReading.value_mmhg).label("avg_mmhg"),
        )
        .where(
            PressureReading.patient_id == current.patient_id,
            PressureReading.recorded_at >= seven_days_ago,
        )
        .group_by(func.date(PressureReading.recorded_at))
        .order_by(func.date(PressureReading.recorded_at))
    ).all()

    daily_values = [
        DailyValue(date=str(row.day), avg_mmhg=round(row.avg_mmhg, 2))
        for row in daily_rows
    ]

    return PressureSummaryOut(
        latest=latest,
        seven_day_avg_mmhg=round(current_avg, 2) if current_avg is not None else None,
        seven_day_change_percent=change_pct,
        daily_values=daily_values,
    )



def _iop_status(value: float) -> str:
    if value <= 21:
        return "normal"
    if value <= 25:
        return "elevated"
    return "high"

