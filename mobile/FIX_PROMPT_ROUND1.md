# FIX PROMPT — Trifecta mobile, audit round 1 (paste everything below the line into Antigravity)

---

Rework pass on the existing Trifecta app in mobile/. An audit found the defects below. FRONTEND_BRIEF.md, DESIGN_RULES.md and API_MODELS.md remain binding, and the Part 1 contract is the law for every data shape — where a section number is cited, match the document exactly. Fix in the order given: Part A protects judged points, Part B is contract/backend consistency, Part C is the UX rework, Part D is component discipline, Part E is packaging. Do not redesign anything that already passes, and do not change navigation structure except where stated.

## PART A — Points-critical functional fixes

A1. Judge Task A must be walkable from Standings. Today a standings row tap opens Club Profile and no match can be reached. Change: tapping a standings row opens a team-matches view (reuse the Fixtures list filtered to that team, with the same match cards) and tapping a match there opens Match Detail. Path must be Standings → row → match → Match Detail.
A2. Roster management is missing "Add player". Add a fourth tab "Add" with a form (full name, position/role picker) that registers a new player into the manager's own squad through a new RosterService.addPlayer method (interface + mock, player appears in the club roster afterwards), with the standard success snackbar. Add does not need offline queueing (the contract's offline types are transfers only).
A3. Receipt download is fake — it only shows a snackbar. Make it real: decode CheckoutResult.receipt.pdfBase64 and save the PDF to the device's documents/downloads folder, then confirm via AppSnackbar with the file name. In the mock, generate genuine PDF bytes from the receipt payload so the button really produces a file. Delete the hand-rolled snackbar in receipt_view.dart.
A4. Settings "Clear cached data" currently deletes the whole cache directory INCLUDING the offline sync queue — pending actions are destroyed. Partition the storage: clearing cached reads must never touch the offline queue file. Move the queue to its own store if needed.
A5. Roster offline base_version is wrong: roster_service_mock.dart uses the GLOBAL audit-entry count. Per contract §5.14 it must be the number of audit entries FOR THAT PLAYER. Fix, and make getPlayerHistory return only that player's entries.
A6. Sync results are mislabelled: a `duplicate` result currently renders in the rejected branch with error colours, and applied chips print the raw code "Applied (rebased_append)". Fix the sync view: duplicate → neutral styling with the AppStrings wording "Already sent earlier"; applied → the plain §5.14 wordings from AppStrings ("Sent" / "Sent — the match had moved on, so it was added on top"); rejected → the plain-language reason for its error code. Raw resolution/status codes never appear on screen.
A7. Remove the raw HTTP code from the cart sheet: the text "Decline Gateway (402)" must go (the payment selector is rebuilt properly in C23).

## PART B — Contract / backend consistency

