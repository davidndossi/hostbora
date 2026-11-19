# Host Bora performance findings

Evidence is **code and configuration**, plus the 2026-11-10 bounded k6 run in `performance-report.md`. Secrets are not reproduced.

**Status 2026-11-10:** C1–C3 patched on stage (`existsById` + activate-by-ref; `PlanPricing.chargeForSession`; payment/booking `Idempotency-Key`). C4–C5 unchanged.

Severity: **Critical** (money/identity integrity or shared-host outage) · **High** (capacity / correctness under load) · **Medium** · **Low**.

---

## Critical

### C1. Snippe webhook replay can extend a subscription twice

`SnippePaymentService.processWebhookEvent` inserts `SnippeWebhookEvent` with an **assigned** String `@Id` then catches `DataIntegrityViolationException` (`SnippePaymentService.kt` ~393–411). Spring Data `save()` on a non-`Persistable` assigned id typically **merges** (SELECT then UPDATE), so a sequential redelivery does **not** throw. `SubscriptionService.activateFromPayment` then adds `30d × months` to `currentPeriodEnd` every call (`SubscriptionService.kt` ~148–150).

Commission is better protected (`commission_ledger.reference` unique). Subscription period is not.

**Fix:** persist-once table with native `INSERT` / `existsById` short-circuit **before** activate; activate keyed by `snippeReference`; webhook always 200 after persist.  
**Validate:** replay the same signed `payment.completed` twice on isolated DB; period must not grow.

### C2. Client chooses subscription amount and plan

`POST /api/snippe/sessions` forwards client `amount` and `subscriptionPlan`. Webhook activates whatever plan is stored and never compares amount to `PlanPricing`. Minimum amount is 500 TZS.

**Fix:** server-side price only; reject mismatch.  
**Validate:** session with amount 500 and plan `ultra` must 400.

### C3. Cash payments and bookings are not idempotent

`PaymentService.recordPayment` de-dupes only when `snippeReference` is set (`PaymentService.kt` ~68–71). Cash retries insert another row. Amounts are `Double`. `BookingService.createBooking` has no overlap check and no client idempotency key.

Flutter `offline_sync_queue` retries failed POSTs up to 3 times **without** an idempotency header. A timeout after commit creates duplicates.

**Fix:** `Idempotency-Key` unique per user; booking exclusion constraint; `BigDecimal`/minor units.  
**Validate:** `k6/correctness.js` with `ENABLE_MUTATING=1` must fail today (documents the bug) and pass after the fix.

### C4. Stage and prod share one host and one SQL Server

`docker-compose.yml`: `hostbora-stage` 8082 and `hostbora-prod` 8444, both `Xms=2280m`, no memory limits, same `.env`. Both JDBC to `167.86.89.92:1433`. A stage load test or OOM can take down production.

**Fix:** split VMs or at least cgroup limits + separate SQL; never run stress on 8082 as it stands.

### C5. OTP is brute-forceable; one phone accepts `0000`

4-digit codes, in-memory maps, no attempt cap (`LoginOtpStore`, `RegistrationOtpStore`). Placeholder `0000` for a hard-coded number is accepted even when prod `accept-placeholder` is false.

**Fix:** 6-digit, attempt lockout, persist OTP, remove prod backdoor.

---

## High

### H1. Hikari pool is default 10; Snippe/SMS run inside transactions

No `spring.datasource.hikari.*`. `initiateMobilePayment` is `@Transactional` and waits up to 15 s connect + 45 s read on Snippe. Ten concurrent STK starts can stall all API traffic.

**Fix:** HTTP outside the transaction; `maximumPoolSize` 20–40 with metrics; timeouts on every `RestTemplate`.

### H2. Unbounded list APIs + unbounded Flutter loads

Notifications are the only paged endpoint. `/api/bookings/list`, `/api/properties`, `/api/payments`, `/api/expenses`, `/api/tenants` return full collections. Flutter `getAllNewestFirst()` appears at ~159 call sites. Home fires three API calls plus four full local income scans.

**Fix:** page size 50; SQL indexes on `user_id` + date; Flutter LIMIT; cancel Dio on dispose.

### H3. Almost no indexes

Only `RefreshToken` declares an entity index. Hibernate `ddl-auto=update` will not invent them. Webhooks look up `snippe_payment` by `snippe_reference` with no unique index.

**Fix:** unique `(snippe_reference)` where not null; index `(user_id, created_at)` on booking, payment, expense, listing.

### H4. Health is a lie

`GET /api/health` always returns UP (`HealthController.kt`). DB outage is invisible.

**Fix:** Actuator with DB ping; nginx/upstream must use it.

### H5. Flutter sync row can stick in `in_progress`

`markInProgress` then handler; `nextPending` only reads `pending`; crash leaves the row forever (`offline_sync_queue_local_data_source.dart`).

**Fix:** reclaim `in_progress` older than 2 minutes.

### H6. JWT user lookup + possible BCrypt on every request

`JWTAuthorizationFilter` loads the user by username. `User.password` default expression is `BCryptPasswordEncoder().encode("")` — if that runs on the no-arg constructor used by Hibernate, every authenticated request pays BCrypt. Confirm with a profiler; treat as **High until disproved**.

### H7. JIT and heap on a shared box

`JAVA_OPTS=-Xms2280m -noverify -XX:TieredStopAtLevel=1` on **both** containers (~4.5 GB committed) and C1-only JIT. No `-Xmx`, no container memory limit. Host RAM unknown.

### H8. Public `/api/dev/*` is not profile-gated

Can send SMS and create Snippe links without auth (`WebConfig` permitAll + `DevController`).

---

## Medium

### M1. `show-sql=true`, DEBUG web/security, `mail.debug=true` in stage and prod

Log and disk blow-up under load; JWT may appear in logs (`log-request-details`). Login filter logs decrypted `LoginRequest` (password in `toString`).

### M2. Open-in-view default, N+1 owner loops

`BookingService` / `PaymentService` `owners.flatMap { find… }`. Dashboard issues many monthly queries.

### M3. No rate limit, WAF, or CDN in front of the mobile API

App talks **directly** to Tomcat `:8444`, bypassing nginx `limit_req`.

### M4. New `RestTemplate` per SMS (`SmsService`) — pool leak under OTP storms.

### M5. Calendar import `RestTemplate()` has no timeout; fetches user URLs (SSRF + hang). `@Transactional syncAllEnabledImports` holds one connection for the whole job.

### M6. Image.network without cache; `File.existsSync()` in `build()`.

### M7. Dio interceptors cleared on a shared client each getter — racy.

### M8. Apple IAP JWS not signature-verified (integrity, not only perf).

---

## Low

- `PagingController` exists but is unused.
- Tuya init only in `main.dart`, not prod.
- 90-day access tokens increase stolen-token window.
- Scheduler pool size 1000 is oversized for the jobs listed.

---

## Probe (not a load test)

Five sequential `GET http://167.86.89.92:8082/api/health` from Dar es Salaam, 2026-11-10:

| # | Status | Client RTT |
|---|---|---|
| 1 | 200 | 1069 ms |
| 2 | 200 | 457 ms |
| 3 | 200 | 607 ms |
| 4 | 200 | 390 ms |
| 5 | 200 | 560 ms |

n=5, min 390 ms, p50 560 ms, max 1069 ms, avg 616 ms. Health does **not** touch SQL Server, so this is TLS/network + empty controller only.
