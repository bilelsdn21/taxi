# app/controllers/driver_controller.py
from fastapi import Depends
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.services.auth_service import get_current_user
from app.models.user import User

# Schemas
from app.schemas.driver import (
    DriverProfileUpdateSchema,
    DriverStatusUpdateSchema,
    RideActionSchema,
)

# Services
from app.services import driver_profile_service, driver_ride_service


# ═══════════════════════════════════════════════════════════════════
#  PROFIL
# ═══════════════════════════════════════════════════════════════════

async def get_driver_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_profile_service.get_profile(db, current_user)


async def update_driver_profile(
    data: DriverProfileUpdateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_profile_service.update_profile(
        db, current_user, data
    )


async def get_driver_taxi(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_profile_service.get_taxi(db, current_user)


async def update_driver_status(
    data: DriverStatusUpdateSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_profile_service.update_status(db, current_user, data.is_online)


# ═══════════════════════════════════════════════════════════════════
#  COURSES
# ═══════════════════════════════════════════════════════════════════

async def get_available_rides(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_ride_service.get_available_rides(db, current_user)


async def accept_ride(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_ride_service.accept_ride(db, current_user, request_id)


async def cancel_ride(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_ride_service.cancel_ride(db, current_user, request_id)


async def update_ride_status(
    request_id: int,
    data: RideActionSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_ride_service.update_ride_status(db, current_user, request_id, data.action)


async def get_driver_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_ride_service.get_ride_history(db, current_user)

async def get_active_ride(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return driver_ride_service.get_active_ride(db, current_user)
