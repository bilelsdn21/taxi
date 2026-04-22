from sqlalchemy import Column, Integer, Float, Text, TIMESTAMP, ForeignKey
from app.database.connection import Base

class RideRating(Base):
    __tablename__ = "ride_ratings"

    rating_id = Column(Integer, primary_key=True, index=True)
    ride_id = Column(Integer, ForeignKey("ride_logs.ride_id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    driver_id = Column(Integer, ForeignKey("driver_profiles.driver_id"))
    rating = Column(Integer)
    comment = Column(Text)
    created_at = Column(TIMESTAMP)