import logging
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

logger = logging.getLogger("miniblog.database")

# ─── Database URL ─────────────────────────────────────────────────────────────
# Local dev:  defaults to local PostgreSQL
# Production: set DATABASE_URL via K8s Secret, e.g.:
#   postgresql://miniblog_admin:<password>@miniblog-prod.xxxxx.us-east-1.rds.amazonaws.com:5432/miniblog
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/miniblog",
)

# ─── Engine Configuration ────────────────────────────────────────────────────
# pool_pre_ping=True  → detects stale connections (critical for RDS Multi-AZ failover)
# pool_size=5         → 5 persistent connections per pod
# max_overflow=10     → up to 10 additional connections under load
# pool_recycle=1800   → recycle connections every 30 min (avoids RDS idle timeout)
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    pool_recycle=1800,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

logger.info("Database engine configured")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

