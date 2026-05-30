from pydantic import BaseModel
from typing import Optional


class PatientProfileResponse(BaseModel):
    patient_id: int
    first_name: str
    last_name: str
    dob: Optional[str]
    diagnosis: Optional[str]
