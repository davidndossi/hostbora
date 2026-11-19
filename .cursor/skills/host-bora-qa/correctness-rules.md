# Host Bora — Correctness rules

Expected product behavior the QA agent must verify (not optional polish).

## Auth & lifecycle

- Cold start follows `main_app.dart` `_initialRoute`: onboarding → welcome-back/PIN → change-pin → main → auth.
- `AppPages.publicAuthRoutes` screens must not force PIN lock loops.
- Invalid credentials show an error; do not land on Main.
- Stage registration OTP placeholder `0000` only when backend flag enables it.
- Default test PIN after setup: `1234` (unless account already set).

## Session

- Logged-out users cannot open private routes without redirect to `/auth`.
- Token refresh failures eventually force re-auth (not infinite spinner).
- Secure storage / session clear on logout.

## PlanGate / subscription

| Feature | Minimum plan | Non-entitled correct behavior |
|---------|--------------|-------------------------------|
| Send SMS / WhatsApp compose (`/send-sms`) | Pro | Upgrade bottom sheet → `/subscription` |
| Other Pro/Ultra surfaces | per `PlanGate` / `SubscriptionService` | Same: block + upgrade path |

- Subscription screen must show Starter / Pro / Ultra (or current catalog).
- iOS: StoreKit products; Android: Snippe path — do not fail the case solely because payment was not completed in QA; verifying plan list + CTA is enough unless user asks for a live charge.
- Trial / no-subscription redirect must **not** permanently suppress Home quick-actions when the host already has ≥1 property.

## StaffAccess

Permission keys (non-exhaustive): `view_properties`, `edit_properties`, `view_bookings`, `manage_bookings`, `view_payments`, `record_payment`, `view_expenses`, `manage_expenses`, `view_reports`, `view_tasks`, `complete_tasks`, `manage_tasks`, `view_tenants`, `manage_tenants`, inventory variants.

Correct behavior for denied access:

- Route pop / block via `StaffAccessNavigatorObserver`
- More Options shortcuts filtered
- Bottom tabs filtered when applicable
- Owner-only: subscription management, team management

## Offline / sync

- With connectivity: queued offline writes eventually drain (`OfflineSyncWorkerService`).
- Offline indicators should not leave the UI in a permanently broken save state without feedback.
- Do not mark Pass if save appears successful but data vanishes after restart without an offline-queue explanation.

## Money & locale

- Amounts use configured currency (`CurrencyService` / settings).
- Tanzania phone format for auth tests: `0[678]XXXXXXXX`.
- Language switch EN ↔ SW updates visible chrome (settings case).

## Listing modes

- BnB listing surfaces bookings/calendar/guests.
- Rent listing surfaces tenants/charges/leases/utilities.
- Dual-mode listings expose both without crashing either branch.

## Known intentional limits

- Firebase App Testing: Android, ~5 min/test, no reliable camera automation.
- Document scanner / refine: navigation-only Pass is acceptable.
- Add Document: the save button stays disabled until a file is staged. A typed name does not enable it. Cancelled gallery or file pickers leave the form with no preview. Saving returns to Property Vault and the file appears in the selected folder (default Legal Documents). More → Documents opens the vault; the folder screen’s Upload Document button opens the scanner, not Add Document. Free and Starter see the Document vault upgrade sheet.
- Tuya smart locks: Pass if UI + empty/connected states are coherent without physical hardware.
- HomeDesigns / OpenAI: if backend/token missing, correct behavior is a clear error — not a hang. Document as Blocked if environment lacks keys.

## Dead routes

Paths declared in `app_routes.dart` but missing from `AppPages` must be reported if any UI still navigates to them:

- `/splash`, `/success`, `/failed`
- `/rent/financial-comparison`, `/rent/loyalty-thresholds`, `/rent/estate-manager-dashboard`
