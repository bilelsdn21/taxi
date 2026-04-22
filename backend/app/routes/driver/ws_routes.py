from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict
import json
from datetime import datetime

from app.database.connection import SessionLocal
from app.models.taxi import Taxi

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        # stocker les websockets actives par id du chauffeur
        self.active_connections: Dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, driver_id: int):
        await websocket.accept()
        self.active_connections[driver_id] = websocket

    def disconnect(self, driver_id: int):
        if driver_id in self.active_connections:
            del self.active_connections[driver_id]

    async def broadcast_position(self, driver_id: int, message: dict):
        # Persiste la derniere position pour permettre un suivi temps reel.
        lat = message.get("latitude")
        lng = message.get("longitude")
        if lat is None or lng is None:
            return

        db = SessionLocal()
        try:
            taxi = db.query(Taxi).filter(Taxi.driver_id == driver_id).first()
            if taxi:
                taxi.latitude = float(lat)
                taxi.longitude = float(lng)
                taxi.last_updated = datetime.utcnow()
                db.commit()
        except Exception:
            db.rollback()
        finally:
            db.close()

manager = ConnectionManager()

@router.websocket("/ws/location/{driver_id}")
async def websocket_endpoint(websocket: WebSocket, driver_id: int):
    await manager.connect(websocket, driver_id)
    try:
        while True:
            data = await websocket.receive_text()
            position_data = json.loads(data)
            # Traiter la position (ex: enregistrement en BD ou broadcast)
            await manager.broadcast_position(driver_id, position_data)
            
            # Réponse optionnelle (Acknowledge)
            await websocket.send_text(json.dumps({"status": "received", "data": position_data}))
    except WebSocketDisconnect:
        manager.disconnect(driver_id)
        print(f"Driver {driver_id} disconnected")
