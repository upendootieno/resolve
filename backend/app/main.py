from fastapi import FastAPI
from app.routers.patients import router as patients_router
from fastapi.middleware.cors import CORSMiddleware
from app.routers.pressure import router as pressure_router

app = FastAPI(
    title="Eye Resolve API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(patients_router)
app.include_router(pressure_router)


@app.get("/")
def root():
    return {"message": "Eye Resolve API is running"}
