from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr
from app.models.user import ProfileType


class LoginRequest(BaseModel):
    ra_or_email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserBase(BaseModel):
    ra_or_email: str
    email: Optional[EmailStr] = None
    full_name: str
    profile_type: ProfileType = ProfileType.ALUNO
    ra: Optional[str] = None
    course: Optional[str] = "Ciência da Computação"
    semester: Optional[int] = 5
    campus: Optional[str] = "Campus Liberdade"
    font_size_factor: str = "normal"
    high_contrast: bool = False
    notifications_enabled: bool = True


class UserCreate(UserBase):
    password: str


class UserUpdateRequest(BaseModel):
    font_size_factor: Optional[str] = None
    high_contrast: Optional[bool] = None
    notifications_enabled: Optional[bool] = None


class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


TokenResponse.model_rebuild()
