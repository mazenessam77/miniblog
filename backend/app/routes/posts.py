import os
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models.post import Post
from app.models.user import User
from app.schemas.post import PostCreate, PostResponse, PostUpdate
from app.services.auth import get_current_user
from app.services.rate_limit import limiter

router = APIRouter(prefix="/posts", tags=["Posts"])


def _image_url(image_key: str | None) -> str | None:
    if not image_key:
        return None
    bucket = os.getenv("MEDIA_BUCKET", "")
    region = os.getenv("AWS_REGION", "us-east-1")
    if not bucket:
        return None
    filename = image_key[len("uploads/"):]
    return f"https://{bucket}.s3.{region}.amazonaws.com/resized/medium/{filename}"


def _to_response(post: Post) -> PostResponse:
    return PostResponse(
        id=post.id,
        title=post.title,
        content=post.content,
        author_id=post.author_id,
        author_username=post.author.username,
        image_url=_image_url(post.image_key),
        created_at=post.created_at,
        updated_at=post.updated_at,
    )


@router.get("", response_model=List[PostResponse])
@limiter.limit("60/minute")
def list_posts(request: Request, db: Session = Depends(get_db)):
    posts = db.query(Post).order_by(Post.created_at.desc()).all()
    return [_to_response(p) for p in posts]


@router.get("/{post_id}", response_model=PostResponse)
def get_post(post_id: int, db: Session = Depends(get_db)):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    return _to_response(post)


@router.post("", response_model=PostResponse, status_code=201)
@limiter.limit("20/minute")
def create_post(
    request: Request,
    data: PostCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    post = Post(title=data.title, content=data.content, author_id=user.id, image_key=data.image_key)
    db.add(post)
    db.commit()
    db.refresh(post)
    return _to_response(post)


@router.put("/{post_id}", response_model=PostResponse)
@limiter.limit("30/minute")
def update_post(
    request: Request,
    post_id: int,
    data: PostUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this post")

    if data.title is not None:
        post.title = data.title
    if data.content is not None:
        post.content = data.content
    if data.image_key is not None:
        post.image_key = data.image_key

    db.commit()
    db.refresh(post)
    return _to_response(post)


@router.delete("/{post_id}", status_code=204)
@limiter.limit("20/minute")
def delete_post(
    request: Request,
    post_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")

    db.delete(post)
    db.commit()
