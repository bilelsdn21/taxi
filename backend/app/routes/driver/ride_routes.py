# app/routes/driver/ride_routes.py
# ─── Routes courses du chauffeur ─────────────────────────────────
# Couche ROUTE uniquement : définit les endpoints et délègue au controller.

from fastapi import APIRouter
from app.controllers.driver_controller import (
    get_available_rides,
    accept_ride,
    cancel_ride,
    update_ride_status,
    get_driver_history,
    get_active_ride,
)

router = APIRouter()

router.add_api_route("/available",             get_available_rides, methods=["GET"])
router.add_api_route("/history",               get_driver_history,  methods=["GET"])
router.add_api_route("/active",                get_active_ride,     methods=["GET"])
router.add_api_route("/{request_id}/accept",   accept_ride,         methods=["POST"])
router.add_api_route("/{request_id}/cancel",   cancel_ride,         methods=["POST"])
router.add_api_route("/{request_id}/status",   update_ride_status,  methods=["PUT"])
