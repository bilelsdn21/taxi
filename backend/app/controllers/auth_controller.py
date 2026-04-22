from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.models.user import User, UserRoleEnum
from app.services import auth_service

async def login_user(login_data: auth_service.LoginRequest, db: Session):
    user = db.query(User).filter(User.email == login_data.email).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    if not auth_service.verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled"
        )
    
    if login_data.remember_me:
        expires_delta = timedelta(days=7)
    else:
        expires_delta = timedelta(minutes=auth_service.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    access_token = auth_service.create_access_token(
        data={"sub": user.email, "user_id": user.user_id, "role": user.role.value},
        expires_delta=expires_delta
    )
    
    return auth_service.LoginResponse(
        access_token=access_token,
        token_type="bearer",
        user_id=user.user_id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value,
        expires_in=int(expires_delta.total_seconds())
    )

async def signup_user(signup_data: auth_service.SignupRequest, db: Session):
    existing_user = db.query(User).filter(User.email == signup_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    try:
        role_enum = UserRoleEnum(signup_data.role)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid role. Must be 'commuter' or 'driver'"
        )
    
    new_user = User(
        full_name=signup_data.full_name,
        email=signup_data.email,
        phone=signup_data.phone,
        password_hash=auth_service.get_password_hash(signup_data.password),
        role=role_enum,
        is_active=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {
        "user_id": new_user.user_id,
        "full_name": new_user.full_name,
        "email": new_user.email,
        "phone": new_user.phone,
        "role": new_user.role.value
    }

async def get_current_user_profile(token: str, db: Session):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = auth_service.jwt.decode(token, auth_service.SECRET_KEY, algorithms=[auth_service.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except auth_service.JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    
    return {
        "id": user.user_id,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role.value,
        "is_active": user.is_active
    }
