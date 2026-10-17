# API MODELS — Trifecta frontend integration contract

For the frontend phase, implement every service below as an **interface + mock implementation** returning realistic data in the exact shapes described. A later phase swaps the mocks for real HTTP calls **without changing any view or controller** — so shapes must match the backend contract from day one.

## 1. Global conventions

- **Base URL:** `http://<host>:8080` — port always 8080. Emulator host: `10.0.2.2`. The host comes from the in-app Settings (server address); never hardcode it in a service.
- All request/response bodies are JSON (`Content-Type: application/json`, UTF-8). Bodies over 1 MB are rejected (413).
- **Auth:** the `/audit/v1/*` routes need NO Authorization header (exception: the RBAC probe routes, which the app does not call directly). App login uses the demo accounts in FRONTEND_BRIEF.md; store the returned session token in secure storage (Keystore-backed).
- **Money:** integers in minor units (paisa), currency always `PKR`. 450000 = PKR 4,500.00. Display format: major units, 2 decimals, no thousands separator (`PKR 4500.00`). Discount `WELCOME10` = 10%: `discount_minor = floor(subtotal_minor * 10 / 100)`.
- **Timestamps:** ISO 8601 UTC `YYYY-MM-DDTHH:MM:SSZ`; dates `YYYY-MM-DD`. Cricket overs are a STRING `"{balls div balls_per_over}.{balls mod balls_per_over}"` (e.g. `"3.2"`). Net run rate rounds to 3 decimals.
- **IDs:** strings, case-sensitive, stored and echoed back **verbatim** — never reformat a server id.
- **Idempotency:** every mutating user action gets ONE client-generated id (`event_id`, `order_id`, `request_id`, `action_id`), created when the user performs the action and reused on every retry. Same id + identical body → server returns the stored result (200). Same id + different body → 409 DUPLICATE_*.
- **Rate limit:** `/api/v1/*` is limited to 100 requests per rolling 10 s per IP → 429 with a `Retry-After` header; back off, never hammer. `/audit/v1/*` and `/health` are exempt.
- **Errors:** every non-2xx body is `{ "error": { "code": "...", "message": "...", "details": {...} } }`. Services parse `error.code`; controllers map it to the plain-language wording in §5. **Raw codes are never displayed.**
- Status code meanings: 200 read/replay · 201 created · 400 validation · 401 session · 402 payment · 403 forbidden · 404 not found · 409 conflict · 413 too large · 429 rate limited.

## 2. Services and models (create in `lib/services/<area>/`)

| Service | Wraps (later) | Models to define |
|---|---|---|
| AuthService | demo-account login, session, role | `SessionUser { id, email, role, tenantId }` — role ∈ superAdmin / organizer / clubManager / player / viewer |
| FixturesService | GET score/fixture data (via backend routes) | `MatchSummary { matchId, leagueId, homeTeamId, awayTeamId, status, startsAt }` — status ∈ upcoming / in_progress / completed / postponed / abandoned / cancelled |
| MatchService | GET `/audit/v1/score/{match_id}`, POST `/audit/v1/events` | `ScoreProjection` (§2.1), `MatchEvent` (§2.1) |
| StandingsService | GET `/audit/v1/standings/{league_id}` | `StandingRow` (§2.2), `H2hEntry` |
| ClubService | club profile data | `ClubProfile { clubId, tenantId, name, venueName, venueLat, venueLng, roster: List<Player>, staff: List<StaffMember> }`, `Player { playerId, name, position, role }` |
| RosterService | POST `/audit/v1/roster/transfer`, GET `/audit/v1/roster/history/{player_id}` | `TransferRequest` (§2.3), `TransferResult`, `AuditEntry` |
| StoreService | POST `/audit/v1/checkout`, GET `/audit/v1/inventory/{variant_id}` | `Product`, `Variant`, `CartItem`, `CheckoutResult` (§2.4) |
| SyncService | local queue + POST `/audit/v1/offline-sync` | `QueuedAction` (§3), `SyncResult` (§3) |
| SettingsService | server address, device id | plain values, persisted locally |
| CacheService | local DB (SQLite/Hive) for Fixtures / Standings / Club profile reads | caches the read models above; every list/detail read goes cache-first |

