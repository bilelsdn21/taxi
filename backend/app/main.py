from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database.connection import engine, Base
from sqlalchemy import text

# ── Importer TOUS les modèles pour que SQLAlchemy résolve les FK ──
from app.models.user import User  # noqa: F401
from app.models.driver_profile import DriverProfile  # noqa: F401
from app.models.taxi import Taxi  # noqa: F401
from app.models.passenger import Passenger  # noqa: F401
from app.models.zone import Zone  # noqa: F401
from app.models.ride_request import RideRequest  # noqa: F401
from app.models.ride_assignment import RideAssignment  # noqa: F401
from app.models.ride_log import RideLog  # noqa: F401
from app.models.ride_event import RideEvent  # noqa: F401
from app.models.ride_ratings import RideRating  # noqa: F401
from app.models.payment import Payment  # noqa: F401
from app.models.notification import Notification  # noqa: F401
from app.models.incident_report import IncidentReport  # noqa: F401
from app.models.recurring_schedule import RecurringSchedule  # noqa: F401

# Services (auth)
from app.services import auth_service

# Routes auth
from app.routes import auth_routes

# Routes utilisateur
from app.routes import user_routes

# Routes chauffeur
from app.routes.driver import profile_routes, ride_routes


# Create tables (tous les modèles sont maintenant connus de SQLAlchemy)
Base.metadata.create_all(bind=engine)


def _ensure_taxi_location_columns() -> None:
    """Ensure newly added taxi location columns exist in existing databases."""
    with engine.begin() as conn:
        conn.execute(
            text("ALTER TABLE taxis ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION")
        )
        conn.execute(
            text("ALTER TABLE taxis ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION")
        )
        conn.execute(
            text("ALTER TABLE taxis ADD COLUMN IF NOT EXISTS last_updated TIMESTAMP")
        )


_ensure_taxi_location_columns()


app = FastAPI(
    swagger_ui_parameters={"syntaxHighlight": False},
    title="Smart Pickup API",
    description="API pour la gestion de Smart Pickup",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Authentification ────────────────────────────────────────────
app.include_router(auth_routes.router)                          # /auth/*

# ── Utilisateurs génériques ─────────────────────────────────────
app.include_router(user_routes.router)                          # /users/*

# ── Chauffeur : Profil & Véhicule ───────────────────────────────
app.include_router(
    profile_routes.router,
    prefix="/api/driver",
    tags=["driver - profile"]
)  # /api/driver/profile, /api/driver/taxi, /api/driver/status

# ── Chauffeur : Courses ─────────────────────────────────────────
app.include_router(
    ride_routes.router,
    prefix="/api/driver/rides",
    tags=["driver - rides"]
)  # /api/driver/rides/available, /api/driver/rides/{id}/accept, etc.

# ── Chauffeur : WebSocket Localisation ──────────────────────────
from app.routes.driver import ws_routes
app.include_router(
    ws_routes.router,
    tags=["driver - location"]
)


@app.get("/", tags=["health"])
def read_root():
    return {"message": "Smart Pickup API is running ✅"}
