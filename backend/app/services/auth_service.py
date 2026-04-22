from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from typing import Optional
import os
from dotenv import load_dotenv
from fastapi.security import OAuth2PasswordBearer
from fastapi import Depends
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.database.connection import get_db
from app.models.user import User

load_dotenv()

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production-123456789")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login", auto_error=False)

# Pydantic models
class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    remember_me: bool = False

class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    user_id: int
    email: str
    full_name: str
    role: str
    expires_in: int

class SignupRequest(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    password: str
    role: str = "commuter"
    license_number: Optional[str] = None
    license_expiry: Optional[str] = None

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    # ── TEMPORARY BYPASS FOR FRONTEND TESTING WITHOUT LOGIN ──
    if not token:
        # Si aucun token n'est fourni, on connecte automatiquement le chauffeur de test
        test_driver = db.query(User).filter(User.role == 'driver').first()
        if test_driver:
            return test_driver
            
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    # Try parsing token if provided
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    return user