### 2.1 Score projection (from GET /audit/v1/score/{match_id})
`ScoreProjection { matchId, sportId, leagueId?, status (upcoming|in_progress|completed), outcome (pending|home_win|away_win|draw|undecided), winnerTeamId?, tiebreakWinnerTeamId?, home: TeamScore, away: TeamScore, version: int, events: List<MatchEvent> }`
`TeamScore { teamId, score: int, wickets: int?, balls: int?, overs: String?, fairPlay: int }` (wickets/balls/overs only for innings sports, else null)
`MatchEvent { sequence: int, eventId, type (match_init|match_start|score|discipline|tiebreak_winner|match_end|compensation), payload: Map, signature, compensated: bool, compensatedBy: String? }`
Posting an event = POST /audit/v1/events body `{ event_id, match_id, type, payload }`; score payload = `{ team_id, event_type }`; compensation payload = `{ compensates: <event_id>, reason }`. Response 201: `{ event_id, match_id, type, sequence, match_version, signature }`.

### 2.2 Standings (from GET /audit/v1/standings/{league_id})
`StandingRow { rank, teamId, played, won, drawn, lost, scored, conceded, diff (num — net run rate for innings sports), points, fairPlay, status (clinched|eliminated|still_possible), resolvedBy: String? }`
Response also carries `leagueId, sportId, qualificationSpots, h2h` (map teamId → map teamId → `{played, points, scored, conceded}`).

### 2.3 Roster transfer (POST /audit/v1/roster/transfer)
Request `TransferRequest { requestId, leagueId, playerId, type (transfer|loan|release), fromSquadId, toSquadId? (null for release), effectiveDate, loanEndDate? (required for loan, must be after effectiveDate), reason, requestedBy }`
Response 201 `TransferResult { requestId, status: "accepted", state (active|deferred_until_match_end), blockingMatchId?, registration?, auditEntry }` — `registration` is null for release; `auditEntry { auditId, action, playerId, leagueId, fromSquadId, toSquadId, state, who, when, effectiveDate, why }`.
History (GET /audit/v1/roster/history/{player_id}?as_of=YYYY-MM-DD): `{ playerId, asOf, leagueId, currentSquadId?, parentSquadId?, history: List<AuditEntry> }` (oldest first).

### 2.4 Checkout (POST /audit/v1/checkout)
Request `{ order_id, customer_id, items: [{ variant_id, quantity }], discount_code?, payment: { token } }` — mock gateway tokens: `tok_success`, `tok_declined` (→ 402 PAYMENT_DECLINED), `tok_capture_fail` (→ 402 PAYMENT_CAPTURE_FAILED). Out of stock → 409 OUT_OF_STOCK (variant in `details.variant_id`); unknown code → 400 INVALID_DISCOUNT_CODE.
Success 201 `CheckoutResult { orderId, status: "paid", currency: "PKR", items: [{ variantId, quantity, unitPriceMinor }], subtotalMinor, discountMinor, totalMinor, payment: { authorizationId, captureId, state: "captured" }, receipt: { payload: Map, signature, pdfBase64 } }` — `pdfBase64` decodes to the receipt PDF (starts with `%PDF`); the receipt view displays it and offers download.
Inventory (GET /audit/v1/inventory/{variant_id}): `{ variantId, stock, reserved }`.

## 3. Offline queue — EXACT format (contract §5.14)

Queued actions are stored in the local DB in exactly this envelope and POSTed to `/audit/v1/offline-sync` on sync:

```json
{ "device_id": "dev-1",
  "actions": [
    { "action_id": "a1", "type": "score_event", "queued_at": "2026-10-17T11:00:00Z", "base_version": 3,
      "payload": { "event_id": "evt-9", "match_id": "m1", "type": "score", "payload": { "team_id": "t1", "event_type": "goal" } } },
    { "action_id": "a2", "type": "roster_transfer", "queued_at": "2026-10-17T11:01:00Z", "base_version": 1,
      "payload": { "... the exact /roster/transfer body ..." } }
  ] }
```

