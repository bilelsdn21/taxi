from sqlalchemy import Column, Integer, DECIMAL, String, TIMESTAMP, Enum, ForeignKey
from app.database.connection import Base
import enum

class PaymentStatusEnum(enum.Enum):
    pending = "pending"
    paid = "paid"
    failed = "failed"

class PaymentMethodEnum(enum.Enum):
    cash = "cash"
    card = "card"

class Payment(Base):
    __tablename__ = "payments"

    payment_id = Column(Integer, primary_key=True, index=True)
    ride_id = Column(Integer, ForeignKey("ride_logs.ride_id"), nullable=False)
    amount = Column(DECIMAL)
    method = Column(Enum(PaymentMethodEnum))
    status = Column(Enum(PaymentStatusEnum))
    transaction_reference = Column(String)
    payment_date = Column(TIMESTAMP)