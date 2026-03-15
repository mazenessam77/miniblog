# MiniBlog Platform

A full-stack blogging platform with React frontend, FastAPI backend, JWT authentication, and PostgreSQL database.

## Architecture

```
Frontend (React + Vite)  →  Backend (FastAPI)  →  PostgreSQL
     :3000                      :8000                :5432
```

## Quick Start with Docker Compose

```bash
docker compose up --build
```

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs (Swagger): http://localhost:8000/docs

## Manual Setup

### Prerequisites

- Python 3.11+
- Node.js 20+
- PostgreSQL 15+

### Database

```bash
# Create the database
createdb miniblog
```

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Set environment variables (optional — defaults work for local dev)
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/miniblog
export SECRET_KEY=your-secret-key

# Run the server
uvicorn app.main:app --reload --port 8000
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## API Endpoints

### Authentication

| Method | Endpoint         | Description       | Auth |
|--------|------------------|-------------------|------|
| POST   | `/auth/register` | Register new user | No   |
| POST   | `/auth/login`    | Login             | No   |

### Posts

| Method | Endpoint       | Description     | Auth |
|--------|----------------|-----------------|------|
| GET    | `/posts`       | List all posts  | No   |
| GET    | `/posts/{id}`  | Get single post | No   |
| POST   | `/posts`       | Create post     | Yes  |
| PUT    | `/posts/{id}`  | Update post     | Yes  |
| DELETE | `/posts/{id}`  | Delete post     | Yes  |

### Health

| Method | Endpoint  | Description  |
|--------|-----------|--------------|
| GET    | `/health` | Health check |

## Database Schema

### users

| Column        | Type         | Constraints       |
|---------------|--------------|-------------------|
| id            | INTEGER      | PK, auto          |
| username      | VARCHAR(50)  | UNIQUE, NOT NULL  |
| email         | VARCHAR(100) | UNIQUE, NOT NULL  |
| password_hash | VARCHAR(255) | NOT NULL          |
| created_at    | TIMESTAMP    | DEFAULT now()     |

### posts

| Column     | Type         | Constraints            |
|------------|--------------|------------------------|
| id         | INTEGER      | PK, auto               |
| title      | VARCHAR(200) | NOT NULL               |
| content    | TEXT         | NOT NULL               |
| author_id  | INTEGER      | FK → users.id NOT NULL |
| created_at | TIMESTAMP    | DEFAULT now()          |
| updated_at | TIMESTAMP    | DEFAULT now()          |

## Project Structure

```
miniblog/
├── backend/
│   ├── app/
│   │   ├── database/
│   │   │   └── connection.py
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   └── post.py
│   │   ├── schemas/
│   │   │   ├── user.py
│   │   │   └── post.py
│   │   ├── services/
│   │   │   └── auth.py
│   │   ├── routes/
│   │   │   ├── auth.py
│   │   │   └── posts.py
│   │   └── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Navbar.tsx
│   │   │   └── PostCard.tsx
│   │   ├── pages/
│   │   │   ├── Login.tsx
│   │   │   ├── Register.tsx
│   │   │   ├── Dashboard.tsx
│   │   │   ├── CreatePost.tsx
│   │   │   ├── EditPost.tsx
│   │   │   └── Feed.tsx
│   │   ├── services/
│   │   │   └── api.ts
│   │   ├── hooks/
│   │   │   └── useAuth.tsx
│   │   ├── styles/
│   │   │   └── index.css
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── Dockerfile
├── docker-compose.yml
└── README.md
```
