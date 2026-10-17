# DESIGN RULES — Trifecta mobile (anti-slop law)

These rules sit ON TOP of the structure prompt and the token files (`app_colors.dart`, `app_text.dart`, `app_sizes.dart`). The tokens are the only visual vocabulary allowed. Where a habit or default conflicts with this file, **this file wins**.

## 1. BANNED — never, on any screen

- **NEVER** use any gradient — no LinearGradient / RadialGradient / SweepGradient, no gradient buttons, headers, cards, backgrounds or text. Every surface is one flat token colour.
- **NEVER** use purple, violet, indigo or magenta anywhere. The only brand colour is the palette primary (#2563EB light / #60A5FA dark). Never invent a second accent colour.
- **NEVER** add drop shadows — no BoxShadow, no elevation above 0, no blurred or floating cards, no coloured or "neon glow" shadows. Depth does not exist in this app; separation is done with borders and tonal surfaces.
- **NEVER** use glassmorphism / frosted glass — no BackdropFilter blur, no semi-transparent panels over photos or backgrounds.
- **NEVER** use emoji as icons or decoration (no 🏆 ⚽ 🔥 in UI, buttons, chips, empty states or headers). Icons come from the icon set only.
- **NEVER** mix icon styles — no filled icons next to outlined ones, no custom-drawn icons, no icon-font or SVG icon packs.
- **NEVER** use rainbow / multi-colour coding — no different colour per category, team, status or tab. Status colours come only from the palette's success / warning / error tokens, and always paired with a text label.
- **NEVER** invent border radii. Only token radii (8 / 12 / 16 / 20, sheet 28). Pill radius (999) is allowed ONLY for status chips. Cards = radiusLg 16, buttons/inputs = radiusMd 12, never rounder.
- **NEVER** centre-align everything. Body text, list rows, form labels and section headers are left-aligned. Centre alignment only for the score block and empty-state messages.
- **NEVER** put floating cards on coloured / gradient / image backgrounds. Content sits on the `background` token colour; cards sit on `surface` with a border.
- **NEVER** use hero illustrations, stock photos, decorative blobs / waves / circles, or image headers. The only images are real data (club logos, product photos). A missing image = a flat `surfaceVariant` block with one outlined icon.
- **NEVER** use lorem ipsum or placeholder gibberish. All demo content is realistic sports data from the brief's baseline world (tenant-alpha, club-alpha-1, league-alpha-1, the jersey product).
- **NEVER** build landing-page layouts — no oversized hero titles, huge empty whitespace, or marketing sections. This is a dense utility app: lists, tables, rows, forms.
- **NEVER** add animation beyond the motion tokens (120 / 200 / 320 ms, standard easing). No bounce/spring, no shimmer skeletons, no staggered fade-in cascades, no animated backgrounds.
- **NEVER** invent a new component style per screen. If a button, card, row, chip, input or header looks different from the same component on another screen, it is a defect.
- **NEVER** show raw technical output: no error codes (OUT_OF_STOCK, "Error 500"), no stack traces, no JSON, no URLs as visible UI text.

## 2. REQUIRED — the flat, consistent system

**Colour & surfaces**
- Every colour from `context.colors.*`. Backgrounds = `background`; cards/panels = `surface`; grouped/secondary areas = `surfaceVariant`. Nothing else.
- Separation is achieved ONLY by a 1px border in the `border` token colour, or a tonal step (background → surface → surfaceVariant). The one card recipe: AppCard = `surface` fill + 1px border + radiusLg.
- Tenant branding enters through exactly two slots: `palette.primary` and the tenant/club logo. Nothing else changes per tenant.

**Icons — OUTLINED only**
- Material **outlined** icons only, always the `_outlined` variant (`Icons.home_outlined`, `Icons.emoji_events_outlined`, `Icons.storefront_outlined`, `Icons.groups_outlined`, `Icons.person_outlined`, `Icons.sync_outlined`, `Icons.shopping_bag_outlined`). Sizes only 20 / 24 / 28 (tokens). Colour `textSecondary` by default, `primary` for the active/selected state.
- Every icon button has a tooltip/semantic label. Bottom-navigation items always show their text label.

**Components — one style each, from the widget kit only**
- **Buttons:** PrimaryButton (flat primary fill, white text, 52 high, radiusMd) — max ONE per screen, and it is the screen's main job (Buy/Checkout, Save). SecondaryButton (flat `surface`, 1px border, primary text, 48 high) for other actions. Text buttons only for minor actions (Cancel, View all). No other button shapes.
- **List rows:** one recipe everywhere — min height 56, 16 horizontal padding, leading outlined icon or thumbnail, title in titleMd/bodyLg, subtitle in bodySm `textSecondary`, trailing chevron OR a status chip — never mixed patterns within one list.
- **Status chips:** one recipe — pill shape, tonal background from status bg tokens (`primaryContainer`, `successBg`, `warningBg`, `errorBg`), labelMd text, optional leading outlined icon. Status is always icon-and/or-text, never a bare coloured dot.
- **Inputs:** one recipe from the theme — 52 high, `surface` fill, 1px border (`border`, `primary` when focused, `error` when invalid), radiusMd, label + plain-language error text under the field.
- **AppBar/headers:** AppScaffold's AppBar everywhere — flat, no shadow, headlineMd title, outlined back arrow on pushed screens. Section headers use SectionHeader. No custom headers.
- **Match rows:** one layout everywhere a match appears — home team left, score centre in headlineLg, away team right, status chip beneath. **The score is the largest text on any screen that shows it.**

**Hierarchy**
- Hierarchy comes ONLY from type size/weight and spacing tokens: screen title headlineMd → section titleMd → body bodyMd → meta caption. The most important element (live score, total price, Buy button) gets the biggest style or the PrimaryButton; everything else stays quiet.

**Screen states — every screen, no exceptions**
- **Loading:** LoadingOverlay or flat `surfaceVariant` placeholder rows — never a blank body or a silent frozen screen.
- **Empty:** EmptyView — one outlined icon, one plain-language sentence ("No matches yet"), one optional action.
- **Error:** ErrorView — plain-language message + Retry (SecondaryButton). Never a raw code.
- **Content:** plus feedback for every action — AppSnackbar on success ("Player transferred"), AppSnackbar with a plain-language reason on failure.

**Feedback, sync, roles**
- Sync indicator ALWAYS visible (app-bar area): outlined icon + "Online" / "Offline" / "Syncing" text + pending count when actions are queued. Queued actions show a "Pending" chip.
- AppDialog confirmation before risky actions: releasing a player, submitting a compensation event, confirming a payment.
- Role gating by HIDING, not disabling: Scoring entry exists only for League Organizer; Roster actions only for Club Manager; Player/Viewer get no edit controls at all.

**Accessibility**
- Every tappable element ≥ 48dp. Meaning never by colour alone (W/D/L text in tables, labelled chips, text errors — colour only reinforces).
- Text/background pairs only from the palette. Content text bodyMd (14) or larger; caption (12) only for non-essential meta.
- Layouts survive 360×640dp and rotation: scrollable lists, no fixed-height content blocks, no horizontal overflow; the standings table scrolls horizontally rather than shrinking text.

## 3. Why — judged areas this wins (contract §8.6)

| Rule group | Judging area |
|---|---|
| Bottom nav, back everywhere, ≤2 taps to main sections | 1. Navigation & ease of use |
| Token-only colours/type/spacing; one recipe per component; no gradients/shadows/emoji/rainbow | 2. Visual consistency & hierarchy ("same colors, fonts, spacing, button styles on every screen") |
| Score = biggest text; one PrimaryButton per screen (Buy stands out) | 2. Visual consistency & hierarchy |
| Tenant colour via `primary` + logo slot only | 2. ("the tenant's logo and colors are applied") |
| Four states on every screen; snackbar feedback; plain-language errors; always-visible sync indicator; confirmations | 3. Feedback & error handling |
| 48dp targets, labelled icons, meaning never by colour alone, palette contrast | 4. Readability & accessibility |
| Role-based hiding; helpful empty states; 360×640 + rotation-safe | 5. Right screen for the right role |

## 4. Per-screen consistency checklist (eyeball each screen against this)

1. ☐ Background is the flat `background` token — no gradient, image, shadow or coloured wash.
2. ☐ Every colour is a palette token; the only saturated colour is `primary` (plus status tones inside chips).
3. ☐ All icons outlined, one size per context (20/24/28), every icon button labelled.
4. ☐ Zero emoji anywhere.
5. ☐ Exactly one PrimaryButton — the screen's main action; everything else Secondary or text.
6. ☐ Cards / rows / chips identical to those on other screens.
7. ☐ Spacing on the token scale; text left-aligned except score blocks and empty states.
8. ☐ Text styles only from the type scale; the most important element is visibly the biggest.
9. ☐ All four states exist: loading, empty, error, content.
10. ☐ Sync indicator visible; queued actions show "Pending".
11. ☐ Actions this role can't perform are absent, not greyed out; risky actions confirm first.
12. ☐ No overflow at 360×640 or after rotation; tap targets ≥48dp; no status by colour alone.
