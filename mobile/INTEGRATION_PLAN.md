# INTEGRATION PLAN — Trifecta mobile: mock services → real backend, section by section

Feed this file to Antigravity ONCE. Then work ONE section at a time: I say "do Section N" → Antigravity implements ONLY that section → code is pushed → Muse reviews it → only then the next section. Never do two sections in one pass. Never change a view, controller behaviour, route, or model shape — the service interfaces and models in API_MODELS.md are frozen; you are writing the REAL implementations behind them.

## Ground rules (every section)

1. Backend base URL comes ONLY from the persisted Settings host (default `https://astjq-203-99-61-238.free.pinggy.net`, NO path suffix). All routes below are appended to it.
2. Add the `http` package (`http: ^1.2.0`) in Section 0. No other new dependencies.
3. Every real service lives next to its mock (`<name>_service_real.dart` beside `<name>_service_mock.dart`), implementing the SAME interface. InitialBinding chooses per-service via a boolean flag `useRealApi` in AppConfig (default false). A section flips ONLY its own services' flags to true.
4. All non-2xx responses have the body `{ "error": { "code": "...", "message": "...", "details": {...} } }`. Parse `error.code`, map it through ONE central mapper (Section 0) to the AppStrings wording (API_MODELS.md §5). Raw codes are never displayed.
5. Every mutating call mints its client id ONCE per user action (event_id, order_id, request_id) and reuses it on retry — the controllers already do this; keep it.
6. If the real call fails with a network error (no response), reads fall back to the CacheService copy and the UI shows its normal offline behaviour. Writes NEVER silently fall back to the mock — they queue offline (score/roster) or fail with the plain-language message (checkout).
7. Money stays int minor units end-to-end; timestamps stay ISO 8601 UTC strings in models.

## Backend reality (verified in the repo, 17 Oct 14:40 PKT — Express + Postgres)

LIVE routes: `GET /health`, `GET /api/v1/ping`, `POST /audit/v1/reset`, `POST /audit/v1/sports`, `POST /audit/v1/leagues`, `POST /audit/v1/events`, `GET /audit/v1/score/:match_id`, `GET /audit/v1/standings/:league_id`, `POST /audit/v1/checkout`, `GET /audit/v1/inventory/:variant_id`.
NOT YET BUILT by the backend dev: `POST /audit/v1/fixtures`, roster (`setup` / `transfer` / `history`), `POST /audit/v1/rbac-matrix` + probes, `POST /audit/v1/offline-sync`. Sections 4–6 build the app side against the contract shapes anyway; they light up when the routes land.
DEMO ID ALIGNMENT (critical): the app's fixture match ids (m-alpha-1, …) are the canonical demo ids. The backend registers league-alpha-1 with fixtures using EXACTLY these ids — if an id differs, score reads 404 and the UI must show its not-found state, never fabricate.

## Section 0 — HTTP foundation (no screen changes)

- Implement ApiService for real: `get(path)`, `post(path, body)` returning the app's Result type; builds the URL from the Settings host; sets `Content-Type: application/json`; on non-2xx parses the error body into a Failure carrying the error `code`.
- Create `core/utils/api_error_mapper.dart`: `String userMessageForCode(String code)` covering ALL 27 codes from API_MODELS.md §5, returning the AppStrings key/text. Services use it; the per-mock hardcoded message keys stay for mocks.
- Register ApiService in InitialBinding (it is currently dead), add `useRealApi` flags map in AppConfig (all false for now).
- Smoke target (already live on the backend): `GET /api/v1/ping` → `{"pong": true}`.
- DONE when: analyze clean; a debug-only call to ping through ApiService succeeds against a running backend; no mock behaviour changed (all flags still false).

## Section 1 — Standings + Score reads (backend LIVE)

- StandingsServiceReal: `GET /audit/v1/standings/{league_id}` → parse with the (already snake_case-fixed) models — response key `table`, plus `h2h`. Write-through to CacheService under the league's own key; on network failure serve the cache.
- MatchServiceReal (read half only): `GET /audit/v1/score/{match_id}` → ScoreProjection. Cache per match id. Match detail's 15-second poll now hits the real endpoint when the flag is on.
- Fixtures list stays seed-driven (the contract has no fixtures-list endpoint): FixturesService keeps returning the canonical demo fixtures with the SAME match ids; tapping one now reads its real score.
- Flip flags: standings, match-read. DONE when: with the backend running and a league registered, Standings shows backend data (change a score via the backend → standings move), and a wrong match id shows the not-found state, not a fabricated 0–0.