- `type` is only ever `score_event` (payload = the /events body) or `roster_transfer` (payload = the /roster/transfer body). 1–100 actions per sync.
- `base_version`: the version the device last saw — for a score_event, the match's `version` (event count); for a roster_transfer, the player's audit-entry count.
- Response is **always HTTP 200** (only a malformed envelope is 400):
  `{ device_id, results: [{ action_id, status, resolution, error_code, processed_order, server_version, signature }], summary: { applied, rejected, duplicate } }`
- Per-action meanings for the UI:
  - `applied` + `appended` → sent cleanly → "Sent"
  - `applied` + `rebased_append` → device was stale, server added it on top → "Sent — the match had moved on, so it was added on top"
  - `duplicate` + `skipped_duplicate` → already processed before → "Already sent earlier"
  - `rejected` + `server_wins` → show the plain-language message for `error_code` from §5 (`INVALID_BASE_VERSION` is sync-only and means the action was based on out-of-date information)
- Re-sending the same sync request is safe: every action returns `duplicate` and nothing changes. The queue clears only after results are displayed to the user.

## 4. Backend endpoint index (for reference — the real wiring phase uses these)

`GET /health` · `POST /audit/v1/reset` · `POST /audit/v1/sports` · `POST /audit/v1/fixtures` · `POST /audit/v1/leagues` · `POST /audit/v1/events` · `GET /audit/v1/score/{match_id}` · `GET /audit/v1/standings/{league_id}` · `POST /audit/v1/roster/setup` · `POST /audit/v1/roster/transfer` · `GET /audit/v1/roster/history/{player_id}` · `POST /audit/v1/checkout` · `GET /audit/v1/inventory/{variant_id}` · `POST /audit/v1/rbac-matrix` · `POST /audit/v1/offline-sync` · `GET /api/v1/ping`

## 5. Error code → user wording (the ONLY wording users ever see)

| Code | Show the user |
|---|---|
| VALIDATION_ERROR | "Some details are missing or don't look right. Please check and try again." |
| UNKNOWN_EVENT_TYPE | "That scoring action isn't part of this sport." |
| INVALID_DISCOUNT_CODE | "That discount code isn't valid." |
| UNAUTHENTICATED | "Your session has expired. Please sign in again." |
| PAYMENT_DECLINED | "Your payment was declined. No money was taken — please try a different payment option." |
| PAYMENT_CAPTURE_FAILED | "The payment couldn't be completed and has been reversed. Please try again." |
| FORBIDDEN | "You don't have permission to do this." |
| *_NOT_FOUND (SPORT/LEAGUE/MATCH/PLAYER/SQUAD/VARIANT/EVENT) | "That could not be found. It may have been removed." (name the thing: league, match, player, product…) |
| SPORT_EXISTS / LEAGUE_EXISTS / MATCH_EXISTS | "That already exists." |
| DUPLICATE_EVENT_ID / DUPLICATE_ORDER_ID | "This was already submitted with different details, so it can't be sent again." |
| ILLEGAL_TRANSITION | "That can't be done while the match is in its current state." |
| MATCH_NOT_IN_PROGRESS | "This match isn't in progress, so scores can't be added right now." |
| TIE_NOT_ALLOWED | "This match can't end in a tie — a tie-break winner is needed." |
| INNINGS_COMPLETE | "This innings is already complete." |
| SERIES_ALREADY_DECIDED | "This series has already been decided." |
| INVALID_COMPENSATION | "That event can't be corrected — it may already have been corrected." |
| NO_VALID_PAIRING | "No fair pairing is possible for this round." |
| OUT_OF_STOCK | "Sorry, that item just sold out." |
| TRANSFER_WINDOW_CLOSED | "The transfer window is closed for this league." |
| NOT_IN_SQUAD | "That player isn't in this squad." |
| SQUAD_FULL | "That squad is already full." |
| PLAYER_ON_LOAN | "That player is currently on loan and can't be moved." |
| CROSS_TENANT_TRANSFER | "Players can't be moved between different organisations." |
| MIN_POSITION_VIOLATION | "That move would leave the squad without enough players in a required position." |
| INVALID_BASE_VERSION (sync only) | "This change was based on out-of-date information and wasn't applied." |
| PAYLOAD_TOO_LARGE | "That request is too large to send." |
| RATE_LIMITED | "Too many requests — please wait a few seconds and try again." |
