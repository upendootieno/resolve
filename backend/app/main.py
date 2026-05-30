from fastapi import FastAPI
from app.routers.patients import router as patients_router

app = FastAPI(
    title="Eye Resolve API",
    version="1.0.0"
)

app.include_router(patients_router)


@app.get("/")
def root():
    return {"message": "Eye Resolve API is running"}
