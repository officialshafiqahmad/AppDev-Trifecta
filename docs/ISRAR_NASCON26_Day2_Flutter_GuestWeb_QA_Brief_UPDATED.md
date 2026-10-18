# Team Trifecta — Day 2 Frontend & QA Execution Brief (v2)

**Date:** Sunday, October 18, 2026 (PKT)  
**For:** Israr (mobile/frontend owner), Antigravity (implementation/testing), Muse (frontend asset author)  
**Repository:** `https://github.com/officialshafiqahmad/AppDev-Trifecta` — work on existing repo and branch `feature/mobile`  
**Binding source:** Official `App Dev Day 2 Problem Statement.pdf`; searchable project copy `docs/NASCON26_Day2_Full_Specification_Agent_Readable.md`. If any brief/agent plan disagrees with the official PDF, follow the PDF. This document is a *task allocation and safe execution brief*, not a substitute for the requirements.

## 0. IMPORTANT STATUS UPDATE — read before changing files

**Muse has ALREADY generated a Guest Web Player ZIP (`webplayer.zip`).** It is an **unverified implementation starting point**, not a tested, finished frontend. Do **not** rebuild the web player from scratch. Extract the *contents* of the ZIP's `webplayer/` folder into repository-root `web/`, preserving `web/assets/`, `web/matches/`, and `web/costream/`.

Inspected ZIP contents:

- `web/assets/player.js`, `web/assets/player.css`
- `web/matches/match-m1/live/index.html`
- `web/matches/match-m1/preview/index.html`
- `web/matches/match-m1/vod/index.html`
- `web/matches/match-m1/notice/index.html`
- `web/costream/cs-session-101/index.html`

**Already present (static inspection only):** all nine exact grader `data-testid` attributes on live and co-stream pages, zero-login initial layout, local guest-cart count behavior, modal markup, WebSocket and SSE listeners, and match-state page templates. These are NOT independently verified in a browser/backend test.

**Known integration issues to correct/test:**

1. HTML references to `../../../assets/player.js`/`.css` (and co-stream equivalents) can resolve to **`/assets/...` instead of `/web/assets/...`** when grader opens `/web/matches/match-m1/live` **without a trailing slash**. Use **root-absolute `/web/assets/player.js` and `/web/assets/player.css`** (or validate server redirects and asset loading on the exact grader URL). Check all page templates.
2. Video URLs use hardcoded `http://localhost:8888/...`; in a remote Android or Selenium-node browser, `localhost` means that device/container, **not necessarily Shafiq's media host**. Coordinate a browser-reachable media URL with Shafiq; do not claim playback passes until an actual media ingest/playback test works. Keep an honest `waiting for stream` state until then.
3. The seeded guest token is hardcoded in JS as a fallback: `guest_anon_tok_7721`. This is a deterministic test seed, **not a production token issuing flow**. Shafiq must provide the actual guest-token backend boundary; do not invent authentication/security responses in frontend.
4. Guest cart is staged in `localStorage`; **server-side atomic merge, inventory checks, and replay idempotency are backend responsibilities**, not implemented by the ZIP.
5. Initial score and co-stream participants are hardcoded. Real updates and host handoff require Shafiq's API/event stream; WebSocket/SSE listener existence is not proof those events are working.
6. The current `fetch('/api/v1/chat')` error handler opens the registration modal even on a **network failure**. Fix UI handling so an actual **HTTP 403 `GUEST_WRITE_FORBIDDEN`** causes the progressive-auth flow; show a distinct network/server error if the request fails. Never append a guest chat message as if it succeeded.
7. The ZIP does **not** supply athlete/club detail pages or an actual server mount. Do not claim these routes are finished. Shafiq owns `/web/*` serving and `/q/*` HTTP 302 routing.

## 1. Absolute scope boundary — preserve Day 1

Yesterday's Part I is **frozen**. Keep the existing repository, Android project, UI flows, application ID, packages, navigation, auth, and release conventions. Day 2 must be **additive and backward-compatible**. Do not revisit or polish yesterday's multi-sport, rosters, leagues, store, or other existing functionality unless narrowly necessary for a new Day 2 integration and approved by Shafiq.

Never create a second repository/app, rewrite Git history, force push, hard reset, delete existing tests, or replace working Phase I functionality. Existing main history must remain descended from the official `DAY1_BASE_SHA`. A previous mobile release APK exists; back it up as appropriate and replace it only with a **new successfully built and verified** Android APK.

## 2. Ownership and coordination — no overlapping edits

**Israr / Antigravity own:**
- `mobile/` — Flutter deep-link routing, new Match Live / Co-Stream / broadcasting UI, scanner (lower priority), mobile tests, rebuilt release APK.
- `web/` — import, inspect, minimally repair and integrate Muse's generated guest web frontend.
- `tests/selenium/` — parallel Selenium Grid browser acceptance tests.
- `tests/appium/` — Appium 2 native deep-link and cross-surface tests.
- Frontend-only documentation and actual QA evidence produced by these tests.

