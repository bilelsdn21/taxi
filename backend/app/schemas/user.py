from pydantic import BaseModel, EmailStr
from typing import Optional
from enum import Enum

class UserRoleEnum(str, Enum):

    commuter = "commuter"
    driver = "driver"
    admin = "admin"

class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: Optional[str]
    password: str
    role: UserRoleEnum