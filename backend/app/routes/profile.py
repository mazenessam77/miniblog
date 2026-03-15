from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.database.connection import get_db
from app.models.user import User
from app.schemas.user import UserResponse
from app.services.auth import get_current_user
from app.services.rate_limit import limiter

router = APIRouter(prefix="/users", tags=["Profile"])


class AvatarUpdate(BaseModel):
    avatar_key: str


@router.put("/me/avatar", response_model=UserResponse)
@limiter.limit("10/minute")
def update_avatar(
    request: Request,
    body: AvatarUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    user.avatar_key = body.avatar_key
    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)


@router.get("/me", response_model=UserResponse)
def get_me(user: User = Depends(get_current_user)):
    return UserResponse.model_validate(user)
