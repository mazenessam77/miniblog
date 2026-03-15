import logging
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database.connection import Base, engine
import app.models.user  # noqa: F401 — register User with Base
import app.models.post  # noqa: F401 — register Post with Base

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
from app.routes import auth, posts  # noqa: E402

app.include_router(auth.router)
app.include_router(posts.router)


@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "ok"}


@app.on_event("startup")
def startup_event():
    logger.info("MiniBlog API started")
    logger.info(f"CORS origins: {cors_origins}")

