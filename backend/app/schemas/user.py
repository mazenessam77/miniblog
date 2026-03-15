import os
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, computed_field


class UserRegister(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(min_length=6)


class UserLogin(BaseModel):
    username: str
    password: str


class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    created_at: datetime
    avatar_key: Optional[str] = None

    @computed_field
    @property
    def avatar_url(self) -> Optional[str]:
        if not self.avatar_key:
            return None
        bucket = os.getenv("MEDIA_BUCKET", "")
        region = os.getenv("AWS_REGION", "us-east-1")
        if not bucket:
            return None
        filename = self.avatar_key[len("uploads/"):]
        return f"https://{bucket}.s3.{region}.amazonaws.com/resized/thumb/{filename}"

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
