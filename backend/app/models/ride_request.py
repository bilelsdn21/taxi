from sqlalchemy import Column, Integer, String, Boolean, Float, TIMESTAMP, DECIMAL, ForeignKey, Enum
from app.database.connection import Base
import enum

class RequestStatusEnum(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"
    cancelled = "cancelled"
    completed = "completed"

class CancellationActorEnum(enum.Enum):
    user = "user"
    driver = "driver"
    system = "system"

class RideRequest(Base):
    __tablename__ = "ride_requests"

    request_id = Column(Integer, primary_key=True, index=True)
    passenger_id = Column(Integer, ForeignKey("passengers.passenger_id"), nullable=False)
    zone_id = Column(Integer, ForeignKey("zones.zone_id"), nullable=False)
    pickup_location = Column(String)
    dropoff_location = Column(String)
    pickup_lat = Column(DECIMAL)
    pickup_lng = Column(DECIMAL)
    dropoff_lat = Column(DECIMAL)
    dropoff_lng = Column(DECIMAL)
    pickup_time = Column(TIMESTAMP)
    scheduled_flag = Column(Boolean, default=False)
    status = Column(Enum(RequestStatusEnum))
    cancellation_reason = Column(String)
    cancelled_by = Column(Enum(CancellationActorEnum))
    estimated_distance = Column(Float)
    estimated_duration = Column(Integer)
    created_at = Column(TIMESTAMP)