from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey
from app.database.connection import Base

class DriverProfile(Base):
    __tablename__ = "driver_profiles"

    driver_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    license_number = Column(String)
    license_expiry = Column(Date)
    total_trips = Column(Integer, default=0)
    average_rating = Column(Float)
    image_url = Column(String)  