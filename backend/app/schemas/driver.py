# app/schemas/driver.py
from pydantic import BaseModel
from datetime import date
from typing import Optional


# ── Profil ──────────────────────────────────────────────────────
class DriverProfileUpdateSchema(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    license_number: Optional[str] = None
    license_expiry: Optional[date] = None


class DriverStatusUpdateSchema(BaseModel):
    is_online: bool


class DriverProfileResponse(BaseModel):
    user_id: int
    full_name: str
    email: str
    phone: Optional[str] = None
    is_active: bool
    driver_profile: dict


class TaxiResponse(BaseModel):
    taxi_id: int
    vehicle_brand: Optional[str] = None
    vehicle_model: Optional[str] = None
    vehicle_year: Optional[int] = None
    plate_number: Optional[str] = None
    availability: bool = True


# ── Courses ─────────────────────────────────────────────────────
class RideActionSchema(BaseModel):
    action: str  # "start" ou "complete"


class AvailableRideResponse(BaseModel):
    request_id: int
    pickup: Optional[str] = None
    dropoff: Optional[str] = None
    distance_km: Optional[float] = None
    time_mins: Optional[int] = None
    created_at: Optional[str] = None


class RideHistoryResponse(BaseModel):
    id: str  # e.g., 'R-2024'
    date: str
    pickup: str
    dropoff: str
    duration: str
    rating: int
    status: str
    passenger: str
