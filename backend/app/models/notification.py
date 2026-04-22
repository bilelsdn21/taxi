from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, ForeignKey
from app.database.connection import Base

class Notification(Base):
    __tablename__ = "notifications"

    notification_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    title = Column(String)
    message = Column(Text)
    type = Column(String)
    is_read = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP)