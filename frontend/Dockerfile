# ─────────────────────────────────────────────────────────────────────────────
#  MiniBlog Frontend — Production Build Dockerfile
#  This Dockerfile is ONLY used for building the React app in CI/CD.
#  The output (dist/) is then synced to S3 — not served from a container.
#
#  Usage:
#    docker build --build-arg VITE_API_URL=https://api.miniblog.example.com -t miniblog-frontend .
#    docker cp $(docker create miniblog-frontend):/app/dist ./dist
#    aws s3 sync ./dist s3://miniblog-frontend-<ACCOUNT_ID> --delete
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

# Build arg — injected at build time with the production API URL
ARG VITE_API_URL=http://localhost:8000
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# ── Stage 2: Output (lightweight image with just the build artifacts) ────────
FROM alpine:3.19

WORKDIR /app

COPY --from=builder /app/dist ./dist

# This image isn't meant to be run — it's just a container for extracting
# the build artifacts. But if you want to preview:
# RUN apk add --no-cache python3
# CMD ["python3", "-m", "http.server", "3000", "--directory", "/app/dist"]
