# Traceability

Official FR/NFR IDs from `docs/TRIFECTA_Part1_Full_Contract.txt` mapped to the source and tests that actually exist. Unimplemented items are marked **not implemented**.

| ID | Requirement | Source | Tests | Status |
| --- | --- | --- | --- | --- |
| FR-1.1 | Multi-sport taxonomy and event-sourced scoring | `backend/src/sports.js`, `backend/src/scoring.js`, `backend/src/canonical.js`, `backend/src/app.js` | `tests/validation.test.js`, `backend/test/sports.test.js`, `backend/test/scoring.unit.test.js`, `backend/test/canonical.test.js`, `backend/test/module2.http.test.js` | Implemented. Mystery sports are JSON-only. Scores are projections; compensations append. |
| FR-1.2 | League and tournament setup | `backend/src/leagues.js`, `backend/src/app.js` | `backend/test/module2.http.test.js` | Partial. Single-stage leagues with supplied fixtures, points, and tie-break config work. Multi-division promotion/relegation and hybrid knockout setup are **not implemented**. |
| FR-1.3 | Match and fixture scheduling | none | none | **Not implemented.** `POST /audit/v1/fixtures` is absent. No circle-method, Swiss, single-elim, or double-elim generator. |
| FR-1.4 | Automated standings and tables | `backend/src/standings.js`, `backend/src/app.js` | `backend/test/standings.unit.test.js`, `backend/test/module5.http.test.js` | Implemented. Event/round/innings diffs, mini-league H2H, recursive `resolve(group)`, SHA256 `draw_lots`, clinched/eliminated/still_possible. |
| FR-2.1 | Club profiles and tenant isolation | `backend/src/baseline.js`, `backend/src/schema.sql`, `backend/src/rbac.js` | `backend/test/module4.http.test.js` | Partial. Baseline tenants/clubs/players exist. Tenant isolation is enforced on RBAC probes. Dedicated club-portal fields (venue, socials, staff history) are **not implemented**. |
| FR-2.2 | Roster and player registry | none | none | **Not implemented.** `POST /audit/v1/roster/setup`, `/roster/transfer`, and `/roster/history/{player_id}` are absent. |
| FR-2.3 | Club merchandise store | `backend/src/store.js`, `backend/src/pdf.js`, `backend/src/app.js`, `backend/src/worker.js` | `backend/test/store.unit.test.js`, `backend/test/module3.http.test.js`, `tests/http.test.js` | Implemented for catalogue variants, checkout, inventory, mock pay, signed PDF. Order-state machine beyond Paid and real-time product pinning are **not implemented**. |
| FR-5.1 | Five-tier RBAC | `backend/src/rbac.js`, `backend/src/jwt.js`, `backend/src/baseline.js` | `backend/test/rbac.unit.test.js`, `backend/test/module4.http.test.js` | Implemented. Super-admin, organizer, manager, player, viewer with tenant/league/club/player scope. |
| NFR-3 | Concurrency correctness | `backend/src/store.js` | `backend/test/module3.http.test.js` | Implemented. 20 parallel checkouts on stock 1 → 1×201, 19×409, stock 0, reserved 0. |
| NFR-4 | Offline tolerance | `mobile/lib/services/sync/sync_service.dart`, `mobile/lib/features/sync_status/` | `mobile/test/sync_service_test.dart` | Partial on mobile (local queue UI). Backend `POST /audit/v1/offline-sync` is **not implemented**. |
| NFR-5 | Security | `backend/src/jwt.js`, `backend/src/ratelimit.js`, `backend/src/rbac.js`, `backend/src/app.js` | `backend/test/rbac.unit.test.js`, `backend/test/module4.http.test.js` | Partial. JWT HS256, `/api/v1` rate limit, 1 MB body cap, input validation. Mobile Keystore/Keychain is owned by the mobile branch. |
| NFR-7 | Reproducibility | `docker-compose.yml`, `backend/Dockerfile`, `backend/src/index.js`, `backend/src/db.js`, `backend/src/baseline.js` | `tests/http.test.js`, `backend/test/http.integration.test.js`, `./run_tests.sh` | Implemented. `DAY1_SALT=<salt> docker compose up -d --build` then `GET /health`. |
| Section 5.3 | HMAC Appendix A | `backend/src/canonical.js` | `tests/canonical.test.js`, `backend/test/canonical.test.js` | Implemented. Vector 1 signature and vector 2 lots keys. |
| Section 5.4 | `GET /health` | `backend/src/app.js` | `tests/http.test.js`, `backend/test/http.integration.test.js` | Implemented. |
| Section 5.5 | `POST /audit/v1/reset` | `backend/src/baseline.js`, `backend/src/schema.sql`, `backend/src/day2/baseline.js` | `tests/http.test.js`, `backend/test/reset.test.js`, `backend/test/day2-sign.test.js` | Implemented. Day 1 response body is unchanged. Reset also seeds `player-beta-2`, `match-m1` at 1-0 in progress, three QR short links, `guest_anon_tok_7721`, and an empty `player-alpha-1` cart. |
| Section 5.6 | `POST /audit/v1/sports` | `backend/src/sports.js`, `backend/src/app.js` | `tests/validation.test.js`, `tests/http.test.js` | Implemented. |
| Section 5.7 | `POST /audit/v1/fixtures` | none | none | **Not implemented.** |
| Section 5.8 | `POST /audit/v1/leagues` | `backend/src/leagues.js` | `backend/test/module2.http.test.js` | Implemented. |
| Section 5.9 | Events and score projection | `backend/src/scoring.js` | `backend/test/scoring.unit.test.js`, `backend/test/module2.http.test.js` | Implemented. |
| Section 5.10 | `GET /audit/v1/standings/{league_id}` | `backend/src/standings.js` | `backend/test/standings.unit.test.js`, `backend/test/module5.http.test.js` | Implemented. |
| Section 5.11 | Roster endpoints | none | none | **Not implemented.** |
| Section 5.12 | Checkout and inventory | `backend/src/store.js`, `backend/src/pdf.js` | `backend/test/module3.http.test.js` | Implemented. |
| Section 5.13 | RBAC matrix, probes, rate limit | `backend/src/rbac.js`, `backend/src/ratelimit.js` | `backend/test/module4.http.test.js` | Implemented. |
| Section 5.14 | `POST /audit/v1/offline-sync` | none | none | **Not implemented.** |
| Section 8.3 | Demo accounts | `backend/src/baseline.js` | `tests/http.test.js` | Implemented. Password `Nascon@26` for all five emails. |