## Section 2 — Scoring writes (backend LIVE)

- MatchServiceReal (write half): postEvent / compensateEvent → `POST /audit/v1/events` with the exact §5.9 body `{ event_id, match_id, type, payload }`; score payload `{ team_id, event_type }`; compensation payload `{ compensates, reason }`. On 201, refresh the projection from the response/GET.
- Online path only in this section: if the device is offline, the EXISTING queue path handles it (do not change queueing). Backend rejections (MATCH_NOT_IN_PROGRESS, ILLEGAL_TRANSITION, INVALID_COMPENSATION, …) surface via the Section 0 mapper.
- Flip flag: match-write. DONE when: a goal entered in the app appears in a fresh GET /score from another client, and scoring a completed match shows the plain-language refusal.

## Section 3 — Store (backend LIVE)

- StoreServiceReal: catalogue = the contract baseline product (prod-jersey-001, variants var-jersey-001-M/L) — the contract has no catalogue endpoint, so the catalogue stays local seed data, BUT stock is LIVE: `GET /audit/v1/inventory/{variant_id}` drives the variant picker's availability ("Only 1 left" must be the backend's number).
- Checkout → `POST /audit/v1/checkout` with `{ order_id, customer_id, items, discount_code?, payment: { token } }` (tokens tok_success / tok_declined / tok_capture_fail from the payment selector). The receipt view renders the REAL receipt payload and Download saves the REAL pdf_base64 bytes.
- 402/409 responses (PAYMENT_DECLINED, PAYMENT_CAPTURE_FAILED, OUT_OF_STOCK, INVALID_DISCOUNT_CODE) surface via the mapper; the cart survives failures.
- Flip flag: store. DONE when: buying the last M jersey succeeds once, the second attempt shows "Sorry, that item just sold out.", and the downloaded PDF is the backend's signed receipt.

## Section 4 — Roster (backend routes NOT YET LIVE — build app side to contract)

- RosterServiceReal: transfer/loan/release → `POST /audit/v1/roster/transfer` (exact §5.11 body, request_id minted once per submission); history → `GET /audit/v1/roster/history/{player_id}?as_of=<today>` returning the spec object (current_squad_id, parent_squad_id, history[]).
- Rule rejections (TRANSFER_WINDOW_CLOSED, SQUAD_FULL, PLAYER_ON_LOAN, CROSS_TENANT_TRANSFER, MIN_POSITION_VIOLATION, NOT_IN_SQUAD) surface via the mapper. Offline actions keep the existing queue path untouched.
- Flip flag: roster (only once the backend routes exist; until then the flag stays false and the section is "code-complete, unverified"). DONE when (routes live): a transfer made in the app appears in the player's history from a fresh GET, with base_version semantics per §5.14.

## Section 5 — Offline sync (backend route NOT YET LIVE — build app side to contract)

- SyncServiceReal: on connectivity regain (or Sync button), POST the EXACT §5.14 envelope `{ device_id, actions: [...] }` built from the persisted queue to `/audit/v1/offline-sync`. Per-action results map to the sync screen's plain wording (applied+appended → "Sent"; applied+rebased_append → "Sent — the match had moved on…"; duplicate → "Already sent earlier"; rejected → mapper message for its error_code). Queue entries clear ONLY for actions the server acknowledged (applied/duplicate); rejected entries stay visible with their reason until the user dismisses them.
- The response is HTTP 200 even with rejections — treat only a network failure or a 400 envelope error as "sync failed, keep everything".
- Flip flag: sync (once the route exists). DONE when (route live): the full desk-check sequence passes against the real backend — offline goal + transfer queue, force-close, reopen, sync, both applied with correct server_versions.

## Section 6 — Auth tokens (backend route NOT YET LIVE — lowest priority)

- The contract has NO login endpoint: app login stays demo-account based. When `POST /audit/v1/rbac-matrix` exists, AuthServiceReal fetches it once per session and stores the current role's JWT (secure storage) for any probe-guarded call; the visible login flow does not change.
- DONE when: tokens are stored per role and a guarded call carries `Authorization: Bearer <jwt>`; nothing else changes.

## Review loop (how each section closes)

After each section: push the code → Muse fetches it and verifies (a) only the section's services changed, (b) shapes against the contract section cited, (c) analyze clean, (d) the section's DONE criteria by code inspection. Fixes come back as one small prompt. Then the next section starts.
