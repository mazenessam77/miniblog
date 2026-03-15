import logging
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from starlette.types import ASGIApp, Receive, Scope, Send

from sqlalchemy import text

from app.database.connection import Base, engine
import app.models.user  # noqa: F401 — register User with Base
import app.models.post  # noqa: F401 — register Post with Base
from app.services.rate_limit import limiter


class _RateLimitStateMiddleware:
    """Pure-ASGI shim: initialise view_rate_limit on scope state before routing.

    SlowAPIMiddleware (BaseHTTPMiddleware) no longer shares request.state with
    endpoint handlers in Starlette 0.40+ — the scope dict is copied on each
    call_next invocation.  This raw ASGI middleware mutates the scope directly,
    so every Request created from it sees the same State object.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] == "http":
            # In Starlette 0.41+, scope["state"] is a plain dict (not State).
            # request.state wraps it lazily: State(scope["state"]).
            # So we must use dict key access here, not attribute assignment.
            scope.setdefault("state", {})
            scope["state"].setdefault("view_rate_limit", None)
        await self.app(scope, receive, send)

# ─── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("miniblog")

# ─── Database Tables ──────────────────────────────────────────────────────────
Base.metadata.create_all(bind=engine)

# ─── Application ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="MiniBlog API",
    description="A minimal blogging platform REST API",
    version="1.0.0",
)

# ─── Rate Limiting ────────────────────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(_RateLimitStateMiddleware)

# ─── CORS ─────────────────────────────────────────────────────────────────────
# Local dev:  defaults to http://localhost:3000
# Production: set CORS_ORIGINS in K8s ConfigMap, e.g.:
#             "https://miniblog.example.com,https://d1234abcd.cloudfront.net"
cors_origins_str = os.getenv("CORS_ORIGINS", "http://localhost:3000")
cors_origins = [origin.strip() for origin in cors_origins_str.split(",")]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Routes ───────────────────────────────────────────────────────────────────
from app.routes import auth, media, posts, profile  # noqa: E402

app.include_router(auth.router)
app.include_router(posts.router)
app.include_router(media.router)
app.include_router(profile.router)


@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "ok"}


@app.on_event("startup")
def startup_event():
    # Idempotent migration: add image_key column if not present
    with engine.connect() as conn:
        conn.execute(
            text("ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_key VARCHAR(500)")
        )
        conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_key VARCHAR(500)")
        )
        conn.commit()
    logger.info("MiniBlog API started")
    logger.info(f"CORS origins: {cors_origins}")