B1. ALL model JSON keys must be snake_case exactly as in the contract's §5 examples (match_id, sport_id, team_id, fair_play, league_id, resolved_by, event_id, variant_id, …). ScoreProjection, TeamScore, MatchEvent, StandingRow, fixtures/club/store models currently read camelCase and will break against the real backend. Also delete the MatchEvent `timestamp` field — the backend never sends one.
B2. StandingsResult (§5.10): the backend's rows key is "table", not "rows" — fix the parser, and add the missing `h2h` map (teamId → teamId → {played, points, scored, conceded}).
B3. CheckoutResult (§5.12) must carry the full shape: items[] (variant_id, quantity, unit_price_minor), payment{authorization_id, capture_id, state}, receipt{payload, signature, pdf_base64}. Add StoreService.getInventory(variantId) and ProductVariant.reserved.
B4. TransferResult (§5.11) is missing `registration` — add it. Roster history must return the spec object {player_id, as_of, league_id, current_squad_id, parent_squad_id, history[]} instead of a bare List<AuditEntry>.
B5. Offline queue (§5.14): build the real envelope {device_id, actions:[…]} for sync. QueuedAction.toJson() must emit ONLY action_id, type, queued_at, base_version, payload — remove the UI-state keys (status, resolution, error_code, user_message) from the wire shape (keep them in a separate local model if the UI needs them). queued_at must be UTC in `…Z` form, not a local +05:00 offset. ActionResult gains processed_order, server_version, signature. The mock sync must stop fabricating results (no literal actionId 'temp', no i%2 rebased decisions, duplicates must be producible): simulate honestly from the queue contents.
B6. The SyncService INTERFACE must expose the reactive state (isOnline, pending actions list) — delete both `as SyncServiceMock` casts (core/widgets/sync_indicator.dart, features/sync_status/controller). Register ApiService in InitialBinding and make it parse the {error:{code, message, details}} body, or delete the ApiService layer entirely; no dead layers.
B7. Checkout must mint ONE order_id per checkout attempt (store it on the controller when the cart is opened for checkout) and reuse it on retry — today every checkout() call mints a fresh id, defeating idempotency.
B8. Add role guards on the routes themselves: AppRoutes.rosterManage opens only for Club Manager / Super-Admin, AppRoutes.scoringEntry only for League Organizer / Super-Admin; any other role navigating there is redirected to their home with the AppStrings permission message. Hiding buttons is not enough.
B9. Match detail must update live: add a refresh timer in MatchDetailController (poll the MatchService every 15 seconds while the screen is open and the match is in progress; cancel on close). Pull-to-refresh stays as the manual fallback.
B10. Role-aware landing after login (contract §8.2): Super-Admin and League Organizer land on Fixtures; Club Manager and Player land on Club Profile (their own club, read-only for Player); Viewer lands on Fixtures. Implement via the main shell's initial tab per role.
B11. Add the model data the UX fixes need — in the service models/mocks, NOT invented in views: (a) squad list with NAMES for the manager's own tenant (ClubService), (b) event types per sport for the scoring picker (from the sport config), (c) a human-readable `description` stored on each QueuedAction at queue time ("Goal for Alpha FC", "Transfer Ahmed Raza to Beta Titans"), (d) tenant NAME on the session/club data (never render tenant ids).

## PART C — UX rework (the screens must stop looking generated)

GLOBAL
C1. Remove every raw identifier and code from visible UI: no tenant ids, squad ids, team ids, action ids, base versions, sequence numbers, HTTP codes, enum names or underscore strings (IN_PROGRESS, rebased_append, CLUBMANAGER) anywhere a user can see them. Always render the human name and plain-language text from AppStrings. Role renders as "Club Manager".
C2. Pills (radiusPill) are for STATUS CHIPS ONLY. Nothing else may be pill-shaped: not account selectors, not filters, not tabs, not role labels.
C3. Stop card-per-row. Staff lists, rosters, cart items, timeline events and sync queue entries become rows inside ONE AppCard per section (rows separated by the border-colour divider), using the AppListTile recipe. AppCard is for genuine standalone blocks only.
C4. Every tappable element is at least 48dp tall, including tabs, filter chips and SectionHeader actions (remove the shrink-wrapped text buttons).
C5. Build ONE shared segmented-control widget in core/widgets and use it for the Fixtures filters, Roster action tabs and Scoring tabs — one implementation, 48dp height, one selected style.
C6. Snackbars: success uses the success background token + check_circle_outlined icon; errors use errorBg + error icon. Everything goes through AppSnackbar.

LOGIN (rebuild the lower half of login_view.dart; delete account_chip.dart)
C7. Remove the circle-badge hero. Header: app name in headlineLg, one-line subtitle "Sign in to continue", left-aligned, no card around the form — fields sit directly on the background.
C8. Replace the Wrap of role pills with a "Demo accounts" section UNDER the form: one AppCard with five list rows (outlined person icon, role name as title, account email as subtitle, chevron). Tapping a row signs in IMMEDIATELY (one tap, no second Sign In press). Section title is exactly "Demo accounts".
C9. Login error appears directly under the password field, not at the bottom of the screen. Add AutofillHints.email / AutofillHints.password, a show/hide password toggle (visibility_outlined / visibility_off_outlined), and hint text in both fields.

