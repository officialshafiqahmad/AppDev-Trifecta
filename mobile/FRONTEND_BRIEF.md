# FRONTEND BRIEF — Trifecta (NaSCon '26 Part I): what to build

Build the **frontend only** for a multi-tenant, multi-sport league & club operations app (Android). The backend already has a fixed contract; this app will be wired to it later. Until then, **all data is mock data, served only through the service interfaces in API_MODELS.md** — never hardcode data in a view or controller.

Companion files (all three are binding):
- `DESIGN_RULES.md` — visual law. Its BANNED list is non-negotiable.
- `API_MODELS.md` — service interfaces, data models, offline queue format, error wording.

## Scoring context (why this brief is strict)

- Mobile is worth 14 of today's 50 points: **Offline persistence & sync = 4**, **UI/HCI judged live by a panel = 10**.
- Judging is a fixed 10-minute desk slot from 15:15 PKT: backend running, app installed. Judges run the SAME three tasks on every team (see Navigation).
- Deliverable: app source in `mobile/`, built APK at `mobile/release/app-release.apk`, installable on Android 10 (API 29)+.

## Screens (all 9 are required)

| # | Screen | Must show | Who |
|---|---|---|---|
| 1 | Login | Email + password; lands on a **role-aware home** after login | All roles |
| 2 | Fixtures | List of matches with status and time; tap a match to open it | All roles (view) |
| 3 | Match detail | Live score (updates without manual reload), event timeline, pinned product showcase | All roles view; scoring hangs off this for Organizer |
| 4 | Standings | Points table for a league, with qualification status per team (Clinched / Eliminated / Still possible) | All roles (view) |
| 5 | Club profile | Club info, roster, staff (coach, manager, physio), home venue | All roles (view) |
| 6 | Store | Catalogue, variant picker (size/colour), cart, checkout with mock payment, receipt view/download | Signed-in roles buy |
| 7 | Roster management | Add / transfer / loan / release a player | **Club Manager only** |
| 8 | Scoring entry | Append a score event AND a compensating (undo) event — appends only, never edits | **League Organizer only** |
| 9 | Sync status | Always-visible online / offline / syncing indicator + the pending-action queue | All roles |

Every screen ships in four states: **loading, empty, error, content** (see DESIGN_RULES.md).

## Roles & demo accounts (the app's login must accept these)

| Role | Email | Password | Sees / can do |
|---|---|---|---|
| Platform Super-Admin | admin@nascon.test | Nascon@26 | Everything, cross-tenant |
| League Organizer | organizer@nascon.test | Nascon@26 | Scoring entry; own league only (league-alpha-1) |
| Club Manager | manager@nascon.test | Nascon@26 | Roster management; own club only (club-alpha-1) |
| Player | player@nascon.test | Nascon@26 | Read-only views; own profile |
| General Viewer | viewer@nascon.test | Nascon@26 | Read-only inside tenant-alpha |

Role gating is by **hiding**: a role never sees buttons/screens it cannot use (no disabled dead controls). Tenant isolation is absolute — tenant-alpha users never see tenant-beta data.

## Navigation (judges test exactly this)

- Bottom navigation with four labelled destinations, reachable in ≤2 taps from anywhere: **Fixtures · Standings · Store · Profile**. Icons always shown WITH text labels.
- Every pushed screen has a working back. No dead ends, no orphan screens.
- The three judged tasks must be short tap paths:
  - **A:** Home → Standings → open a match → Match detail. (Also: Fixtures → tap match.)
  - **B:** Home → Store → product → pick variant → cart → checkout (with confirmation before payment completes) → receipt view/download.
  - **C:** Manager login → Roster management → do an action → success feedback. Repeated offline in the sync test below.

## Sync indicator & offline behaviour (4 points ride on this)

- A sync indicator is **always visible** on every screen (in the AppScaffold app-bar area): outlined icon + text — **Online / Offline / Syncing** — plus a pending count when actions are queued.
- The desk check does this exact sequence; the app must survive all of it:
  1. Online: judge opens Fixtures, Standings, a Club profile → all three must be **cached in a local database** (SQLite/Hive), not just memory.
  2. Airplane mode on: the same screens still open from cache; **"Offline"** indicator shows.
  3. Offline: judge performs one scoring action (Organizer) and one roster action (Manager) → each is saved to a **persistent local queue**, shown as **"Pending"**, in the exact action format of API_MODELS.md §3.
  4. App force-closed and reopened, still offline: **pending actions are still there**.
  5. Network on: auto-sync (or an obvious **Sync** button) → **per-action results** shown (applied / rejected + plain-language reason) → queue clears.
- Rejected actions are explained in **plain language** (wording table in API_MODELS.md §5), never raw error codes.

## Settings & storage

- **Server address must be changeable inside the app** (a Settings screen): default `10.0.2.2:8080` (emulator); a physical phone uses the laptop's LAN IP. Port is always 8080.
- Login tokens are stored in **secure storage** (Android Keystore-backed, e.g. flutter_secure_storage) — never plain shared preferences.

## Mock data world (use these exact ids/names — no lorem ipsum, no invented teams)

- Tenants: `tenant-alpha` ("Alpha Sports"), `tenant-beta` ("Beta Athletics")
- Leagues: `league-alpha-1`, `league-alpha-2`, `league-beta-1` · Clubs: `club-alpha-1`, `club-alpha-2`, `club-beta-1` · Players: `player-alpha-1`, `player-alpha-2`, `player-beta-1`
- Sports: football, basketball, cricket, esports
- Store: product `prod-jersey-001`, variants `var-jersey-001-M` / `var-jersey-001-L`, price **PKR 4500.00**, discount code `WELCOME10` (10% off)
- Empty-state example to mirror: "No matches yet"

## Build order

1. Scaffold + tokens + widget kit (per the structure prompt) → 2. Login + role homes + bottom nav → 3. Fixtures + Match detail → 4. Standings → 5. Club profile → 6. Store (catalogue → variant → cart → checkout → receipt) → 7. Roster management → 8. Scoring entry → 9. Sync status + Settings (server address) + offline queue plumbing against the mock SyncService.
