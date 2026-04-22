from sqlalchemy import Column, Integer, String, Boolean, TIME, DATE, ForeignKey, Enum
from app.database.connection import Base
import enum

class DayOfWeekEnum(enum.Enum):
    monday = "monday"
    tuesday = "tuesday"
    wednesday = "wednesday"
    thursday = "thursday"
    friday = "friday"
    saturday = "saturday"
    sunday = "sunday"

class RecurringSchedule(Base):
    __tablename__ = "recurring_schedules"

    schedule_id = Column(Integer, primary_key=True, index=True)
    passenger_id = Column(Integer, ForeignKey("passengers.passenger_id"), nullable=False)
    pickup_location = Column(String)
    dropoff_location = Column(String)
    day_of_week = Column(Enum(DayOfWeekEnum))
    pickup_time = Column(TIME)
    start_date = Column(DATE)
    end_date = Column(DATE)
    is_active = Column(Boolean, default=True)