FIXTURES (match_card.dart, fixtures_view.dart)
C10. Content budget per match card — exactly 4 elements: team names; score or "vs" (titleLg, not headlineLg); ONE status element (LIVE pill / FT pill / kickoff); ONE meta line in caption: "Sat 18 Oct • 3:00 PM • Venue name" (date + time + venue combined; sport as the first word of the meta line only when the list mixes sports). Delete the separate sport/venue header row.
C11. Group the list by date with a plain SectionHeader per day ("Today", "Tomorrow", "Sat 18 Oct"). Filters use the shared segmented control (C5).

MATCH DETAIL (match_detail_view.dart, event_timeline_tile.dart, pinned_merch_card.dart)
C12. Delete the "Fair Play: x/10" lines from the score block. The block is only: status chip, two team names, the score.
C13. Status text from AppStrings in plain words ("Live", "Full time", "Upcoming") — never the raw status string.
C14. Move PinnedMerchCard BELOW the event timeline. Shrink it to a single row (icon tile, name, price, one text-button "View") — no full-width button.
C15. Timeline tiles become rows in one card (C3). Row budget: icon, a plain-words title ("Goal — Ahmed Raza", "Yellow card — Bilal Khan", "Score correction"), ONE meta line: the team NAME (never its id). No sequence numbers. A compensated event shows only the correction row (with the "Corrected" chip); the original is not rendered as a separate struck-through card.
C16. Remove the "Refresh" text action from the timeline SectionHeader; pull-to-refresh stays.

STANDINGS (standings_view.dart)
C17. Rebuild the table for a 360dp phone: visible without horizontal scrolling are exactly #, Team, P, W, D, L, Pts (bold). Goal difference / NRR moves to a caption under the team name ("GD +6" / "NRR 0.532"). Qualification status becomes short chip text (Clinched / Out / Alive) as the last visible column if it fits at 360dp, otherwise the full status word as caption text under the team name beside GD. Team names in textPrimary (not primary blue); keep the chevron. The league banner becomes plain header text, no card.

CLUB PROFILE (club_profile_view.dart)
C18. Delete the "Tenant: <id>" line; if a tenant is shown, show its NAME.
C19. Venue: venue name as the row title; coordinates as a labelled row "Coordinates: 33.7294, 73.0931" in bodySm — required data, presented properly, not a caption dump.
C20. Staff and roster become rows in one card each (C3). Staff role and player position get the SAME treatment: bodySm textSecondary under the name. Delete the trailing role caption on player rows — position only.

STORE (store_view.dart, product_card.dart, cart_sheet.dart, receipt_view.dart, variant_picker_sheet.dart)
C21. Product card budget: icon tile, name, price, ONE action. Remove the description text and the full-width Add button — the whole card tap opens the variant picker; add a small trailing "Add" text-button with the add icon that does the same. A button must never promise an action it doesn't perform.
C22. Delete the header's "N items" action and the duplicate "Store" SectionHeader (the app bar already titles the tab). The floating cart bar shows: bag icon, "View cart", and the cart total price on the right.
C23. Payment selector: replace the raw DropdownButton with three selectable radio-style rows with outlined icons, labelled in plain outcomes: "Mock card — payment succeeds", "Mock card — payment is declined", "Mock card — payment fails after approval". No token strings, no HTTP codes, all three outcomes present.
C24. Discount field hint becomes "Enter discount code" (never print the code itself). The applied state reads "WELCOME10 applied — 10% off".
C25. Receipt: add a success header (check_circle_outlined in a successBg circle + "Payment successful" in titleLg) above the details card. Remove the "Auth ID" row. Remove the bottom Close SecondaryButton (keep the X). The Download button (now real, per A3) stays primary.
C26. Cart sheet: wrap the whole sheet content in a scroll view so it cannot overflow at 640dp height. Variant rows: title "M — White", subtitle the stock ("Only 1 left" / "5 available"), trailing add_circle_outlined icon. No "Size:" / "Color:" prefixes.

