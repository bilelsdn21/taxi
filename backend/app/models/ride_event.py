from sqlalchemy import Column, Integer, TIMESTAMP, Enum, ForeignKey
from app.database.connection import Base
import enum

class RideEventTypeEnum(enum.Enum):
    requested = "requested"
    offered = "offered"
    accepted = "accepted"
    started = "started"
    completed = "completed"
    cancelled = "cancelled"

class RideEvent(Base):
    __tablename__ = "ride_events"

    event_id = Column(Integer, primary_key=True, index=True)
    ride_id = Column(Integer, ForeignKey("ride_logs.ride_id"), nullable=False)
    event_type = Column(Enum(RideEventTypeEnum))
    event_time = Column(TIMESTAMP)