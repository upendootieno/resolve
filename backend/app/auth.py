"""JWT + password utilities, and the FastAPI dependency that resolves the current patient."""
from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone

import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.hash import pbkdf2_sha256
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database import get_db
from app.models import Patient, RefreshToken

settings = get_settings()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# ── Password helpers ──────────────────────────────────────────────────────────
def hash_password(plain: str) -> str:
    return pbkdf2_sha256.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    if hashed.startswith("$pbkdf2-sha256$"):
        return pbkdf2_sha256.verify(plain, hashed)
    if hashed.startswith("$2"):
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    return False


# ── JWT helpers ────────────────────────────────────────────────────────────────
def create_access_token(patient_id: str) -> tuple[str, int]:
    """Returns (token, expires_in_seconds)."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": patient_id, "exp": expire, "type": "access"}
    token = jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)
    return token, settings.access_token_expire_minutes * 60


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


def create_refresh_token(patient_id: str, db: Session) -> str:
    raw = secrets.token_urlsafe(48)
    expires = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    db.add(RefreshToken(patient_id=patient_id, token_hash=_hash_token(raw), expires_at=expires))
    db.commit()
    return raw


def rotate_refresh_token(raw_old: str, db: Session) -> tuple[str, RefreshToken]:
    """Validate old token, revoke it, issue new one."""
    hashed = _hash_token(raw_old)
    stored: RefreshToken | None = db.execute(
        select(RefreshToken).where(RefreshToken.token_hash == hashed)
    ).scalar_one_or_none()

    if not stored or stored.revoked or stored.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")

    stored.revoked = True
    raw_new = secrets.token_urlsafe(48)
    expires = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    new_rt = RefreshToken(patient_id=stored.patient_id, token_hash=_hash_token(raw_new), expires_at=expires)
    db.add(new_rt)
    db.commit()
    return raw_new, stored


def revoke_refresh_token(raw: str, db: Session) -> None:
    hashed = _hash_token(raw)
    stored: RefreshToken | None = db.execute(
        select(RefreshToken).where(RefreshToken.token_hash == hashed)
    ).scalar_one_or_none()
    if stored:
        stored.revoked = True
        db.commit()


# ── FastAPI dependency: current patient ───────────────────────────────────────
def get_current_patient(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Patient:
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        patient_id: str | None = payload.get("sub")
        if patient_id is None or payload.get("type") != "access":
            raise credentials_exc
    except JWTError:
        raise credentials_exc

    patient = db.execute(
        select(Patient).where(Patient.patient_id == patient_id)
    ).scalar_one_or_none()
    if patient is None:
        raise credentials_exc
    return patient
