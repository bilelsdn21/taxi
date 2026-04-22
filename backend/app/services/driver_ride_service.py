# app/services/driver_ride_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException
from datetime import datetime

from app.models.user import User, UserRoleEnum
from app.models.taxi import Taxi
from app.models.ride_request import RideRequest, RequestStatusEnum
from app.models.ride_assignment import RideAssignment, AssignmentStatusEnum
from app.models.ride_log import RideLog, RideExecutionStatusEnum
from app.models.ride_event import RideEvent, RideEventTypeEnum
from app.models.passenger import Passenger


def _assert_driver(user: User):
    """Vérifie que l'utilisateur est bien un chauffeur."""
    if user.role != UserRoleEnum.driver:
        raise HTTPException(status_code=403, detail="Vous n'êtes pas un chauffeur.")


def _get_taxi(db: Session, user: User) -> Taxi:
    """Récupère le taxi du chauffeur ou lève une erreur."""
    taxi = db.query(Taxi).filter(Taxi.driver_id == user.user_id).first()
    if not taxi:
        raise HTTPException(status_code=400, detail="Vous n'avez pas de taxi enregistré.")
    return taxi


# ── Liste des courses disponibles ───────────────────────────────
def get_available_rides(db: Session, current_user: User) -> list:
    _assert_driver(current_user)

    available_requests = (
        db.query(RideRequest)
        .filter(RideRequest.status == RequestStatusEnum.pending)
        .all()
    )

    return [
        {
            "request_id": req.request_id,
            "pickup": req.pickup_location,
            "dropoff": req.dropoff_location,
            "distance_km": req.estimated_distance,
            "time_mins": req.estimated_duration,
            "created_at": req.created_at,
        }
        for req in available_requests
    ]


# ── Accepter une course ─────────────────────────────────────────
def accept_ride(db: Session, current_user: User, request_id: int) -> dict:
    _assert_driver(current_user)
    taxi = _get_taxi(db, current_user)

    ride_req = db.query(RideRequest).filter(RideRequest.request_id == request_id).first()
    if not ride_req:
        raise HTTPException(status_code=404, detail="Course introuvable.")
    if ride_req.status != RequestStatusEnum.pending:
        raise HTTPException(status_code=400, detail="Cette course n'est plus disponible (Déjà prise ou annulée).")

    ride_req.status = RequestStatusEnum.accepted

    assignment = RideAssignment(
        request_id=request_id,
        taxi_id=taxi.taxi_id,
        status=AssignmentStatusEnum.accepted,
        acceptance_time=datetime.utcnow(),
    )
    db.add(assignment)
    db.commit()

    return {"message": "Course acceptée !", "request_id": request_id}


# ── Annuler une course ──────────────────────────────────────────
def cancel_ride(db: Session, current_user: User, request_id: int) -> dict:
    _assert_driver(current_user)
    taxi = _get_taxi(db, current_user)

    assignment = (
        db.query(RideAssignment)
        .filter(
            RideAssignment.request_id == request_id,
            RideAssignment.taxi_id == taxi.taxi_id,
            RideAssignment.status == AssignmentStatusEnum.accepted,
        )
        .first()
    )

    if not assignment:
        raise HTTPException(status_code=404, detail="Vous n'êtes pas assigné à cette course.")

    assignment.status = AssignmentStatusEnum.rejected

    ride_req = db.query(RideRequest).filter(RideRequest.request_id == request_id).first()
    if ride_req:
        ride_req.status = RequestStatusEnum.pending

    db.commit()
    return {"message": "Course annulée de votre côté. Remise sur le marché."}


# ── Démarrer ou terminer une course ─────────────────────────────
def update_ride_status(db: Session, current_user: User, request_id: int, action: str) -> dict:
    _assert_driver(current_user)
    taxi = _get_taxi(db, current_user)

    if action == "start":
        ride_log = RideLog(
            request_id=request_id,
            taxi_id=taxi.taxi_id,
            start_time=datetime.utcnow(),
            status=RideExecutionStatusEnum.started,
        )
        db.add(ride_log)
        db.commit()
        db.refresh(ride_log)

        event = RideEvent(
            ride_id=ride_log.ride_id,
            event_type=RideEventTypeEnum.started,
            event_time=datetime.utcnow(),
        )
        db.add(event)
        db.commit()

        return {"message": "Course démarrée !", "ride_id": ride_log.ride_id}

    elif action == "complete":
        ride_log = (
            db.query(RideLog)
            .filter(
                RideLog.request_id == request_id,
                RideLog.status == RideExecutionStatusEnum.started,
            )
            .first()
        )

        if not ride_log:
            raise HTTPException(status_code=400, detail="Veuillez d'abord démarrer la course.")

        ride_log.status = RideExecutionStatusEnum.completed
        ride_log.end_time = datetime.utcnow()

        ride_req = db.query(RideRequest).filter(RideRequest.request_id == request_id).first()
        if ride_req:
            ride_req.status = RequestStatusEnum.completed

        event = RideEvent(
            ride_id=ride_log.ride_id,
            event_type=RideEventTypeEnum.completed,
            event_time=datetime.utcnow(),
        )
        db.add(event)
        db.commit()

        return {"message": "Course terminée avec succès."}

    else:
        raise HTTPException(status_code=400, detail="Action inconnue. Utilisez 'start' ou 'complete'.")


