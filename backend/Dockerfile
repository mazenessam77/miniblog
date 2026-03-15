# ─────────────────────────────────────────────────────────────────────────────
#  MiniBlog Backend — Production Dockerfile
#  - Multi-stage build for smaller image size
#  - Non-root user (matches K8s securityContext runAsUser: 1000)
#  - No dev dependencies or build tools in final image
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Install dependencies ────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Production image ────────────────────────────────────────────────
FROM python:3.11-slim

# Security: run as non-root user (UID 1000 matches K8s pod securityContext)
RUN groupadd -r appuser && useradd -r -g appuser -u 1000 appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY . .

# Own the app directory
RUN chown -R appuser:appuser /app

USER appuser

# ── Environment defaults (overridden by K8s ConfigMap/Secret) ────────────────
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

# Health check for container runtimes (Docker, ECS)
# Note: K8s uses its own liveness/readiness probes defined in the deployment
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--proxy-headers", "--forwarded-allow-ips", "*"]
