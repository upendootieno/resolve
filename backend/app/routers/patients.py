from fastapi import APIRouter, HTTPException

from app.services.patient_service import get_patient_by_id

router = APIRouter(prefix="/api/v1/patients", tags=["Patients"])


@router.get("/{patient_id}")
def get_patient(patient_id: int):

    patient = get_patient_by_id(patient_id)

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    return {
        "patient_id": patient["patient_id"],
        "first_name": patient["first_name"],
        "last_name": patient["last_name"],
        "dob": patient["dob"],
        "diagnosis": patient["condition"]
    }