ROSTER (roster_manage_view.dart)
C27. Player picker: remove the card around the dropdown; use the standard input recipe (label above, bordered field). Dropdown items show "Ahmed Raza" only; jersey/position move into a small summary line under the field once selected.
C28. Target squad becomes a REAL selector listing squad NAMES from the manager's own tenant (data from B11a), styled like the player field. The fixed grey text box is deleted.
C29. When the Loan tab is active, show a "Loan return date" date-picker field under the target squad; hide it for Transfer/Release. Transfer and Loan get the same AppDialog.confirm pattern as Release, summarising in plain words: "Transfer Ahmed Raza from Alpha FC to Beta Titans?"
C30. History entries become rows in one card: title "Ahmed Raza", subtitle "Alpha FC → Beta Titans • 12 Oct 2026", the action as plain text in the subtitle ("Transfer", "Loan", "Release") — no uppercase pill, no ids, no "Reason:" prefix (reason as the subtitle's second line only if present). Reason field hint: "Reason (shown in the player's history)".

SCORING ENTRY (scoring_entry_view.dart)
C31. Use the shared segmented control (C5). Replace the free-text-first flow with tap-first: team choice (keep the existing boxes), then an EVENT TYPE selector — a 2-column grid of tappable tiles with outlined icons for the sport's event types (data from B11b) — then an OPTIONAL player field labelled "Player (optional)". The free-text field is the last resort, not the main input.
C32. Compensation list labels read "Goal — Ahmed Raza" (plain words), never "Seq #n". Reason hint: "Reason for the correction".

SYNC STATUS (sync_status_view.dart, sync_indicator.dart)
C33. Delete the offline simulator Switch and both subtitles ("Connected to Trifecta servers", "Simulating offline / airplane mode"). The status card reflects REAL connectivity only: status icon, "Online" / "You're offline", and one plain line — online: "Everything is up to date" or "N actions waiting to sync"; offline: "Actions you take now will be saved and sent when you're back online."
C34. Queue cards become rows in one card (C3), using the stored description (B11c) as the title ("Goal for Alpha FC", "Transfer Ahmed Raza to Beta Titans"), queued time as caption, and a status chip with PLAIN text only: "Pending", "Sent", "Sent — added on top", "Already sent", or "Not sent" with the plain-language reason from AppStrings beneath it. No action ids, no base versions, no resolution codes.
C35. The app-bar sync badge loses the nested pill: pending count renders as plain text after the label ("Offline • 2 waiting").

PROFILE & SETTINGS (profile_view.dart, settings_view.dart)
C36. Profile menu becomes ONE AppCard of list rows (icon, label, chevron): Manage Roster (managers only), Sync Status, Settings, then Sign Out as a final row in error-coloured text. Delete the four stacked full-width buttons. Role shown as plain text under the email ("Club Manager"), not a pill. Tenant row shows the tenant NAME.
C37. Settings: delete the sentence "Port 8080 is fixed per competition specification." — replace with the caption "Port 8080". Move the Device ID card to the bottom and demote it to a plain caption row ("Device ID: dev-1") — no card.

## PART D — Component discipline & missing states

