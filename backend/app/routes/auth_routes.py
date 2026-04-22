from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.controllers import auth_controller
from app.services.auth_service import LoginRequest, LoginResponse, SignupRequest, oauth2_scheme

router = APIRouter(prefix="/auth", tags=["authentication"])

@router.post("/login", response_model=LoginResponse)
async def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    return await auth_controller.login_user(login_data, db)

@router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(signup_data: SignupRequest, db: Session = Depends(get_db)):
    return await auth_controller.signup_user(signup_data, db)

@router.get("/me")
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    return await auth_controller.get_current_user_profile(token, db)
