# MiniBlog Platform

A **production-grade full-stack blogging platform** built with React + FastAPI + PostgreSQL, deployed on **AWS EKS** using **Terraform IaC** and **GitHub Actions CI/CD**.

> Register, write posts, and read from other users — fully secured with JWT auth, running on Kubernetes in the AWS cloud.

---

## What We Built

### Full-Stack Application
A complete blogging platform where users can register, log in, create posts, edit them, and read posts from other users — secured with JWT authentication and bcrypt password hashing.

### Cloud Infrastructure on AWS
Every AWS resource was provisioned with Terraform — nothing was clicked manually in the console. The infrastructure runs in **us-east-1** and includes a 3-tier VPC, EKS cluster, RDS PostgreSQL, ECR, S3 static hosting, and CloudWatch observability.

### CI/CD Pipelines
Three GitHub Actions pipelines automate everything from infrastructure changes to code deployments. A push to `main` triggers a full build, test, Docker image push, and Kubernetes rolling update — **zero downtime**.

---

## Architecture

```
                         Internet
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
        [S3 Static Site]           [Application Load Balancer]
         React frontend              (AWS Load Balancer Controller)
                                           │
                                    [EKS Node Group]
                                    ┌──────┴──────┐
                                    │  backend     │  × 3 pods
                                    │  (FastAPI)   │  rolling update
                                    └──────┬──────┘
                                           │
                                    [RDS PostgreSQL 15]
                                    (private subnet, Multi-AZ)
```

### AWS Services

| Service | Purpose |
|---------|---------|
| **EKS** | Runs FastAPI backend in 3 replicas with HPA auto-scaling |
| **RDS PostgreSQL 15** | Managed database — Multi-AZ, gp3, 7-day backups |
| **ECR** | Private Docker registry for backend images |
| **S3** | Hosts the React static build |
| **ALB** | Internet-facing load balancer managed via K8s Ingress |
| **VPC** | 3-tier: public (ALB/NAT), private-app (EKS), private-db (RDS) |
| **CloudWatch** | Metrics, log groups, RDS alarms, dashboard |
| **IAM / IRSA** | Pod-level AWS access via OIDC — no static keys in pods |

---

## Tech Stack

### Backend
- **FastAPI** — async Python REST API
- **SQLAlchemy 2** — ORM with connection pooling (`pool_size=5`, `max_overflow=10`)
- **PostgreSQL 15** — relational database
- **python-jose** — JWT creation & verification
- **passlib + bcrypt** — password hashing
- **Pydantic v2** — request/response validation
- **Uvicorn** — ASGI server

### Frontend
- **React 18** + **TypeScript**
- **Vite** — fast build tool
- **React Router v6** — client-side routing
- **Axios** — HTTP client with JWT interceptor (auto-attach token + 401 redirect)
- **Lucide React** — icon library (navbar, forms, post cards, loading states)
- **Context API** — global auth state (`useAuth` hook)

### Infrastructure & DevOps
- **Terraform** — all AWS resources as code (7 child modules)
- **Kubernetes** — Deployment, Service, Ingress, HPA, ConfigMap, Secrets
- **Helm** — AWS Load Balancer Controller, CloudWatch metrics agent
- **Docker** — containerized backend
- **GitHub Actions** — 3 automated CI/CD pipelines

---

## Project Structure

```
miniblog/
├── backend/                        # FastAPI application
│   ├── app/
│   │   ├── main.py                 # App entry, CORS middleware, DB table init
│   │   ├── database/connection.py  # SQLAlchemy engine, session, Base
│   │   ├── models/                 # User, Post ORM models
│   │   ├── routes/                 # auth.py, posts.py
│   │   ├── schemas/                # Pydantic request/response models
│   │   └── services/auth.py        # JWT, bcrypt, get_current_user dependency
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/                       # React + TypeScript SPA
│   ├── src/
│   │   ├── App.tsx                 # Routes + ProtectedRoute wrapper
│   │   ├── components/
│   │   │   ├── Navbar.tsx          # Icons, avatar, styled links
│   │   │   └── PostCard.tsx        # Author/date icons, edit/delete actions
│   │   ├── hooks/useAuth.tsx       # Auth context (login / register / logout)
│   │   ├── pages/
│   │   │   ├── Feed.tsx            # Public post list with loading spinner
│   │   │   ├── Dashboard.tsx       # User's own posts with empty state
│   │   │   ├── Login.tsx           # Icon-enhanced login form
│   │   │   ├── Register.tsx        # Icon-enhanced register form
│   │   │   ├── CreatePost.tsx      # New post form
│   │   │   └── EditPost.tsx        # Edit existing post
│   │   ├── services/api.ts         # Axios instance, JWT + 401 interceptors
│   │   └── styles/index.css        # Full design system (CSS variables, animations)
│   ├── package.json
│   └── vite.config.ts
│
├── infra/                          # Terraform IaC
│   ├── main.tf                     # Root module orchestrating all children
│   ├── variables.tf
│   ├── outputs.tf                  # kubectl configure, ECR login, deploy commands
│   ├── versions.tf                 # Provider pins + S3 remote state backend
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/                    # VPC, subnets, IGW, NAT GWs, route tables
│       ├── iam/                    # EKS cluster + node group IAM roles
│       ├── ecr/                    # Two repos with lifecycle policies
│       ├── eks/                    # Cluster, managed node group, IRSA, Helm
│       ├── rds/                    # PostgreSQL, subnet group, security group
│       ├── s3/                     # Static website bucket, public read policy
│       └── cloudwatch/             # Log groups, SNS alarms, dashboard
│
├── infra/k8s/                      # Kubernetes manifests
│   ├── namespace.yaml
│   ├── backend-deployment.yaml     # 3 replicas, rolling update, probes, security
│   ├── backend-service.yaml        # ClusterIP → ALB backend
│   ├── backend-ingress.yaml        # ALB Ingress (internet-facing, ip target mode)
│   ├── backend-configmap.yaml      # CORS_ORIGINS, Python settings
│   ├── backend-secret.yaml         # Secret template (values injected by CI/CD)
│   ├── backend-serviceaccount.yaml # Linked to IRSA role
│   └── backend-hpa.yaml            # Scale 2–10 replicas at 70% CPU
│
├── .github/workflows/
│   ├── infrastructure.yml          # Terraform plan + apply
│   ├── backend-deploy.yml          # Test → ECR push → EKS rolling deploy
│   └── frontend-deploy.yml         # TypeScript check → Vite build → S3 sync
│
└── docker-compose.yml              # Local dev: backend + postgres
```

---

## CI/CD Pipelines

### Pipeline 1 — Infrastructure
Triggers: push to `infra/**` (excluding `k8s/`) or `workflow_dispatch`

```
terraform fmt check  →  terraform init  →  terraform plan  →  terraform apply
```

### Pipeline 2 — Backend Deploy
Triggers: push to `backend/**` or `infra/k8s/**` or `workflow_dispatch`

```
🧪 Test
  ├── postgres service container
  ├── pytest (if tests exist) or import check
  └── ruff lint

🐳 Build & Push to ECR
  ├── docker build (tags: <sha>, latest, main-<run>)
  └── docker push --all-tags

🚀 Deploy to EKS
  ├── kubectl apply — namespace, secrets, configmap, serviceaccount
  ├── kubectl apply — service, ingress, hpa
  ├── sed image tag into deployment manifest → kubectl apply (rolling update)
  └── kubectl rollout status --timeout=180s

⏪ Rollback (auto, only on deploy failure)
  └── kubectl rollout undo deployment/backend
```

### Pipeline 3 — Frontend Deploy
Triggers: push to `frontend/**` or `workflow_dispatch`

```
🔨 Build
  ├── npm ci
  ├── tsc --noEmit (strict type check)
  └── vite build  (VITE_API_URL baked in from GitHub Secret)

🚀 Deploy to S3
  ├── aws s3 sync dist/ — long cache for hashed assets
  └── index.html + JSON — no-cache headers (always fresh)
```

---

## Kubernetes Details

| Feature | Configuration |
|---------|--------------|
| Replicas | 3 (spread across 2 AZs) |
| Update strategy | RollingUpdate — `maxUnavailable: 1`, `maxSurge: 1` |
| Liveness probe | `GET /health` — restart unhealthy pods |
| Readiness probe | `GET /health` — remove from ALB until ready |
| CPU request/limit | 100m / 500m |
| Memory request/limit | 128Mi / 512Mi |
| Auto-scaling (HPA) | 2–10 replicas at 70% avg CPU |
| Security context | `runAsNonRoot`, `readOnlyRootFilesystem`, no privilege escalation |
| Pod identity | IRSA via OIDC — no AWS credentials in environment |

