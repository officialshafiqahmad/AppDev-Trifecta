# Architecture Decision Record — Team Trifecta, Part I

## ADR-1 Express + PostgreSQL + Redis on Docker Compose

The official grader starts one command: `DAY1_SALT=<salt> docker compose up -d --build`, then polls `GET /health` on host port 8080. We used Node 20 and Express because the audit wrappers are HTTP JSON contracts, PostgreSQL 16 for transactional inventory and event append, and Redis 7 for rate limiting plus the internal order-event list. Compose forwards `DAY1_SALT: ${DAY1_SALT}` and never hard-codes the salt.

## ADR-2 Configuration-driven sports, not sport name branches

Mystery-sport grading forbids hard-coded football/cricket/esports logic. Sport rules live as JSON (`scoring_model`, `scoring_events`, periods, draw policy, tie-break order, roster limits). Scoring and standings branch only on those fields. Adding a sport is `POST /audit/v1/sports`.

## ADR-3 Event-sourced scores with compensation

Live scores are projections of an append-only `match_events` log. Corrections append a compensation row signed with `DAY1_SALT`; historical rows are never updated. Standings rebuild from the same projections on every `GET /audit/v1/standings/{league_id}` so a later compensation immediately changes points, H2H, rank, and qualification.

## ADR-4 Checkout reservation in one PostgreSQL transaction

The 20-buyer / last-unit vector requires one success and zero negative stock. Checkout locks the variant row (`SELECT FOR UPDATE`), reserves, captures the mock token, then commits or releases. Redis is not the inventory source of truth.

## ADR-5 Policy function for five-tier RBAC

Roles are seeded users. Authorization is a reusable `can(actor, action, resource)` matrix plus HS256 JWTs. `/audit/v1/*` stays grader-open except the RBAC probe routes. `/api/v1/*` uses a Redis sliding window of 100 requests / 10 seconds.

## ADR-6 Supporting queue, worker, and object store

Section 1.3 requires cache, queue, object store, and workers in Compose. Cache and queue are official `redis:7-alpine` images already used by the API. Object store and worker reuse the same backend image (`node:20-bookworm-slim`) so the grader does not pull an extra vendor image. The worker drains `trifecta:order-events` and writes JSON objects; API health does not depend on worker liveness beyond Compose startup of the object store.

## ADR-7 Offline-first sync queue with replay idempotency

Field operators enter scores, disciplinary actions, and roster adjustments in unpredictable connectivity environments. Client writes are immediately enqueued in a durable local sync queue with monotonic client sequence numbers and deterministic idempotency keys (`action_id`). An always-visible `SyncIndicator` reflects connectivity and pending queue depth. When connectivity is restored, the queue replays operations in sequence against `/api/v1/*` with exponential backoff and compensation handling on rejection.

## ADR-8 Contract-first integration behind useRealApi feature flags

Day 2 streaming, co-stream sessions, and guest web features require progressive backend integration without disrupting Phase I stability. All network services implement abstract interfaces with two implementations: a hermetic in-memory mock and an HTTP/SSE real API client. Service instantiation is governed by `AppConfig.useRealApi[serviceKey]` toggles injected via `--dart-define` or runtime settings. If live backend endpoints or media hosts are unreachable, the UI gracefully retains honest degraded states (e.g., "Waiting for stream signal") rather than crashing or displaying fabricated live indicators.

