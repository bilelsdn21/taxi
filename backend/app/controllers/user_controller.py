import os
from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session
from app.services.user_service import create_user, get_user_by_email

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def save_file(upload_file: UploadFile):
    if upload_file:
        path = os.path.join(UPLOAD_DIR, upload_file.filename)
        with open(path, "wb") as f:
            f.write(upload_file.file.read())
        return path
    return None

async def register_user_with_images(
    full_name: str,
    email: str,
    phone: str,
    password: str,
    role: str,
    user_image: UploadFile,
    driver_image: UploadFile,
    license_number: str,
    license_expiry: str,
    db: Session
):
    if get_user_by_email(db, email):
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    user_image_path = save_file(user_image)

    driver_image_path = None
    if role == "driver":
        if not driver_image or not license_number or not license_expiry:
            raise HTTPException(status_code=400, detail="Driver doit fournir license et image")
        driver_image_path = save_file(driver_image)

    user = create_user(
        db=db,
        full_name=full_name,
        email=email,
        phone=phone,
        password=password,
        role=role,
        user_image=user_image_path,
        driver_image=driver_image_path,
        license_number=license_number,
        license_expiry=license_expiry
    )
    return {"user_id": user.user_id, "email": user.email, "role": user.role}