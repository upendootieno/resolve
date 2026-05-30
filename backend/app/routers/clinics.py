import json
import math

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import get_current_patient
from app.database import get_db
from app.models import Clinic, Patient
from app.schemas import (
    ClinicEnrichRequest,
    ClinicEnrichResponse,
    ClinicEnrichedOut,
    OpeningDayHours,
)

router = APIRouter(prefix="/clinics", tags=["clinics"])

_RADIUS_DEG = 0.05  # ~5 km bounding box rough proximity


def _nearby(clinic: Clinic, lat: float, lon: float) -> bool:
    if clinic.latitude is None or clinic.longitude is None:
        return False
    dist = math.sqrt((clinic.latitude - lat) ** 2 + (clinic.longitude - lon) ** 2)
    return dist <= _RADIUS_DEG


def _parse_opening_hours(raw: str | None) -> dict[str, OpeningDayHours | None] | None:
    if not raw:
        return None
    try:
        data = json.loads(raw)
        result: dict[str, OpeningDayHours | None] = {}
        for day, hours in data.items():
            result[day] = None if hours is None else OpeningDayHours(**hours)
        return result
    except Exception:
        return None


@router.post("/enrich", response_model=ClinicEnrichResponse)
def enrich_clinics(
    body: ClinicEnrichRequest,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> ClinicEnrichResponse:
    enriched: list[ClinicEnrichedOut] = []

    for loc in body.locations:
        clinic: Clinic | None = None
        if loc.osm_id:
            clinic = db.execute(select(Clinic).where(Clinic.osm_id == loc.osm_id)).scalar_one_or_none()

        if clinic is None:
            all_clinics = db.execute(select(Clinic)).scalars().all()
            for c in all_clinics:
                if _nearby(c, loc.latitude, loc.longitude):
                    clinic = c
                    break

        if clinic is None:
            continue

        specialties: list[str] = []
        if clinic.accepted_specialties:
            try:
                specialties = json.loads(clinic.accepted_specialties)
            except Exception:
                specialties = [s.strip() for s in clinic.accepted_specialties.split(",") if s.strip()]

        enriched.append(
            ClinicEnrichedOut(
                osm_id=loc.osm_id or clinic.osm_id,
                clinic_id=clinic.clinic_id,
                name=clinic.name,
                phone=clinic.phone,
                email=clinic.email,
                website=clinic.website,
                standard_checkup_price_usd=clinic.standard_checkup_price_usd,
                currency=clinic.currency or "USD",
                accepted_specialties=specialties,
                average_wait_minutes=clinic.average_wait_minutes,
                rating=clinic.rating,
                review_count=clinic.review_count or 0,
                is_network_partner=clinic.is_network_partner or False,
                opening_hours_structured=_parse_opening_hours(clinic.opening_hours_json),
            )
        )

    return ClinicEnrichResponse(enriched=enriched)