---

## Database

| Property | Value |
|----------|-------|
| Engine | PostgreSQL 15.14 |
| Instance class | db.t3.small |
| Storage | 20 GB gp3 |
| Multi-AZ | Yes |
| Backup retention | 7 days |
| Network | Private subnet only — no internet access |

### Schema

```sql
CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP
);

CREATE TABLE posts (
    id         SERIAL PRIMARY KEY,
    title      VARCHAR(200) NOT NULL,
    content    TEXT         NOT NULL,
    author_id  INTEGER      NOT NULL REFERENCES users(id),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Pressure Test Results (20 threads × 200 queries = 4,000 ops)

| Metric | Result |
|--------|--------|
| Throughput | **844 queries/sec** |
| Median latency | 1.93 ms |
| p95 latency | 5.72 ms |
| p99 latency | 8.86 ms |
| Errors | **0** |

---

## API Reference

### Auth
| Method | Path | Body | Response |
|--------|------|------|----------|
| `POST` | `/auth/register` | `{username, email, password}` | `{access_token, user}` |
| `POST` | `/auth/login` | `{username, password}` | `{access_token, user}` |

### Posts
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/posts` | — | List all posts |
| `POST` | `/posts` | ✓ | Create post |
| `GET` | `/posts/{id}` | — | Get single post |
| `PUT` | `/posts/{id}` | ✓ owner | Edit post |
| `DELETE` | `/posts/{id}` | ✓ owner | Delete post |

### Health
| Method | Path | Response |
|--------|------|----------|
| `GET` | `/health` | `{"status": "ok"}` |

---

## Local Development

```bash
# Clone the repo
git clone https://github.com/mazenessam77/miniblog.git
cd miniblog

# Start backend + postgres with Docker Compose
docker compose up --build

# Frontend dev server (separate terminal)
cd frontend
npm install
npm run dev
```

| Service | URL |
|---------|-----|
| Frontend | http://localhost:5173 |
| Backend API | http://localhost:8000 |
| Swagger docs | http://localhost:8000/docs |

---

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS credentials for CI |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials for CI |
| `AWS_REGION` | e.g. `us-east-1` |
| `ECR_REPOSITORY` | e.g. `miniblog/backend` |
| `EKS_CLUSTER_NAME` | EKS cluster name |
| `RDS_ENDPOINT` | RDS hostname |
| `RDS_PASSWORD` | RDS master password |
| `JWT_SECRET_KEY` | JWT signing secret (min 32 chars) |
| `S3_BUCKET_NAME` | Frontend S3 bucket name |
| `CLOUDFRONT_DOMAIN` | Frontend URL |
| `API_URL` | Backend ALB URL (baked into frontend build) |

---

## Issues Fixed During Development

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `relation "users" does not exist` | `create_all()` called before model classes imported | Import `app.models.user` and `app.models.post` before `create_all()` |
| `ValueError: password cannot be longer than 72 bytes` | `bcrypt 4.x` incompatible with `passlib 1.7.4` | Pin `bcrypt==3.2.2` |
| ALB not provisioning — `AddTags` denied | IAM policy missing `listener/*` ARN patterns | Add `listener` and `listener-rule` ARNs to `AddTags` resource list |
| ALB not provisioning — `waf-regional` denied | IAM policy missing WAF regional actions | Add `waf-regional:GetWebACL*` / `AssociateWebACL` to IAM policy |
| Terraform fmt failing in CI | Inconsistent HCL formatting | Run `terraform fmt -recursive` before every push |
| `npm ci` fails in CI | `package-lock.json` not committed | Commit `frontend/package-lock.json` |
| Backend image URI blocked as GitHub secret | GitHub Actions masks ECR URLs matching secret patterns | Reconstruct full URI from `aws sts get-caller-identity` in deploy job |
| `workflow_dispatch` jobs skipped | `if: github.event_name == 'push'` excluded manual triggers | Update condition to `(push \|\| workflow_dispatch)` in all deploy jobs |

---

## Author

**Mazen Essam** — [@mazenessam77](https://github.com/mazenessam77)

Built end-to-end: application code, cloud infrastructure, containerization, Kubernetes manifests, and CI/CD pipelines.
