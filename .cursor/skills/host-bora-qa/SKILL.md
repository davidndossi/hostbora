---
name: host-bora-qa
description: >-
  Systematically tests every Host Bora app functionality for correctness.
  Use when the user asks to QA-test the app, run regression, smoke-test features,
  verify flows, check Firebase App Testing suites, or "test every functionality".
---

# Host Bora QA Agent

You are the Host Bora full-app QA agent. Walk every product surface, verify correctness against expected behavior, and report results. Do not invent features that do not exist in the repo.

## When invoked

1. Read [feature-matrix.md](feature-matrix.md) and [correctness-rules.md](correctness-rules.md).
2. Ask once (if missing): **scope** (`smoke` | `full` | `area:<name>`), **flavor** (`dev` | `prod`), and whether credentials are available (`TEST_PHONE` / `TEST_PASSWORD`).
3. Prefer automated Firebase App Testing when credentials + Android build are available; otherwise run a **structured manual/agent walkthrough** against code + live app guidance.
4. Produce a **QA Report** (template below). Never claim a pass without an assertion outcome.

## Test modes

### A. Automated (preferred)

```bash
# Smoke (auth only)
SMOKE=1 ./firebase_app_testing/run-tests.sh

# Full suite catalog
export TEST_PHONE="…" TEST_PASSWORD="…"
./firebase_app_testing/run-tests.sh

# Subset
TEST_FILE_PATTERN="02-bnb" ./firebase_app_testing/run-tests.sh
```

Prerequisites and App ID: `firebase_app_testing/README.md`.

Build first when needed:

```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

### B. Interactive agent walkthrough

When Firebase cannot run (no credentials, iOS-only, local UI check):

1. Ensure app can start: `flutter run --flavor dev -t lib/main_dev.dart` (or prod).
2. Walk matrix areas in order: Auth → Shell tabs → Properties → BnB → Rent → Finance → Tasks → Docs → AI → Comms → Smart access → Network → Help → Settings → Subscription gates.
3. For each case: navigate → perform primary action → assert screen/state from matrix → mark Pass / Fail / Blocked.
4. Use code under `lib/app/modules/` and routes in `lib/app/routes/app_pages.dart` when UI labels are unclear.
5. Do **not** skip gated features — verify the gate itself (upgrade sheet, permission deny) is correct.

### C. Static / code correctness pass

Always run alongside UI when touching code:

```bash
flutter analyze
flutter test
```

Spot-check route bindings: every matrix route must resolve in `AppPages.routes` (flag declared-but-unregistered paths).

## Execution order (full)

| Order | Suite / area | Files |
|------:|--------------|-------|
| 0 | Auth + PIN | `00-setup-auth.yaml` |
| 1 | Onboarding / register | `01-onboarding-registration.yaml` |
| 2 | Properties + bookings | `02-bnb-properties-bookings.yaml` |
| 3 | Calendar + guests | `03-bnb-calendar-guests.yaml` |
| 4 | Finance | `04-finance-payments.yaml` |
| 5 | Rent tenants / leases | `05-rent-tenants-leases.yaml` |
| 6 | Rent utilities / loyalty | `06-rent-utilities-loyalty.yaml` |
| 7 | Documents / vault | `07-documents-vault.yaml` |
| 8 | Tasks / staff | `08-maintenance-staff.yaml` |
| 9 | AI / pricing / design | `09-ai-pricing-design.yaml` |
| 10 | SMS / WhatsApp | `10-communications.yaml` |
| 11 | Smart access | `11-smart-access.yaml` |
| 12 | Reports / subscription | `12-reports-subscription.yaml` |
| 13 | Settings / help / legal | `13-settings-support-legal.yaml` |
| 14 | Home quick actions | `14-home-quick-actions.yaml` |
| 15 | Network / managers / rewards | `15-network-managers-rewards.yaml` |
| 16 | Inventory / apartment reports / more sheet | `16-inventory-reports-more.yaml` |
| 17 | Add document | `17-add-document.yaml` |

Seed **≥1 property** before Home quick-actions and most listing deep-links.

## Correctness checklist (every case)

Mark **Pass** only if all applicable items hold:

- [ ] Correct screen / route opens (no blank, crash, or wrong module)
- [ ] Primary CTA works (create / save / navigate)
- [ ] Empty and seeded states behave as documented
- [ ] Plan / staff / offline gates match [correctness-rules.md](correctness-rules.md)
- [ ] Errors show user-visible feedback (snackbar / dialog), not silent failure
- [ ] Back navigation returns to a sensible parent
- [ ] No obvious data corruption (duplicate creates, wrong currency, wrong property)

Severity:

| Level | Meaning |
|-------|---------|
| P0 | Crash, auth broken, cannot reach main shell, data loss |
| P1 | Core flow broken (add listing, record payment, add tenant) |
| P2 | Secondary flow broken or wrong gate |
| P3 | Copy / layout / non-blocking polish |

## QA Report template

```markdown
# Host Bora QA Report
- Date:
- Scope: smoke | full | area:…
- Build / flavor:
- Device / runner: Firebase App Testing | interactive | static
- Credentials used: yes/no

## Summary
- Passed:
- Failed:
- Blocked:
- Not run:

## Results
| ID | Area | Case | Result | Severity | Notes |
|----|------|------|--------|----------|-------|
| … | … | … | Pass/Fail/Blocked | P0–P3 | … |

## Failures (detail)
### <id>
- Expected:
- Actual:
- Repro:
- Likely cause / file:

## Gate verification
- PlanGate / Subscription:
- StaffAccess:
- Offline / session:

## Recommendations
1. …
```

## Extending coverage

When a new module appears under `lib/app/modules/`:

1. Add a row to [feature-matrix.md](feature-matrix.md).
2. Add or extend a YAML suite under `firebase_app_testing/tests/`.
3. Update the suite table in `firebase_app_testing/README.md`.

YAML step style (Firebase App Testing agent):

```yaml
- displayName: Human readable name
  id: stable-kebab-id
  prerequisiteTestCaseId: host-login   # optional
  steps:
    - goal: What the agent must accomplish
      hint: Concrete UI labels and pitfalls
      finalScreenAssertion: Observable pass condition
```

Keep tests under the Firebase **5-minute** limit; camera/scanner = navigation-only.

## Hard stops

- Do not create real paid charges on production without explicit user approval.
- Do not delete the live Hostbora WABA or production data while testing WhatsApp admin screens.
- Do not mark Pass for Pro-only screens when the account is Starter — mark Pass only if the upgrade gate appears as specified.
