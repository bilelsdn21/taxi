from sqlalchemy import Column, Integer, String, TIMESTAMP, Enum, ForeignKey
from app.database.connection import Base
import enum

class PassengerTypeEnum(enum.Enum):
    adult = "adult"
    child = "child"
    elderly = "elderly"

class Passenger(Base):
    __tablename__ = "passengers"

    passenger_id = Column(Integer, primary_key=True, index=True)
    parent_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    full_name = Column(String)
    type = Column(Enum(PassengerTypeEnum))
    created_at = Column(TIMESTAMP)