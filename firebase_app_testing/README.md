# HostBora — Firebase App Testing agent suites

Natural-language test cases for the [Firebase App Testing agent](https://firebase.google.com/docs/app-distribution/android/app-testing-agent) (Android preview).

## Prerequisites

1. Open [App Distribution for Host Bora](https://console.firebase.google.com/project/paa-yangu/appdistribution) and click **Get started** (required once per project).
2. Opt in to the **App Testing agent** preview in App Distribution.
3. Use the Android app registered as `tz.co.artbel.paa_yangu` (package must match your APK/AAB).
4. Build a **prod/stage APK/AAB** that points at your test backend.
5. **Firebase CLI ≥ 15** for `apptesting:execute`.

```bash
firebase --version   # should be 15.x+
# or rely on helper scripts (they use npx firebase-tools@latest on older CLIs)
```

## Important: use the correct App ID

The App ID in `android/app/google-services.json` is the one tied to your shipped app:

```
1:610307403409:android:f58b9db750a20136961930
```

Do **not** use the stale ID from `firebase.json` (`...70ee5414cd96590b961930`). Using the wrong ID causes:

```
✖ Failed to request test execution
Error: Test invocation failed
```

(with `--debug`: `App Distribution could not find your app ... 404 NOT_FOUND`)

The helper scripts read the App ID from `google-services.json` automatically.

## Test credentials

| Variable | Example | Notes |
|----------|---------|--------|
| `TEST_PHONE` | `0701001001` | Tanzanian format `0[678]XXXXXXXX` |
| `TEST_PASSWORD` | *(stage password)* | Must exist on backend |
| Registration OTP (stage) | `0000` | When `app.otp.registration.accept-placeholder=true` |
| App PIN (after first login) | `1234` | Set during first PIN setup if prompted |

## Quick start (smoke test)

```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart

export TEST_PHONE="0701001001"
export TEST_PASSWORD="your-stage-password"

# Recommended first run: single login test
SMOKE=1 ./firebase_app_testing/run-tests.sh
```

## Run all suites

```bash
export TEST_PHONE="0701001001"
export TEST_PASSWORD="your-stage-password"

./firebase_app_testing/run-tests.sh
```

Default binary: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

## Run a subset

```bash
TEST_FILE_PATTERN="00-setup-auth" \
TEST_NAME_PATTERN="Login with phone" \
./firebase_app_testing/run-tests.sh
```

Note: `--test-name-pattern` matches the test **display name**, not the YAML `id` field.

## Import test cases to Firebase console

```bash
./firebase_app_testing/import-tests.sh
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `unknown option '--app'` | Upgrade to Firebase CLI 15+ or use helper scripts |
| `Test invocation failed` / `404 NOT_FOUND` | Wrong App ID — use `google-services.json` value; enable App Distribution (**Get started**) |
| `No tests found` | `--test-name-pattern` must match display name (e.g. `Login with phone`, not `host-login`) |
| Tests fail at login | Pass `--test-username` / `--test-password-file`; ensure stage account exists |
| Hangs on upload | AAB uploads can take 1–2 minutes; use `FIREBASE_DEBUG=1` for details |
| Home quick-actions dialog never appears (`14-home-quick-actions.yaml`) | It only shows once the host has ≥1 property. Run `02-bnb-properties-bookings.yaml` first (or seed a property on the stage account), then re-run. |
| "Other (Specify)" tests time out or always show the error message | The backend AI endpoint (`POST /api/ai/request`) needs `OPENAI_ENABLED=true` and a valid `OPENAI_API_KEY` on the stage backend the test build points at. |
| Send SMS / WhatsApp / subscription tests land on the subscription screen instead of Send SMS | Expected on a non-Pro test account. Send SMS (`Routes.SEND_SMS`, `SendSmsController._checkAccess`) is gated behind the Pro plan via `PlanGate`; opening it without Pro shows an "Upgrade to Pro" bottom sheet that, on tap, navigates to `Routes.SUBSCRIPTION`. This is also the most reliable way to reach the subscription plans screen in tests (see `10-communications.yaml` and `12-reports-subscription.yaml`). |
| Home quick-actions dialog never appears even though the host has properties | `HomeController._maybeShowTrialPrompt` used to race `_maybeShowQuickActionsDialog` — if the account had no active subscription, it would redirect to `Routes.SUBSCRIPTION` before the quick-actions dialog's guard check (`Get.currentRoute != Routes.MAIN`) ran, permanently skipping the dialog for that session. Fixed by skipping the trial prompt once `hasAnyProperty` is true. |

Debug a failing run:

```bash
FIREBASE_DEBUG=1 SMOKE=1 ./firebase_app_testing/run-tests.sh
```

## Suite layout

| File | Coverage |
|------|----------|
| `00-setup-auth.yaml` | Login, PIN unlock, forgot password |
| `01-onboarding-registration.yaml` | Onboarding, host registration, OTP |
| `02-bnb-properties-bookings.yaml` | Properties, listings, bookings |
| `03-bnb-calendar-guests.yaml` | Calendar, guest history, access codes |
| `04-finance-payments.yaml` | Dashboard, record payment, expenses, reports |
| `05-rent-tenants-leases.yaml` | Tenants, leases, rent payments, reminders |
| `06-rent-utilities-loyalty.yaml` | Utilities, loyalty, concierge |
| `07-documents-vault.yaml` | Property vault, documents |
| `08-maintenance-staff.yaml` | Tasks, staff roster |
| `09-ai-pricing-design.yaml` | AI Manager, pricing, design studio |
| `10-communications.yaml` | SMS / WhatsApp |
| `11-smart-access.yaml` | Smart locks, entry logs |
| `12-reports-subscription.yaml` | Reports hub, subscription plans |
| `13-settings-support-legal.yaml` | Settings, help, legal, feedback |
| `14-home-quick-actions.yaml` | Home "What would you like to do?" dialog, quick-add wizards, AI "Other (Specify)" routing |

## Agent limitations

- **5-minute timeout** per test — keep steps short.
- **Android only** in preview.
- Document-scan tests verify navigation only (no camera automation).
- Running 89 tests × 2 devices consumes quota quickly — start with `SMOKE=1`.

## CI example

Wire `SMOKE=1 ./firebase_app_testing/run-tests.sh` into your pipeline after `flutter build appbundle`.
