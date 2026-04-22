# app/services/driver_profile_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.models.user import User, UserRoleEnum
from app.models.driver_profile import DriverProfile
from app.models.taxi import Taxi


def _assert_driver(user: User):
    """Vérifie que l'utilisateur est bien un chauffeur."""
    if user.role != UserRoleEnum.driver:
        raise HTTPException(status_code=403, detail="Vous n'êtes pas un chauffeur.")


# ── GET profil complet ──────────────────────────────────────────
def get_profile(db: Session, current_user: User) -> dict:
    _assert_driver(current_user)

    profile = (
        db.query(DriverProfile)
        .filter(DriverProfile.driver_id == current_user.user_id)
        .first()
    )

    return {
        "user_id": current_user.user_id,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "phone": current_user.phone,
        "is_active": current_user.is_active,
        "driver_profile": {
            "license_number": profile.license_number if profile else None,
            "license_expiry": profile.license_expiry if profile else None,
            "total_trips": profile.total_trips if profile else 0,
            "average_rating": profile.average_rating if profile else 0.0,
        },
    }


# ── PUT mise à jour profil ──────────────────────────────────────
def update_profile(db: Session, current_user: User, data) -> dict:
    _assert_driver(current_user)

    profile = (
        db.query(DriverProfile)
        .filter(DriverProfile.driver_id == current_user.user_id)
        .first()
    )

    if not profile:
        profile = DriverProfile(driver_id=current_user.user_id)
        db.add(profile)

    if data.license_number is not None:
        profile.license_number = data.license_number
    if data.license_expiry is not None:
        profile.license_expiry = data.license_expiry
    
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.phone is not None:
        current_user.phone = data.phone

    db.commit()
    db.refresh(profile)

    return {"message": "Profil mis à jour avec succès", "license_number": profile.license_number}


# ── GET taxi du chauffeur ───────────────────────────────────────
def get_taxi(db: Session, current_user: User) -> dict:
    _assert_driver(current_user)

    taxi = db.query(Taxi).filter(Taxi.driver_id == current_user.user_id).first()

    if not taxi:
        raise HTTPException(status_code=404, detail="Vous n'avez pas encore de véhicule enregistré.")

    return {
        "taxi_id": taxi.taxi_id,
        "vehicle_brand": taxi.vehicle_brand,
        "vehicle_model": taxi.vehicle_model,
        "vehicle_year": taxi.vehicle_year,
        "plate_number": taxi.plate_number,
        "availability": taxi.availability,
    }


# ── PUT mise à jour statut en ligne / hors ligne ────────────────
def update_status(db: Session, current_user: User, is_online: bool) -> dict:
    _assert_driver(current_user)

    current_user.is_active = is_online

    taxi = db.query(Taxi).filter(Taxi.driver_id == current_user.user_id).first()
    if taxi:
        taxi.availability = is_online

    db.commit()

    return {"message": "Statut mis à jour avec succès", "is_online": current_user.is_active}
