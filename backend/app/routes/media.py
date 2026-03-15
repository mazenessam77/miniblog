import os
import uuid

import boto3
from botocore.exceptions import ClientError
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.services.auth import get_current_user

router = APIRouter(prefix="/media", tags=["Media"])

BUCKET = os.getenv("MEDIA_BUCKET", "")
REGION = os.getenv("AWS_REGION", "us-east-1")

ALLOWED_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/gif": "gif",
}


class PresignedUrlRequest(BaseModel):
    filename: str
    content_type: str


class PresignedUrlResponse(BaseModel):
    upload_url: str
    key: str
    public_url: str


@router.post("/presigned-url", response_model=PresignedUrlResponse)
def get_presigned_url(
    body: PresignedUrlRequest,
    _user=Depends(get_current_user),
):
    if not BUCKET:
        raise HTTPException(status_code=503, detail="Media storage not configured")

    if body.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported type. Allowed: {', '.join(ALLOWED_TYPES)}",
        )

    ext = ALLOWED_TYPES[body.content_type]
    key = f"uploads/{uuid.uuid4()}.{ext}"

    try:
        s3 = boto3.client("s3", region_name=REGION)
        upload_url = s3.generate_presigned_url(
            "put_object",
            Params={"Bucket": BUCKET, "Key": key, "ContentType": body.content_type},
            ExpiresIn=300,  # 5 minutes
        )
    except ClientError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    filename = key[len("uploads/"):]
    public_url = (
        f"https://{BUCKET}.s3.{REGION}.amazonaws.com/resized/medium/{filename}"
    )

    return PresignedUrlResponse(upload_url=upload_url, key=key, public_url=public_url)
