from sqlalchemy import Column, Integer, Float, TIMESTAMP, ForeignKey, Enum
from app.database.connection import Base
import enum

class RideExecutionStatusEnum(enum.Enum):
    started = "started"
    completed = "completed"
    cancelled = "cancelled"

class RideLog(Base):
    __tablename__ = "ride_logs"

    ride_id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, ForeignKey("ride_requests.request_id"), nullable=False)
    taxi_id = Column(Integer, ForeignKey("taxis.taxi_id"), nullable=False)
    start_time = Column(TIMESTAMP)
    end_time = Column(TIMESTAMP)
    actual_distance = Column(Float)
    actual_duration = Column(Integer)
    status = Column(Enum(RideExecutionStatusEnum))