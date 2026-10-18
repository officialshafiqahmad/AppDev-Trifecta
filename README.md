# Trifecta — NaSCon 2026

Part I: Multi-Sport League & Club Operations Platform

Backend: Node.js 20, Express, PostgreSQL 16, Redis 7.
Mobile: Flutter Android.
API host port: 8080.

The backend must start using Docker Compose.
All graded audit endpoints follow the official Part I specification.

## Run

Copy `.env.example` to a local `.env` if you want Compose to read extra variables. Do not put the real team salt in Git.

From the repository root:

```bash
DAY1_SALT=demo-salt docker compose up -d --build
```

That command starts the API on host port 8080 plus PostgreSQL, Redis cache, an internal Redis queue, a self-hosted object store, and a worker. No other host software is required.

`GET http://localhost:8080/health` returns `{"status":"ok"}` when PostgreSQL is reachable and baseline data is seeded. The grader polls this endpoint after Compose returns.

`POST http://localhost:8080/audit/v1/reset` rebuilds the official baseline. It is repeatable.

`./run_tests.sh` runs unit tests first, then the live HTTP suite when the API is already healthy.

## Demo accounts

These accounts exist after startup and after every `POST /audit/v1/reset`. Password for every account is `Nascon@26`.

| Role | Email | Password |
| --- | --- | --- |
| Platform Super-Admin | `admin@nascon.test` | `Nascon@26` |
| League Organizer (owns `league-alpha-1`) | `organizer@nascon.test` | `Nascon@26` |
| Club Manager (owns `club-alpha-1`) | `manager@nascon.test` | `Nascon@26` |
| Player (`player-alpha-1`) | `player@nascon.test` | `Nascon@26` |
| General Viewer | `viewer@nascon.test` | `Nascon@26` |
