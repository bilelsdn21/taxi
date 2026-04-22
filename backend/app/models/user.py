from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, Enum
from app.database.connection import Base
import enum

class UserRoleEnum(enum.Enum):
    commuter = "commuter"
    driver = "driver"
    admin = "admin"

class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    email = Column(String, unique=True, nullable=False)
    phone = Column(String)
    password_hash = Column(String, nullable=False)
    role = Column(Enum(UserRoleEnum))
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP)
    updated_at = Column(TIMESTAMP)
    image_url = Column(String) 