**Shafiq / Cursor own:**
- `backend/`, DB, `/audit/v1/*` and `/api/v1/*` backend endpoints, guest authorization, QR HTTP 302, `/web/*` static-file serving, real-time score/chat bus, server-side cart merge and moderation, media server.
- Root `docker-compose.yml`, Selenium Grid **infrastructure** (Hub + >=3 nodes), MinIO, `DAY2_SALT`, GitHub Actions, `tests/k6_load.js`, backend coverage.
- Coordinating integration to `main` and checkpoint pushes.

**Do not independently edit** `backend/`, `docker-compose.yml`, `.github/workflows/`, `tests/k6_load.js`, `COVERAGE_DAY2.json`, or other backend-owned paths. Raise required API behavior to Shafiq promptly. Shafiq must serve the new web assets on port **8080** at exact `/web/*` paths. The frontend must not rely on a separate graded port.

Muse's files are owned by Israr after import; **Antigravity may make targeted fixes and API integration changes in `web/`**. The old instruction "do not edit web/" is superseded: *do not rebuild it; do fix actual test and integration failures.* Avoid concurrent Muse/Antigravity edits to the same files.

## 3. PRIORITY P0 — Start execution immediately

### P0-A. Native Android deep links

Required **exact URIs**:
- `nascon://entity/match-m1` -> native **Match Live** screen.
- `nascon://stream/cs-session-101` -> native **Co-Stream** screen.

Register Android `VIEW`, `DEFAULT`, `BROWSABLE` intent filter for `nascon`. Handle both **cold start** and **already-running app**, maintain existing navigation/auth flows, and open public content **without a login wall**. Target foreground and correct screen **within 2 seconds** and no crash.

Verify on an authorized device with:

```bash
adb devices
adb shell am start -W -a android.intent.action.VIEW -d 'nascon://entity/match-m1'
adb shell am start -W -a android.intent.action.VIEW -d 'nascon://stream/cs-session-101'
```

Do not claim PASS just because `am start` exits successfully; verify the expected screen and actual elapsed time using Appium or observation. Do not damage unrelated phone data.

### P0-B. Import Muse's web player and check its real browser behavior

1. Extract only needed ZIP contents into the new root `web/` directory; preserve the directory hierarchy; avoid accidentally nesting `webplayer/webplayer/` or overwriting other work.
2. Fix/verify root-absolute static asset URLs **for the exact grader URLs without trailing slashes**.
3. Confirm zero login prompts on initial load, working player shell, visible initial score, pinned jersey, local staged guest cart and progressive modal only when genuinely blocked.
4. Do not replace live video/data with fake success indicators. If the backend/media isn't online, report **BLOCKED by backend** rather than **PASS**.
5. Communicate the required static serving and API paths to Shafiq. Test the actual `http://localhost:8080` once mounted, not just a local HTML-file preview.

**Nine exact case-sensitive `data-testid` attributes** on live **and** co-stream pages:

`guest-video-player`, `live-score-banner`, `pinned-merch-card`, `add-to-guest-cart-btn`, `guest-cart-count`, `chat-message-list`, `chat-input-field`, `chat-send-btn`, `progressive-auth-modal`.

Their **behavior**, not only existence, is graded. Cart count `0 -> 1`; modal hidden initially and displayed after a rejected guest write; live score updates within **500 ms**; chat list displays actual delivered messages and masked profanity. Preserve keyboard navigation, semantic ARIA labels, contrast at least **4.5:1**, and touch targets at least **48x48 CSS px**.

### P0-C. Validate and deliver checkpoint work

- Work on `feature/mobile` in the same repository. Before pulling/merging, inspect `git status --short`, `git fetch origin`, and preserve Antigravity's local changes; never reset or overwrite uncommitted work.
- Commit only deliberate `mobile/`, `web/`, `tests/selenium/`, `tests/appium/`, and reviewed `.md` documentation changes. **Do not use `git add .` blindly.** Do not commit secrets, a venue slip, temporary files, or generated unverified reports.
- Push **your own branch** when the targeted changes have passed checks; send commit SHA, changed files, and validation results to Shafiq. **Shafiq alone coordinates `main`** to avoid conflicts. A feature-branch push may not satisfy the checker if the scorer expects `main`.
- The official Sunday windows are **10:15–11:30; 11:30–12:45; 12:45–13:45; 13:45–14:00 PKT**. Code freeze **14:00**; hard push lock **14:05**. Do not hold completed work awaiting later polish. If a window has already passed, immediately focus on the next; never falsify a push timestamp.

## 4. PRIORITY P1 — Automated acceptance

### Selenium: `tests/selenium/test_guest_grid.py`

Run against **live backend-served pages** via Grid port `4444`, with at least **three registered nodes** (Chrome + Firefox). Execute with `pytest -n 3 tests/selenium/` and record real results.

