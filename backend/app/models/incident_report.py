from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, Enum, ForeignKey
from app.database.connection import Base
import enum

class ReportStatusEnum(enum.Enum):
    open = "open"
    resolved = "resolved"
    rejected = "rejected"

class IncidentReport(Base):
    __tablename__ = "incident_reports"

    report_id = Column(Integer, primary_key=True, index=True)
    ride_id = Column(Integer, ForeignKey("ride_logs.ride_id"))
    user_id = Column(Integer, ForeignKey("users.user_id"))
    report_type = Column(String)
    description = Column(Text)
    severity_level = Column(Integer)
    status = Column(Enum(ReportStatusEnum))
    resolution_note = Column(Text)
    created_at = Column(TIMESTAMP)
    resolved_at = Column(TIMESTAMP)