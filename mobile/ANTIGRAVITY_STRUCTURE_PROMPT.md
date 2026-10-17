# Antigravity prompt — PeopleGone-style Flutter structure + design rules

Set up this Flutter app to match the structure and design system below EXACTLY. This is the architecture of a production app (PeopleGone); copy its conventions, not its features.

WHERE: Create/restructure the app inside the `mobile/` folder of this repo. If no Flutter app exists there yet, create it there.

## Folder structure (lib/)

- `lib/main.dart` — entry point only: runApp + InitialBinding.
- `lib/config/app_config.dart` — non-secret client config (API base URL etc.), read from dart-define.
- `lib/core/bindings/initial_binding.dart` — registers global services.
- `lib/core/routes/app_routes.dart` + `app_pages.dart` — route name constants + GetPage list. ALL navigation is defined here.
- `lib/core/constants/app_colors.dart`, `app_text.dart`, `app_sizes.dart` — the design tokens below. These are the ONLY files allowed to contain raw `Color(0x...)` values, font sizes, or layout numbers.
- `lib/core/theme/app_theme.dart` + `theme_ext.dart` — ThemeData for light + dark; context extensions `context.colors`, `context.text`, `context.sizes`.
- `lib/core/strings/app_strings.dart` — EVERY user-visible string as a static const here. No string literals in views.
- `lib/core/utils/` — formatters + a `Result<T>` success/failure type.
- `lib/core/widgets/` — the shared widget kit, built FIRST: AppScaffold, PrimaryButton, SecondaryButton, AppCard, AppSheet (bottom-sheet wrapper), AppDialog, AppSnackbar, EmptyView, ErrorView, LoadingOverlay, SectionHeader. Features only use these.
- `lib/features/<feature_name>/` — one folder per screen/flow, each containing: `binding/` (GetX binding — the ONLY place its controllers are registered), `controller/`, `model/` (plain data classes + route args), `view/` (the screen), `widgets/` (feature-only widgets).
- `lib/services/<area>/` — service INTERFACES live here (e.g. `services/api/`, `services/storage/`, `services/auth/`). Only implementation files may import http/dio, storage, or platform packages. Features never call packages directly — only services.

## Architecture rules

- GetX for state + routing. Controllers are registered ONLY in bindings — NEVER `Get.put`/`Get.find` inside `build()`.
- Views are dumb: layout + Obx only. No logic, no try/catch in views.
- Services return `Result<T>`. Controllers expose loading/error state; views render ErrorView or AppSnackbar from the kit — no ad-hoc `Get.snackbar`/`Get.dialog` calls in features.
- Every hand-written file under ~400 lines. One screen per view file.

## Design tokens (copy these values exactly)

**Colours** — an `AppPalette` class as a ThemeExtension, light + dark variants, theme mode = system (follow device):
- Light: primary #2563EB, onPrimary #FFFFFF, primaryContainer #DBEAFE, secondary #0F766E, background #F8F9FA, surface #FFFFFF, surfaceVariant #F1F3F5, textPrimary #111827, textSecondary #4B5563, textTertiary #9CA3AF, border #E5E7EB, success #10B981 (bg #D1FAE5), warning #F59E0B (bg #FEF3C7), error #EF4444 (bg #FEE2E2), scrim #8C0A0C10.
- Dark: primary #60A5FA, onPrimary #0B132B, primaryContainer #1E3A8A, secondary #2DD4BF, background #0B0D11, surface #14171E, surfaceVariant #1D212A, textPrimary #F9FAFB, textSecondary #9CA3AF, textTertiary #6B7280, border #252932, success #10B981 (bg #064E3B), warning #FBBF24 (bg #451A03), error #F87171 (bg #450A0A), scrim #B3000000.

**Text** — bundled font **Inter** (add it as an asset font; do NOT use the google_fonts package). Styles are functions of the active palette (size / weight / line-height): display 32/700/1.20, headlineLg 24/700/1.25, headlineMd 20/600/1.30, titleLg 18/600/1.35, titleMd 16/600/1.40, bodyLg 16/400/1.50, bodyMd 14/400/1.50, bodySm 13/400/1.45, labelLg 14/600/1.40, labelMd 12/600/1.35, caption 12/400 in textSecondary, overline 11/600 letter-spacing 0.8 in textSecondary.

**Sizes** — fixed logical pixels only; NO screenutil, NO percentage sizing: spacing scale 2, 4, 8, 12, 16, 20, 24, 32, 40, 48; screen padding 16 (20 at ≥600dp width); card padding 16; radius 8 / 12 / 16 / 20, sheet 28, pill 999; primary button height 52, secondary 48, compact 40; input height 52; list row min 56; app bar 56; icons 20 / 24 / 28; minimum touch target 48 everywhere; content centred and capped at 640 max width; breakpoints 600 / 840; motion durations 120 / 200 / 320 ms.

## Hard rules

- No raw `Color(...)`, font sizes, or magic numbers anywhere outside the three constants files.
- No hardcoded strings in UI — `app_strings.dart` only.
- No logic in views; no `Get.put` in `build()`.

Do this in ONE pass: full folder structure, all three token files, theme + extensions, routes skeleton, the complete widget kit, and one sample feature (`home`) wired end-to-end as the pattern for the rest. Do not stop between steps.
