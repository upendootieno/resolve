from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import (
    create_access_token,
    create_refresh_token,
    hash_password,
    revoke_refresh_token,
    rotate_refresh_token,
    verify_password,
)
from app.database import get_db
from app.models import Patient
from app.schemas import (
    AccessTokenResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: Session = Depends(get_db)) -> TokenResponse:
    existing = db.execute(select(Patient).where(Patient.email == body.email)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    patient = Patient(
        email=body.email,
        password_hash=hash_password(body.password),
        full_name=body.full_name,
        date_of_birth=body.date_of_birth,
        phone_number=body.phone_number,
        avatar_url=body.avatar_url,
    )
    db.add(patient)
    db.flush()  # get patient_id

    access_token, expires_in = create_access_token(patient.patient_id)
    refresh_token = create_refresh_token(patient.patient_id, db)

    return TokenResponse(
        patient_id=patient.patient_id,
        email=patient.email,
        full_name=patient.full_name,
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
    )


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    patient: Patient | None = db.execute(
        select(Patient).where(Patient.email == body.email)
    ).scalar_one_or_none()

    if not patient or not verify_password(body.password, patient.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    access_token, expires_in = create_access_token(patient.patient_id)
    refresh_token = create_refresh_token(patient.patient_id, db)

    return TokenResponse(
        patient_id=patient.patient_id,
        email=patient.email,
        full_name=patient.full_name,
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
    )


@router.post("/refresh", response_model=AccessTokenResponse)
def refresh(body: RefreshRequest, db: Session = Depends(get_db)) -> AccessTokenResponse:
    _new_rt, old = rotate_refresh_token(body.refresh_token, db)
    access_token, expires_in = create_access_token(old.patient_id)
    return AccessTokenResponse(access_token=access_token, expires_in=expires_in)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(body: RefreshRequest, db: Session = Depends(get_db)) -> None:
    revoke_refresh_token(body.refresh_token, db)

