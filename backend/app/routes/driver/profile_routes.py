# app/routes/driver/profile_routes.py
# ─── Routes profil & véhicule du chauffeur ───────────────────────
# Couche ROUTE uniquement : définit les endpoints et délègue au controller.

from fastapi import APIRouter
from app.controllers.driver_controller import (
    get_driver_profile,
    update_driver_profile,
    get_driver_taxi,
    update_driver_status,
)

router = APIRouter()

router.add_api_route("/profile", get_driver_profile, methods=["GET"])
router.add_api_route("/profile", update_driver_profile, methods=["PUT"])
router.add_api_route("/taxi",    get_driver_taxi,      methods=["GET"])
router.add_api_route("/status",  update_driver_status,  methods=["PUT"])