from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.database import Base, engine
from app.routers import auth, appointments, clinics, dose_logs, medications, messages, notifications, patients, pressure

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create all tables against SQLite Cloud on startup
    with engine.begin() as conn:
        Base.metadata.create_all(conn)
    yield


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Backend API for Eye Resolve — a glaucoma management Flutter app.",
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=f"{settings.api_prefix}/redoc",
    openapi_url=f"{settings.api_prefix}/openapi.json",
    lifespan=lifespan,
)

# ── CORS (Flutter web + mobile dev) ──────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
PREFIX = settings.api_prefix

app.include_router(auth.router, prefix=PREFIX)
app.include_router(patients.router, prefix=PREFIX)
app.include_router(pressure.router, prefix=PREFIX)
app.include_router(appointments.router, prefix=PREFIX)
app.include_router(clinics.router, prefix=PREFIX)
app.include_router(medications.router, prefix=PREFIX)
app.include_router(dose_logs.router, prefix=PREFIX)
app.include_router(messages.router, prefix=PREFIX)
app.include_router(notifications.router, prefix=PREFIX)


@app.get(f"{PREFIX}/health", tags=["health"])
async def health() -> dict:
    return {"status": "ok"}