## Phase II (in progress)

| ID | Requirement | Source | Tests | Status |
| --- | --- | --- | --- | --- |
| Section 5.2 | Phase II reset seeds | `backend/src/day2/baseline.js`, `backend/src/schema.sql` | `backend/test/day2-sign.test.js`, `backend/test/http.integration.test.js` | Implemented. Live `POST /audit/v1/reset` keeps the Day 1 body and seeds `player-beta-2`, `match-m1` (in progress, 1-0), three QR links, `guest_anon_tok_7721`, and an empty cart. |
| Section 5.3 | `DAY2_SALT` HMAC | `backend/src/day2/sign.js`, `docker-compose.yml` | `backend/test/day2-sign.test.js`, `backend/test/day2-phase2.unit.test.js` | Implemented for the Appendix A reference vectors. Salt is read from the environment. |
| Section 5.4 | `POST /audit/v1/stream/key` | `backend/src/day2/stream-key.js`, `backend/src/app.js` | `backend/test/day2-phase2.unit.test.js`, `backend/test/day2.http.test.js` | Implemented. Generate returns 201, rotate and revoke return 200, revoked overrides return 409 `KEY_REVOKED`. Media ingest itself is not verified. |
| Section 5.5 | `POST /audit/v1/costream/session` | `backend/src/day2/costream.js`, `backend/src/app.js` | `backend/test/day2-phase2.unit.test.js`, `backend/test/day2.http.test.js` | Implemented. Four-participant host drop, sole-host termination, layout checks, and identical-request replay. Composite playback is a URL, not a verified media mix. |
| Section 5.6 | QR metadata, short link, exports | `backend/src/day2/qr.js`, `backend/src/day2/qr-image.js`, `backend/src/app.js` | `backend/test/day2-phase2.unit.test.js`, `backend/test/day2.http.test.js` | Implemented for seeded `match-m1`, players, clubs, and co-stream sessions. `/q/m1-live` returns 302 to the live or VOD route. SVG, PNG, and PDF exports encode the short URL. |
| Section 5.7–5.9 | Guest merge, moderation, metrics, erasure | none | none | **Not implemented.** |