D1. Create the two missing shared widgets in core/widgets: AppStatusChip (the one chip recipe from DESIGN_RULES §2) and AppTextField, and add a full inputDecorationTheme to core/theme/app_theme.dart implementing the one input recipe. Replace every hand-rolled chip (fixtures/match_card.dart, match_detail_view.dart, sync_status_view.dart, event_timeline_tile.dart) and every inline InputDecoration (login_view.dart, roster_manage_view.dart, scoring_entry_view.dart, settings_view.dart, cart_sheet.dart) with them.
D2. Scoring entry has TWO PrimaryButtons (append + compensation) — the compensation action becomes a SecondaryButton. One primary per screen, everywhere.
D3. Missing screen states: profile_view (add EmptyView + ErrorView), settings_view (add ErrorView), sync_status_view (add LoadingOverlay + ErrorView). The login screen must show the sync indicator like every other screen (remove showSyncIndicator: false).
D4. One icon family only: replace every *_outline_rounded icon (person/people/info/error _outline_rounded) with its *_outlined equivalent. All icons outlined, one variant family.
D5. Move ALL remaining hardcoded UI strings into AppStrings (cart_sheet.dart, receipt_view.dart, variant_picker_sheet.dart and anywhere else a literal is rendered). No user-visible literal outside core/strings.

## PART E — Packaging

E1. Change applicationId from com.example.trifecta to com.trifecta.app and the app label from "trifecta" to "Trifecta".
E2. Build the release APK and place it at mobile/release/app-release.apk (debug signing is acceptable for the competition build).

## PART F — Release build cannot reach the network (verified in the Android manifest)

F1. android/app/src/main/AndroidManifest.xml declares NO INTERNET permission (it exists only in the debug/profile manifests) — a release APK built from this project cannot make any network call at all. Add `<uses-permission android:name="android.permission.INTERNET"/>` to the MAIN manifest.
F2. The backend is plain http:// on port 8080 (emulator 10.0.2.2 / laptop LAN IP), and Android blocks cleartext HTTP by default — add `android:usesCleartextTraffic="true"` to the <application> element (or an equivalent network security config permitting cleartext for the app). Without F1+F2 the judged release APK can never reach the backend or sync, however well it runs in debug.

## PART G — ADDENDUM: second-pass findings (send after the main prompt if already pasted)

