import os

from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address


def _key_func(request: Request) -> str:
    """
    Use the authenticated user's ID for write endpoints so shared IPs
    (e.g. NAT gateway, office proxy) don't penalise everyone.
    Fall back to real IP for public endpoints (login / register).
    """
    user = getattr(request.state, "user", None)
    if user and hasattr(user, "id"):
        return f"user:{user.id}"
    return get_remote_address(request)


_redis_url = os.getenv("REDIS_URL", "")

if _redis_url:
    # Production: shared Redis state across all 3 pods
    limiter = Limiter(
        key_func=_key_func,
        storage_uri=_redis_url,
        swallow_errors=True,  # Redis down → allow traffic, don't 500
    )
else:
    # Local dev / CI (no Redis): in-memory, single-process only
    limiter = Limiter(key_func=_key_func, swallow_errors=True)
