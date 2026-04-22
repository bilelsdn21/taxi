from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Float, TIMESTAMP
from app.database.connection import Base

class Taxi(Base):
    __tablename__ = "taxis"

    taxi_id = Column(Integer, primary_key=True, index=True)
    driver_id = Column(Integer, ForeignKey("driver_profiles.driver_id"), nullable=False)
    vehicle_brand = Column(String)
    vehicle_model = Column(String)
    vehicle_year = Column(Integer)
    plate_number = Column(String, unique=True)
    availability = Column(Boolean, default=True)
    image_url = Column(String)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    last_updated = Column(TIMESTAMP, nullable=True)
 