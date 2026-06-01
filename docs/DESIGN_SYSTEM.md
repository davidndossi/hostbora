# Host Bora – Design System

Design source: **[Figma – HOST BORA](https://www.figma.com/design/7PeFdWA0oIYMxMEoc8qkxm/PAA-YANGU?node-id=2001-1281&m=dev)**

Use this file and the Figma link above as the single source of truth for UI implementation.

---

## Colors

| Token | Hex | Usage |
|-------|-----|--------|
| **Primary (teal)** | `#1C6E64` | Primary buttons, active states, selected nav, links, focus |
| **Primary dark** | `#145C54` | Hover / pressed primary |
| **Surface / background** | `#F6F8F8` | Page background, splash |
| **White** | `#FFFFFF` | Cards, app bar, inputs |
| **Primary text** | `#4A4A4A` | Headings, body |
| **Secondary text** | `#9FA4B0` | Captions, hints |
| **Placeholder** | `#A0A0A0` | Input placeholders |
| **Input border** | `#E0E0E0` | Borders, dividers |
| **Success** | `#2ECC71` | Confirmations, positive change |
| **Alert** | `#E74C3C` | Errors, negative change |

In code: `AppColors.colorPrimary`, `AppColors.designAccent`, `AppColors.designSurface`, `AppColors.pageBackground`, etc.

---

## Typography

- **Sans-serif**, clear hierarchy.
- **Titles**: 24–28px, bold (w700).
- **Section headings**: 16–18px, semibold (w600).
- **Body**: 14–15px, regular (w400).
- **Captions / secondary**: 11–13px, regular or medium.
- **Primary text color**: `AppColors.textColorPrimary` / `designSecondaryText`.
- **Secondary text**: `AppColors.textColorSecondary`.

---

## Components

### Cards

- **Background**: White (`AppColors.colorWhite`).
- **Corner radius**: 12px (`AppValues.radius_12`).
- **Shadow**: Subtle elevation — `BoxShadow(color: black 6%, blur: 8, offset: (0, 2))`.
- Use for: metric cards, list items, content blocks, property cards.

### Buttons

- **Primary**: Teal fill, white text, rounded corners (e.g. 6–8px or 24px for pill).
- **Secondary**: White/outline with teal border or teal text.
- **Height**: ~48px for main actions; use `AppValues.formButtonHeight` where applicable.

### App bar

- White or transparent; dark icons.
- Back button, title, actions (e.g. notifications, settings).

### Bottom navigation

- White bar, top rounded corners (e.g. 20px).
- Selected item: teal (`colorPrimary`); unselected: grey.
- Icons + labels; minimal style.

### Inputs

- Rounded corners (6px); border `designInputBorder`.
- Focus: border `colorPrimary`.
- Placeholder: `designPlaceholder`.

---

## Layout

- **Padding**: 16–20px horizontal for screen content; 12–16px inside cards.
- **Spacing**: 8, 12, 16, 24px between sections (`AppValues.halfPadding`, `margin_12`, `padding`, `largePadding`).
- **Content**: Cards and sections in a vertical scroll; horizontal scroll only where needed (e.g. trend charts, lists of cards).

---

## Implementation notes

- Use `AppColors` and `AppValues` for all spacing, radius, and colors so the app stays aligned with Figma.
- For semantic surfaces in code, prefer `context.tokens` from `AppThemeTokens` (`lib/app/core/theme/app_theme_tokens.dart`) — especially card backgrounds in dark mode.
- For new screens, match the structure above (surface background, white cards, teal primary actions).
- When in doubt, refer to the [Figma file](https://www.figma.com/design/7PeFdWA0oIYMxMEoc8qkxm/PAA-YANGU?node-id=2001-1281&m=dev) and Dev Mode specs.

### Loading UI (2026)

| Scenario | Use |
|----------|-----|
| First paint of a list screen | Layout skeleton (`AppSkeleton`, `skeleton_presets.dart`) |
| Pull-to-refresh | `RefreshIndicator`; keep content visible |
| Form submit | `LoadingButton` — not `showLoading()` / full-screen overlay |
| Cold start / auth | Full-screen `Loading` allowed |

See `docs/UI_IMPROVEMENT_PLAN.md` for the full rollout plan.

### App-wide UI patterns (2026 rollout)

| Pattern | API |
|---------|-----|
| Theme tokens | `context.tokens` — `AppThemeTokens` |
| First load | `DefaultScreenSkeleton` / `RentDefaultScreenSkeleton` |
| List screen body | `AsyncScreenBody(isLoading:, child:)` |
| Base loading overlay | `BaseView.pageLoadingSkeleton` override |
| Submit buttons | `LoadingButton` / `rentPrimaryButton(isLoading:)` |
| Swipe actions | `AppSwipeableCard` / `AppInteractiveCard` |
| Undo destructive | `controller.runDestructiveWithUndo(...)` — `feedback_extensions.dart` |
| Haptics | `hapticPrimaryConfirm()` / `hapticValidationError()` |

Batch migration script: `tool/ui_trend_migrate.py`.
