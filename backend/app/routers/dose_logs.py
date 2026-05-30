from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.auth import get_current_patient
from app.database import get_db
from app.models import DoseLog, Medication, Patient, RefillAlert
from app.schemas import (
    DoseLogCreate,
    DoseLogOut,
    PerMedicationCompliance,
    RefillAlertCreate,
    WeeklyComplianceOut,
)

router = APIRouter(prefix="/patients/me", tags=["dose-logs"])

_SCHEDULE_DOSES_PER_DAY = {
    "once_daily": 1,
    "twice_daily": 2,
    "nightly": 1,
    "as_needed": 0,
}


@router.post("/dose-logs", response_model=DoseLogOut, status_code=status.HTTP_201_CREATED)
def log_dose(
    body: DoseLogCreate,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> DoseLogOut:
    log = DoseLog(
        patient_id=current.patient_id,
        medication_id=body.medication_id,
        logged_at=body.logged_at,
        status=body.status,
        notes=body.notes,
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return DoseLogOut.model_validate(log)


@router.get("/compliance/weekly", response_model=WeeklyComplianceOut)
def weekly_compliance(
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> WeeklyComplianceOut:
    today = datetime.now(timezone.utc).date()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)
    days_in_period = 7

    meds = db.execute(
        select(Medication).where(
            Medication.patient_id == current.patient_id,
            Medication.is_active.is_(True),
        )
    ).scalars().all()

    total_expected = 0
    total_taken = 0
    per_med: list[PerMedicationCompliance] = []

    for med in meds:
        doses_per_day = _SCHEDULE_DOSES_PER_DAY.get(med.schedule or "", 1)
        expected = doses_per_day * days_in_period

        start_dt = datetime(week_start.year, week_start.month, week_start.day, tzinfo=timezone.utc)
        end_dt = datetime(week_end.year, week_end.month, week_end.day, 23, 59, 59, tzinfo=timezone.utc)

        taken = db.execute(
            select(func.count(DoseLog.log_id)).where(
                DoseLog.patient_id == current.patient_id,
                DoseLog.medication_id == med.medication_id,
                DoseLog.status == "taken",
                DoseLog.logged_at >= start_dt,
                DoseLog.logged_at <= end_dt,
            )
        ).scalar_one()

        compliance = round((taken / expected * 100) if expected > 0 else 0, 2)
        total_expected += expected
        total_taken += taken

        per_med.append(
            PerMedicationCompliance(
                medication_id=med.medication_id,
                name=med.name,
                doses_expected=expected,
                doses_taken=taken,
                compliance_percent=compliance,
            )
        )

    overall_compliance = round((total_taken / total_expected * 100) if total_expected > 0 else 0, 2)

    # Streak: consecutive days ending today with at least one dose taken
    streak = 0
    check_day = today
    while True:
        day_start = datetime(check_day.year, check_day.month, check_day.day, tzinfo=timezone.utc)
        day_end = day_start + timedelta(days=1)
        count = db.execute(
            select(func.count(DoseLog.log_id)).where(
                DoseLog.patient_id == current.patient_id,
                DoseLog.status == "taken",
                DoseLog.logged_at >= day_start,
                DoseLog.logged_at < day_end,
            )
        ).scalar_one()
        if count == 0:
            break
        streak += 1
        check_day -= timedelta(days=1)
        if streak > 365:
            break

    return WeeklyComplianceOut(
        period_start=week_start,
        period_end=week_end,
        doses_expected=total_expected,
        doses_taken=total_taken,
        compliance_percent=overall_compliance,
        streak_days=streak,
        per_medication=per_med,
    )


@router.post("/refill-alerts", status_code=status.HTTP_201_CREATED)
def create_refill_alert(
    body: RefillAlertCreate,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict:
    alert = RefillAlert(
        patient_id=current.patient_id,
        medication_id=body.medication_id,
        remind_on=body.remind_on,
        channel=body.channel,
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    return {"alert_id": alert.alert_id, "remind_on": str(alert.remind_on), "channel": alert.channel}


