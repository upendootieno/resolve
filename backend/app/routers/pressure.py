from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.pressure_service import (
    create_pressure_reading,
    get_pressure_readings,
    get_pressure_summary
)

router = APIRouter(
    prefix="/api/v1/patients",
    tags=["Pressure Readings"]
)


# -----------------------------
# REQUEST MODEL
# -----------------------------
class PressureCreate(BaseModel):
    value_mmhg: float
    recorded_at: str


# -----------------------------
# CREATE
# -----------------------------
@router.post("/{patient_id}/pressure-readings")
def add_reading(patient_id: int, body: PressureCreate):

    row = create_pressure_reading(
        patient_id,
        body.value_mmhg,
        body.recorded_at
    )

    return dict(row)


# -----------------------------
# LIST
# -----------------------------
@router.get("/{patient_id}/pressure-readings")
def list_readings(patient_id: int, limit: int = 20, offset: int = 0):

    rows = get_pressure_readings(patient_id, limit, offset)

    return {
        "readings": [dict(r) for r in rows]
    }


# -----------------------------
# SUMMARY
# -----------------------------
@router.get("/{patient_id}/pressure-readings/summary")
def summary(patient_id: int):

    result = get_pressure_summary(patient_id)

    if not result:
        raise HTTPException(status_code=404, detail="No readings found")

    return result
