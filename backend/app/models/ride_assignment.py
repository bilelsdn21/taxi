from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, ForeignKey, Enum
from app.database.connection import Base
import enum

class AssignmentStatusEnum(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"
    expired = "expired"

class RideAssignment(Base):
    __tablename__ = "ride_assignments"

    assignment_id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, ForeignKey("ride_requests.request_id"), nullable=False)
    taxi_id = Column(Integer, ForeignKey("taxis.taxi_id"), nullable=False)
    status = Column(Enum(AssignmentStatusEnum))
    offered_at = Column(TIMESTAMP)
    responded_at = Column(TIMESTAMP)
    acceptance_time = Column(TIMESTAMP)
    rejection_reason = Column(String)
    is_suggested = Column(Boolean, default=False)