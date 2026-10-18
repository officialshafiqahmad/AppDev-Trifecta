# Final checkpoint evidence

Recorded for the 1:45–2:00 PM PKT push on 18 October 2026. Figures below are copied from runs already completed. No venue salt is stored in this file.

## Repository

- Prior `main`: `8a0e81fff29bd7c7b7e520ac3a3fd0cdd927fac9`
- Backend evidence commit: `07ccee166fcaf9d24bcf6636a505f9b46c648a65`
- Israr mobile merge: `4bbc83d71c9f9f299df80bcd663df8c7126723c5` (pull request #14, includes `597c414`)
- Day 1 ancestor checked: `25f241df1843c5aa4d0073f404987f547536b1fa` (17 October 2026, 15:03:55 PKT)

## SSE fanout

Source: `tests/reports/sse-fanout.json`, generated 2026-10-18T08:32:41Z.

- Endpoint: `GET /api/v1/matches/match-m1/stream`
- 25 connected clients, all received the update
- Score event HTTP status: 201
- Delivery latency: min 6 ms, p95 6 ms, max 7 ms
- Under the 500 ms bar: yes

## Hidden scenarios

Source: `tests/reports/hidden-scenarios.json`, generated 2026-10-18T08:32:56Z. All four passed.

- Co-stream host drop: 201, active host `player-alpha-2`, handoff true, 3 participants, chat room `chat-cs-hidden-1`
- QR after match end: short URL stayed `http://localhost:8080/q/m1-live`, target changed from `/web/matches/match-m1/live` to `/web/matches/match-m1/vod`, signature changed
- Ten simultaneous moderation posts: all HTTP 200, each `kicked_users` was `["user-spammer"]`
- Repeated cart merge: both HTTP 200, `total_items` stayed 1

## Load and coverage

Local k6 summary in `tests/reports/k6-summary.json`: 23,192 requests, failure rate 0, p95 480.98 ms. Thresholds in that run were not crossed.

GitHub Actions run [39112406247](https://github.com/officialshafiqahmad/AppDev-Trifecta/actions/runs/39112406247) on `8a0e81f` succeeded. Its k6 step reported 17,458 requests, 0% failed, p95 459.67 ms.

`COVERAGE_DAY2.json` measured line coverage: streaming 86.4, costream 93.8, qr_guest 87.2, moderation_dlq 92.9, observability 98.5.

## Not claimed

- A 25-client WebSocket probe was not run. The verified path is SSE.
- Appium on port 4723 was not running during these checks.
- Media ingest authentication, composite FFmpeg mixing, and VOD recording were not part of this checkpoint.
- Grading must supply `DAY1_SALT` and `DAY2_SALT` in the environment. The local API process used for the SSE and scenario runs was still on the published reference `DAY2_SALT`.