G1. The changeable server address does not survive a restart: StorageServiceImpl is an in-memory Map, so the Settings host and device_id silently revert to 10.0.2.2 / dev-1 after any force-close (§8.1, §8.4 step 4 — a phone configured with the laptop's LAN IP loses it exactly when the desk check reopens the app). Persist settings (host, device_id) to disk (same file store as the cache), loaded at startup.
G2. Nothing detects REAL connectivity: SyncServiceMock._isOnline flips only via the simulator switch (deleted in C33) — with no connectivity source, the app reports "Online" during the judge's real airplane-mode step and the required "Offline" indicator never appears. Add the connectivity_plus package (or platform connectivity) and drive isOnline + auto-sync from REAL device connectivity changes.
G3. Match detail fabricates data: match_service_mock's store holds only m-alpha-1 and getScoreProjection() invents a football 0–0 "Alpha FC vs Beta Titans" projection for ANY other id, then caches the invention; fixtures getMatchSummary() returns the first match for an unknown id. The mocks must carry a real projection for EVERY fixture in the fixtures list (basketball and Alpha United matches included, each with its own teams/sport/timeline), and unknown ids return a proper not-found error — never fabricated content.
G4. Club profile and standings ignore the requested id: getClubProfile() returns Alpha FC for every club (cached under the requested key); getStandings() returns league-alpha-1's table for every league. Give each club (club-alpha-1, club-alpha-2, club-beta-1) its own profile data and each league its own table, cached under its own key.
G5. Checkout never checks stock, and the mock stock contradicts the contract baseline (§5.5 reset seed: var-jersey-001-M stock 1, var-jersey-001-L stock 5). Set the seed stock to exactly M=1 / L=5 and enforce it: quantity above available stock fails with the OUT_OF_STOCK wording from AppStrings; a successful checkout decrements stock (the variant picker then shows "Only 1 left" / sold out truthfully).
G6. Checkout "succeeds" while offline — store_controller never checks connectivity. Offline checkout must NOT issue a receipt: show the plain-language offline message ("You're offline — checkout will be available when you reconnect") and keep the cart intact.
G7. No session restore, and the login form is PRE-FILLED with working credentials (auth_controller onInit sets organizer@nascon.test / Nascon@26) — scaffolding shipped in the judged build. Remove the pre-fill entirely. Add session restore: at startup, if a token + user exist in secure storage, go straight to the role's home (§8.4 step 4 reopens the app; re-login must not be forced).
G8. Transfer/loan dates are hardcoded literals ('2026-10-17', '2026-12-31') sent on every submission. Wire the real dates: an "Effective date" date-picker (default today) for all three actions plus the loan return date from C29 — the chosen dates go into the payload (§5.11 treats both as real per-request fields).
G9. No double-tap protection: appendScoreEvent, submitRosterAction and confirmAndCheckout set isSubmitting/isCheckingOut but never CHECK them on entry. Guard each on entry (`if (isSubmitting.value) return;`) so a double-tap cannot append a goal twice to the append-only log, queue a transfer twice, or run checkout twice.
G10. The pinned product's shop action pushes a second copy of the app shell (openStoreMerchandise calls Get.toNamed(AppRoutes.main)). Replace with switching the main shell's tab to Store (via MainNavController) — never stack a duplicate shell; Back behaviour must stay sane.
G11. The score payload fabricates the match minute from the wall clock: scoring_entry_controller builds 'player': '$player (${DateTime.now().minute}\')'. Remove the invented minute entirely — the payload carries team_id and event_type (and the player name only, if provided); timeline display derives its text from real event data.
G12. Offline queue cold-start race: SyncServiceMock's constructor fires _loadQueueFromDisk() un-awaited — after every cold start the queue (and the pending count in the app bar) reads empty until the read lands, and an action queued inside that window can be clobbered when assignAll() completes. Make queue loading part of async initialisation (bindings await readiness before the UI reads it) and never overwrite in-memory actions with a stale disk snapshot.
G13. The mock accepts scoring on matches that aren't in progress — the real backend rejects that with MATCH_NOT_IN_PROGRESS (§5.9). postEvent must check the projection status and refuse upcoming/completed matches with the AppStrings wording, so the demo flow matches the real API's behaviour.
G14. The mock world contradicts itself across screens: club-alpha-1 is "Alpha FC" in fixtures but "Alpha Kings" in m-alpha-4; club-beta-1 appears as both "Beta Titans" and "Beta Wolves", sits inside tenant-alpha's league, and a phantom "club-beta-2" exists nowhere else. One canonical club→name/sport/league/tenant mapping across ALL mocks, matching the contract baseline (§5.5): beta clubs belong only to tenant-beta and never appear in alpha leagues or standings.
G15. Standings can only ever show league-alpha-1 — the controller hardcodes it and there is no league selector, but Judge Task A starts with "find A league's standings" and fixtures span two leagues. Add a league selector (plain dropdown/segmented control of league NAMES) above the table; switching reloads that league's table (per G4).
G16. Two competing base-URL truths: app_config.dart defaults to http://10.0.2.2:8080/api (the /api suffix matches no §5.1 route) while the Settings host lives in a store the network layer never reads. ONE source of truth: the persisted Settings host (G1), read by AppConfig/ApiService; the default is http://10.0.2.2:8080 with NO path suffix.
G17. Applying a bad or empty discount code silently removes an already-applied good one. applyDiscountCode: an empty field is a no-op (no error); an invalid code shows the invalid-code message but KEEPS any previously applied discount untouched.
G18. Leftovers: pubspec description still reads "A new Flutter project." — set a real one ("Trifecta — multi-sport league & club operations"); ProfileController injects a ClubService it never calls — remove the unused injection. (App label + applicationId are covered in E1.)
