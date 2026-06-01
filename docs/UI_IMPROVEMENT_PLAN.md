# UI Improvement Implementation Plan

**Based on:** [UI Trends That Are Actually Happening (Mohit Phogat, Apr 2026)](https://medium.com/@mohitphogat/ui-trends-that-are-actually-happening-and-worth-paying-attention-to-4c632440ba8b)  
**Product:** Host Bora (Flutter / GetX — Rent + BnB)  
**Baseline alignment:** ~50% across eight trends (see assessment in product discussion, May 2026)  
**Target after plan:** ~70–75% on trends #2, #5, #6; preserve strengths on #7 and #8

---

## 1. Goals

| Goal | How we measure success |
|------|------------------------|
| **Perceived speed** | No full-screen spinner for list refresh or routine saves; user sees structure within 200ms of navigation |
| **Clarity under load** | Skeleton placeholders on top 5 list screens match final card layout |
| **Trust on writes** | Payment/booking/expense saves show immediate UI state + sync status |
| **Token consistency** | Rent/BnB dark mode uses theme tokens; no new hardcoded `0xFF2C2C2E` in touched files |
| **AI that helps without noise** | One hub-level insight line + chat; fewer duplicate AI nav entries |
| **Operational density kept** | Tenancy/finance cards stay information-rich; secondary metrics behind expand |

---

## 2. Guiding principles (from article → app rules)

1. **Remove confusion, not capability** — hide secondary metrics, don’t hide primary actions users need daily.
2. **Design feedback before the API returns** — every primary button answers “what happened?” in &lt;200ms.
3. **Stable chrome, adaptive content** — workspace (Rent/BnB), locale, filters may change; tab structure and More grid positions do not.
4. **Micro-interactions confirm state** — pressed buttons, undo on destructive actions, inline field errors.
5. **Tokens in code match Figma** — `docs/DESIGN_SYSTEM.md` remains source of truth; code uses extensions, not one-off colors.

---

## 3. Architecture foundations (Phase 0)

**Duration:** 3–5 days  
**Owner:** One dev familiar with `lib/app/core` and Rent shell  
**Blocks:** All later phases

### 3.1 App tokens (`ThemeExtension`)

| Task | Description | Files |
|------|-------------|-------|
| 0.1 | Add `AppThemeTokens` extension: `cardBackground`, `elevatedSurface`, `textPrimary`, `textSecondary`, `textMuted`, `border`, `success`, `warning` | `lib/app/core/theme/app_theme_tokens.dart` (new) |
| 0.2 | Register extension in `_lightTheme()` / `_darkTheme()` in `main_app.dart` | `lib/app/main_app.dart` |
| 0.3 | Map values from `AppColors` + `RentTheme` per `docs/DESIGN_SYSTEM.md` | Same |
| 0.4 | Add `context.tokens` helper (`extension on BuildContext`) | `lib/app/core/theme/app_theme_tokens.dart` |

**Acceptance criteria**

- [ ] `Theme.of(context).extension<AppThemeTokens>()` non-null in light/dark
- [ ] `rentCard()` uses `tokens.cardBackground` (fixes white cards in dark mode)
- [ ] Document new API in `docs/DESIGN_SYSTEM.md` § Implementation notes

### 3.2 Shared loading primitives

| Task | Description | Files |
|------|-------------|-------|
| 0.5 | `AppSkeleton` — rounded rect shimmer (or static grey pulse if no package) | `lib/app/core/widget/app_skeleton.dart` (new) |
| 0.6 | `SkeletonListTile`, `SkeletonMetricCard`, `SkeletonBookingCard` presets | `lib/app/core/widget/skeleton_presets.dart` (new) |
| 0.7 | `LoadingButton` — `onPressed` null + small indicator when `isLoading` | `lib/app/core/widget/loading_button.dart` (new) |
| 0.8 | `UndoSnackBar.show(context, message, onUndo)` wrapper | `lib/app/core/widget/undo_snackbar.dart` (new) |

**Dependency decision:** Add `shimmer` package **or** implement lightweight `AnimationController` pulse (prefer shimmer for polish; document in `pubspec.yaml`).

**Acceptance criteria**

- [ ] Demo screen or widget test proving skeleton + loading button in light/dark
- [ ] No new full-page `Loading` usage in Phase 1 pilot screens

### 3.3 Loading policy (team convention)

Document in this file and enforce in review:

| Scenario | Pattern |
|----------|---------|
| First open of screen (no cached data) | Skeleton body OR inline shimmer grid |
| Pull-to-refresh | Keep content visible; `RefreshIndicator` only |
| `callDataService` on form submit | `LoadingButton` / disable field; **do not** call `showLoading()` |
| Cold auth / DB migration | Full-screen `Loading` allowed |

| Task | Description | Files |
|------|-------------|-------|
| 0.9 | Add `callDataService` option `useFullScreenLoader: false` (default false for new calls) | `lib/app/core/base/base_controller.dart` |
| 0.10 | Deprecation comment on `showLoading()` for list controllers | `base_controller.dart` |

---

## 4. Phase 1 — Real-time feedback (Trend #2)

**Duration:** 1.5–2 weeks  
**Trend impact:** #2 ~38% → ~65%

### 4.1 Pilot screens (skeletons)

Replace body-level `CircularProgressIndicator` with layout-matched skeletons.

| Priority | Screen | Controller / view |
|----------|--------|-------------------|
| P0 | BnB Home | `home_controller.dart`, `home_view.dart` |
| P0 | All bookings | `all_bookings_controller.dart`, `all_bookings_view.dart` |
| P0 | Tenancy insights | `rent_tenant_residency_payment_tracker_*` |
| P1 | Rent hub | `rent_hub_controller.dart`, `rent_hub_view.dart` |
| P1 | My properties (BnB) | `my_properties_*` |

**Per-screen tasks**

1. Introduce `isInitialLoad` vs `isRefreshing` on controller.
2. View: if `isInitialLoad` → `Skeleton*` column; else show data.
3. Wrap scrollable content in `RefreshIndicator` where missing.
4. Remove `homeLoading` full-body spinner pattern where replaced.

**Acceptance criteria**

- [ ] Navigating to pilot screen shows skeleton within one frame, not blank white/dark
- [ ] Pull-to-refresh does not hide list
- [ ] No regression in empty/error states (copy + illustration unchanged)

### 4.2 Button-level loading (high-traffic writes)

| Flow | View | Controller method |
|------|------|-------------------|
| Record payment | `record_payment_view.dart` | `recordPayment` / save |
| Add booking | `add_new_booking_view.dart` | create booking |
| Send SMS / WhatsApp | `send_sms_view.dart` | send actions |
| Add tenant | `rent_add_tenant_form_view.dart` | submit |
| Schedule payment reminder | `rent_schedule_payment_reminder_view.dart` | schedule |

**Tasks**

- Replace `controller.isLoading` full-form lock with `LoadingButton` on primary CTA only.
- Ensure error surfaces on the same screen (snackbar + field errors).

**Acceptance criteria**

- [ ] User can scroll form while submit in flight (where safe)
- [ ] Double-tap does not double-submit

### 4.3 Optimistic UI + sync badges (offline queue)

Leverage existing `OfflineSyncQueueLocalDataSource` and `syncStatus` fields.

| Entity | UI surface | Behavior |
|--------|------------|----------|
| Booking create | Home upcoming list, all bookings | Show pending row immediately; badge “Syncing” |
| Payment | Record payment success → ledger/home if visible | Toast + pending badge until worker completes |
| Expense | Manage expenses list | Same pattern |

**Tasks**

1. Add `SyncStatusChip` widget (`pending` / `synced` / `failed`).
2. After local queue insert, update in-memory lists before pop.
3. Listen for worker completion (or poll on resume) to clear badge.

**Files:** `lib/app/core/widget/sync_status_chip.dart`, `bnb_booking_merge.dart`, `record_payment_controller.dart`, `add_new_booking_controller.dart`

**Acceptance criteria**

- [ ] Airplane mode: create booking → appears in list with “Syncing”; clears when online
- [ ] Failed sync shows “Tap to retry” (reuse queue retry if exists)

---

## 5. Phase 2 — Design tokens & visual consistency (Trend #6)

**Duration:** 1 week (can overlap Phase 1 tail)  
**Trend impact:** #6 ~58% → ~75%

### 5.1 Token migration (incremental)

Migrate **touched files only** in Phase 1–2, then batch Rent shell.

| Batch | Scope | Rule |
|-------|-------|------|
| A | `rent_ui.dart`, `rent_base_shell_view.dart`, `rent_others_tab_view.dart` | Zero hardcoded dark card colors |
| B | Tenancy + ledger views | Use `context.tokens` |
| C | `booking_details_view.dart`, `home_view.dart` | Same |

**Acceptance criteria**

- [ ] Rent More grid + tenancy cards correct in dark mode screenshot test
- [ ] `rg "0xFF2C2C2E" lib/app/modules/rent/base_shell` → 0 matches

### 5.2 Typography cleanup

| Task | Description |
|------|-------------|
| 2.1 | Use `Theme.of(context).textTheme` for section titles on migrated screens |
| 2.2 | Cap micro-labels: minimum 10sp, avoid ALL CAPS blocks &gt; 2 lines (tenancy card) |

**File:** `rent_tenant_residency_payment_tracker_view.dart` — collapse “TOTAL STAY DURATION” into secondary line or expandable section (pairs with Phase 3).

### 5.3 Material 3 (optional sub-phase)

**Defer** unless Phase 0–2 stable. If done:

- Flip `useMaterial3: true` in `main_app.dart`
- Map `ColorScheme.fromSeed(seedColor: AppColors.colorPrimary)`
- Verify `SegmentedButton`, `FilledButton`, inputs in tenancy + schedule reminder

---

## 6. Phase 3 — Functional minimalism & readable density (Trends #1, #7)

**Duration:** 1 week  
**Trend impact:** #1 ~65% → ~75%, #7 ~72% → ~80%

### 6.1 Tenancy card progressive disclosure

**File:** `rent_tenant_residency_payment_tracker_view.dart`

| State | Visible |
|-------|---------|
| Collapsed (default) | Avatar, name, property, balance/status, primary CTA |
| Expanded | Stay duration, lease progress bar, secondary KPIs |

**Tasks**

- `TenantInsightCard` expansion via `ExpansionTile` or custom `AnimatedCrossFade`
- Persist expand preference optional (low priority)

**Acceptance criteria**

- [ ] Scan test: 3 cards fit above fold with more whitespace than today
- [ ] Tap card still opens ledger; chevron expands metrics only

### 6.2 Navigation noise reduction

| Action | Detail |
|--------|--------|
| Audit “More” grid | Mark items used &lt;5% (analytics or survey); move to Help center only |
| BnB home quick actions | Max 8 visible; group Design studio + Moodboards under “Design” if needed |
| AI routes | See Phase 4 |

### 6.3 Bottom sheets for sub-flows

**Pilot:** Booking details → Message / Schedule WhatsApp already exist; convert **Record payment** from full route to sheet when launched from booking details only.

**Files:** `booking_details_controller.dart`, `record_payment_view.dart` (sheet entry variant)

**Acceptance criteria**

- [ ] User returns to booking details without stack depth +2

---

## 7. Phase 4 — AI as layer + micro-interactions (Trends #4, #5)

**Duration:** 1–1.5 weeks  
**Trend impact:** #4 ~45% → ~65%, #5 ~28% → ~55%

### 7.1 Hub insight strip (AI layer)

| Surface | Content | Implementation |
|---------|---------|----------------|
| Rent hub | One line: overdue count / maintenance due | `PortfolioAiLocalResolver` or thin wrapper on `PortfolioAiContextService` |
| BnB home | Active bookings today + revenue snippet | `PortfolioAiContextService` with `workspace: bnb` |

**UI:** `HubInsightBanner` below app bar — tappable → `Routes.AI_MANAGER` with prefilled question.

**Files:** `lib/app/core/widget/hub_insight_banner.dart`, `rent_hub_view.dart`, `home_view.dart`

**Acceptance criteria**

- [ ] Banner loads from local DB only (no network on paint)
- [ ] Tap opens AI Manager with context string, not empty chat

### 7.2 Consolidate AI entry points

| Keep | Demote / merge |
|------|----------------|
| AI Manager (chat) | AI Insights → merge as “suggested questions” in Manager |
| Help center link | AI Automations → settings or future phase |
| — | AI Pricing Optimizer → property/listing context only |

**Tasks**

- Remove duplicate tiles from `rent_others_tab_view.dart` / BnB home when merged
- Redirect old routes to AI Manager with query params (backward compatible)

### 7.3 Communicative micro-interactions

| Pattern | Where |
|---------|-------|
| `HapticFeedback.lightImpact()` | Primary confirm: save payment, schedule WhatsApp, send bulk SMS |
| `UndoSnackBar` | Cancel booking, delete WhatsApp template, remove tenant charge |
| Inline field shake | Auth, add tenant, add booking (first invalid field focus) |
| Success check on button | 300ms `Icon(Icons.check)` morph before pop (optional polish) |

**Files:** `undo_snackbar.dart`, form validators in pilot controllers

**Acceptance criteria**

- [ ] Cancel booking shows undo for 5s; undo restores list item if feasible

---

## 8. Phase 5 — Invisible UI & personalization polish (Trends #3, #8)

**Duration:** 0.5–1 week (ongoing)  
**Trend impact:** #3 ~32% → ~45%, #8 ~65% → ~75%

| Task | Description |
|------|-------------|
| 5.1 | Remember last finance window (tenure / all-time) in `PreferenceManager` |
| 5.2 | Send SMS: restore last workspace + property filter from prefs |
| 5.3 | Swipe actions on maintenance tasks list (complete / snooze) — if list exists |
| 5.4 | Long-press guest card on home → quick actions sheet (message, call, booking) |

**Do not:** Reorder bottom nav or More grid per user behavior.

---

## 9. Testing & rollout

### 9.1 Manual test matrix

| Area | Light | Dark | en | sw | Offline |
|------|-------|------|----|----|---------|
| Phase 1 pilots | ✓ | ✓ | ✓ | ✓ | ✓ |
| Optimistic booking | ✓ | ✓ | — | — | ✓ |
| Token migration batch A–C | ✓ | ✓ | — | — | — |

### 9.2 Automated tests (minimum)

| Test | Type |
|------|------|
| `AppThemeTokens` light/dark values | Unit |
| `LoadingButton` disables second tap | Widget |
| `UndoSnackBar` calls onUndo | Widget |
| Skeleton presets build without overflow | Widget (golden optional) |

### 9.3 Rollout strategy

1. **Internal / staging** — Phase 0 + Phase 1 P0 screens (1 week).
2. **Production** — Phase 1 complete + Phase 2 batch A.
3. **Follow-up release** — Phase 3–4.
4. Feature flag optional: `kUseSkeletonLoading` in `BuildConfig` for instant rollback.

---

## 10. Effort summary

| Phase | Calendar (1 dev) | Parallel (2 devs) |
|-------|------------------|-------------------|
| 0 — Foundations | 3–5 days | 3 days |
| 1 — Feedback | 8–10 days | 5–6 days |
| 2 — Tokens | 5 days | 3 days (overlap) |
| 3 — Density / nav | 5 days | 3 days |
| 4 — AI + micro | 6–8 days | 4–5 days |
| 5 — Polish | 3–5 days | Ongoing |
| **Total** | **~6–7 weeks** | **~4 weeks** |

---

## 11. Out of scope (this plan)

- Full Material 3 migration (unless Phase 2.3 explicitly scheduled)
- Figma Variables → CI codegen pipeline
- Glassmorphism / bento marketing layouts
- Rewriting GetX navigation to declarative routing
- Backend API changes (except existing offline queue)

---

## 12. Definition of done (program level)

- [ ] Baseline ~50% → **≥70%** weighted across eight trends (re-audit checklist in §13)
- [ ] Zero P0 screens use full-body spinner for cached reload
- [ ] `DESIGN_SYSTEM.md` documents tokens, loading policy, skeleton usage
- [ ] No new `Color(0xFF2C2C2E)` in `lib/app/modules/rent/base_shell` or Phase 1 pilots

---

## 13. Re-audit checklist (copy for QA)

Score each trend 0–100% after release:

- [ ] **1. Functional minimalism** — Primary tasks ≤2 taps; secondary hidden not deleted
- [ ] **2. Real-time feedback** — Skeletons + button loading on pilots; optimistic booking
- [ ] **3. Invisible UI** — ≥1 sheet flow + ≥1 swipe/long-press pilot
- [ ] **4. AI as layer** — Hub banner + reduced AI nav clutter
- [ ] **5. Micro-interactions** — Undo on ≥2 destructive flows; haptics on primary saves
- [ ] **6. Design tokens** — ThemeExtension on Rent shell + pilots
- [ ] **7. Data-dense readable** — Tenancy cards expandable; hierarchy ≥12sp body
- [ ] **8. Personalization** — Stable nav; prefs for filters/windows

---

## 14. Key file index

```
lib/app/main_app.dart
lib/app/core/base/base_controller.dart
lib/app/core/base/base_view.dart
lib/app/core/theme/app_theme_tokens.dart          (new)
lib/app/core/widget/app_skeleton.dart             (new)
lib/app/core/widget/loading_button.dart           (new)
lib/app/core/widget/undo_snackbar.dart            (new)
lib/app/core/widget/sync_status_chip.dart         (new)
lib/app/core/widget/hub_insight_banner.dart       (new)
lib/app/modules/rent/widgets/rent_ui.dart
lib/app/modules/rent/hub/views/rent_hub_view.dart
lib/app/modules/home/views/home_view.dart
lib/app/modules/all_bookings/views/all_bookings_view.dart
lib/app/modules/rent/tenant_residency_payment_tracker/views/
lib/app/data/local/service/portfolio_ai_hybrid_service.dart
docs/DESIGN_SYSTEM.md
```

---

*Last updated: May 2026 — adjust dates and owners when sprint planning.*