# ── Historique des courses ──────────────────────────────────────
def get_ride_history(db: Session, current_user: User) -> list:
    _assert_driver(current_user)
    taxi = _get_taxi(db, current_user)

    assignments = db.query(RideAssignment).filter(RideAssignment.taxi_id == taxi.taxi_id).all()
    request_ids_from_assignments = [a.request_id for a in assignments]

    logs = db.query(RideLog).filter(RideLog.taxi_id == taxi.taxi_id).all()
    request_ids_from_logs = [log.request_id for log in logs]

    all_req_ids = list(set(request_ids_from_assignments + request_ids_from_logs))

    if not all_req_ids:
        return []

    requests = db.query(RideRequest).filter(RideRequest.request_id.in_(all_req_ids)).all()
    history_list = []

    for req in requests:
        status = "cancelled"
        if req.status == RequestStatusEnum.completed:
            status = "completed"

        passenger = db.query(Passenger).filter(Passenger.passenger_id == req.passenger_id).first()
        passenger_name = passenger.full_name if passenger else "Inconnu"

        duration_str = f"{req.estimated_duration} min" if req.estimated_duration else "N/A"
        if status == "cancelled":
            duration_str = "0 min"

        history_list.append({
            "id": f"R-{req.request_id}",
            "date": req.created_at.strftime("%Y-%m-%d") if req.created_at else "",
            "pickup": req.pickup_location,
            "dropoff": req.dropoff_location,
            "duration": duration_str,
            "rating": 5 if status == "completed" else 0,
            "status": status,
            "passenger": passenger_name
        })

    # Trier par date décroissante
    history_list.sort(key=lambda x: x["date"], reverse=True)
    return history_list

# %% Course en cours %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# ── Course en cours ─────────────────────────────────────────────
def get_active_ride(db: Session, current_user: User) -> dict:
    _assert_driver(current_user)
    taxi = _get_taxi(db, current_user)
    
    # Retrouver les logs en cours (started)
    ride_log = db.query(RideLog).filter(
        RideLog.taxi_id == taxi.taxi_id, 
        RideLog.status == RideExecutionStatusEnum.started
    ).first()
    
    request_id = None
    if ride_log:
        request_id = ride_log.request_id
    else:
        # Chercher une acceptée mais pas encore démarrée
        assignment = db.query(RideAssignment).filter(
            RideAssignment.taxi_id == taxi.taxi_id,
            RideAssignment.status == AssignmentStatusEnum.accepted
        ).first()
        if assignment:
            # Vérifier que le statut de la requête est bien 'accepted'
            ride_req = db.query(RideRequest).filter(RideRequest.request_id == assignment.request_id).first()
            if ride_req and ride_req.status == RequestStatusEnum.accepted:
                request_id = assignment.request_id
                
    if not request_id:
        return None
        
    ride_req = db.query(RideRequest).filter(RideRequest.request_id == request_id).first()
    passenger = db.query(Passenger).filter(Passenger.passenger_id == ride_req.passenger_id).first()
    return {
        'id': ride_req.request_id,
        'passenger': passenger.full_name if passenger else 'Inconnu',
        'pickup': ride_req.pickup_location,
        'dropoff': ride_req.dropoff_location,
        'pickup_lat': float(ride_req.pickup_lat) if ride_req.pickup_lat is not None else None,
        'pickup_lng': float(ride_req.pickup_lng) if ride_req.pickup_lng is not None else None,
        'dropoff_lat': float(ride_req.dropoff_lat) if ride_req.dropoff_lat is not None else None,
        'dropoff_lng': float(ride_req.dropoff_lng) if ride_req.dropoff_lng is not None else None,
        'eta': f'{ride_req.estimated_duration} min' if ride_req.estimated_duration else 'N/A',
        'distance': f'{ride_req.estimated_distance} km' if ride_req.estimated_distance else 'N/A',
        'progress': 0.5 if ride_log else 0.1,
        'ride_started': ride_log is not None,
    }
