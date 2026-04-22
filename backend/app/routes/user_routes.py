# app/routes/user_routes.py
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.models.user import User
from app.services.auth_service import get_current_user
from app.controllers import user_controller

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    return {
        "user_id": current_user.user_id,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "phone": current_user.phone,
        "role": current_user.role.value if current_user.role else None,
        "is_active": current_user.is_active
    }

@router.post("/signup-with-images")
async def signup_with_images(
    full_name: str = Form(...),
    email: str = Form(...),
    phone: str = Form(None),
    password: str = Form(...),
    role: str = Form(...),
    user_image: UploadFile = File(None),
    driver_image: UploadFile = File(None),
    license_number: str = Form(None),
    license_expiry: str = Form(None),
    db: Session = Depends(get_db)
):
    return await user_controller.register_user_with_images(
        full_name, email, phone, password, role, 
        user_image, driver_image, license_number, license_expiry, db
    )