Three graded scenarios:
1. Opening `http://localhost:8080/q/m1-live` redirects to `/web/matches/match-m1/live`, renders video container and score within **3 seconds**, initial auth modal hidden.
2. Fresh guest enters chat and sends: backend returns **403**, no message is added, registration modal becomes visible.
3. Fresh guest adds jersey to cart -> count `1`; after backend score event, banner updates within **500 ms**, without reload.

When WebDriver runs *inside a Docker browser node*, node-local `localhost:8080` does not necessarily reach the host API. Use a tested host route/service DNS **without changing the grader's external URL contract**; coordinate with Shafiq. Never report a static DOM-only check as passing server integration.

### Appium: `tests/appium/test_mobile_deeplink.py`

Server on `http://localhost:4723` using Appium 2 + UiAutomator2. Assert both native links open correct screens within **2 seconds**. Add an actual cross-surface test where phone joins/initiates `cs-session-101` while Selenium opens `/web/costream/cs-session-101` and delivered chat appears within **3 seconds**. Record measured PASS/FAIL or BLOCKED; do not fabricate synchronized chat when backend transport is absent.

The existing physical Android device may be shared with Shafiq; coordinate USB access and avoid destructive settings/data operations. `adb reverse tcp:8080 tcp:8080` can support a *USB-attached phone* with `127.0.0.1:8080` API addressing, but a browser, Docker node, or another host requires an independently reachable address.

## 5. PRIORITY P2 — Streaming mobile UI, then lower-priority features

After deep links, imported web player, and basic tests are stable:

1. Match Live screen with *real* scoreboard/overlay/merch/chat updates from agreed backend events.
2. Co-Stream grid (`solo`, `grid_2`, `grid_4`, `spotlight`), active host, participants, common chat, and deterministic host handoff surfaced in UI. Keep chat/session ID stable after handoff.
3. Solo broadcaster camera interface and real WHIP/RTMP path *if media ingest is available*. Test actual transport; a camera preview is not a working stream.
4. Backend-driven notifications where feasible.
5. Native QR scanning when primary graded integration is working.
6. Athlete profile/social graph only if priority work is verified and time remains. **This feature remains part of the official Day 2 specification; it is deferred by team prioritization, not removed from the rubric.**

Finalize `mobile/release/app-release.apk` only after a successful build and installation, then rerun both deep-link checks on the *actual release candidate*. Preserve existing Day 1 package/application functionality.

## 6. Explicit frontend/backend handoff contract

| Required route / dependency | Owner | Frontend expectation |
|---|---|---|
| `GET /q/m1-live` | Shafiq | HTTP 302 to current state route; same short URL after match status changes |
| `/web/matches/match-m1/live` and `/web/costream/cs-session-101` | Shafiq serves, Israr supplies assets | Page and assets load at port 8080 |
| `GET /audit/v1/qr/match-m1?inspect=true` | Shafiq | Signed QR JSON, inspect does not increment scan count |
| `POST /api/v1/chat` | Shafiq | Anonymous bearer guest is denied with actual `403 GUEST_WRITE_FORBIDDEN` |
| `GET /api/v1/matches/match-m1/stream` or `ws://.../ws/matches/match-m1` | Shafiq | Realtime score event matches frontend parsing within 500 ms |
| `POST /audit/v1/guest/cart-merge` | Shafiq | Authenticated cart merging is atomic and replay-idempotent |
| `POST /audit/v1/costream/session` | Shafiq | Real session, participant/host state, common chat room |
| Media HLS 8888 / WHIP-WHEP 8889 / RTMP 1935 | Shafiq | Playback URLs genuinely reachable from actual browser/phone |
| Selenium Grid 4444 / >=3 nodes | Shafiq infrastructure | Israr tests run on live browsers |
| Appium 4723 | Israr local testing / shared machine | UiAutomator2 connects to real Android device |

Request the **actual JSON event shape and network-reachable URL** from Shafiq once backend exists. Do not invent data formats or silently weaken frontend assertions.

## 7. Acceptance, evidence, handoff

Before saying COMPLETE, report:

- Exact **commit SHA and branch**, whether merged/pushed to `main` by Shafiq (or not).
- Files created/changed; URL of live browser page and release APK path.
- Commands actually executed plus real PASS/FAIL/BLOCKED; do not equate selectors present with UI workflow passing.
- Deep-link foreground time + correct screen; screenshot if possible.
- Browser test outcomes in both Chrome and Firefox; actual node count.
- Real server-side 403 response and 500ms score test result, if available.
- Any backend dependency, port conflict, or unimplemented interface preventing completion.
- Generated reports only when real runs produce them; do not invent or copy sample coverage/QA numbers.

**Single-line status format:** `SHA | files changed | deep links PASS/FAIL/BLOCKED | guest web PASS/FAIL/BLOCKED | Selenium | Appium | APK | backend blockers`.

**End state:** A safe, additive Day 2 mobile/web delivery that preserves yesterday's work, can be served from the existing port-8080 backend, and can be independently verified by the competition's external tests.
