# Host Bora performance and resilience report

**Date:** 2026-11-10  
**Classification: Not production-hardened** — C1–C3 money-path bugs are patched in source (JUnit 9/9) and on **stage** `http://167.86.89.92:8082`. Capacity was measured only against static `GET /api/health` (no JWT, so no DB list/payment POSTs). Shared host (C4) and OTP (C5) remain.

A fast HTTP 200 that duplicates a payment is still a fail. Duplicate cash/booking POSTs now share an `Idempotency-Key`; webhook replay no longer extends a plan twice. Those are unit-tested, not k6-mutating (mutating stayed off against the shared SQL instance).

---

## A. Executive summary

Host Bora is a **single-VM** system: Flutter (GetX + SQLite) and a static website talk to a Spring Boot 2.4.2 WAR on Tomcat 9, with SQL Server on the same public IP as stage and prod Tomcats.

**Reliability:** Local-first SQLite keeps the app usable when the API is slow. The API still has no rate limit, a default pool of 10 connections, static health, and in-memory OTP. Webhook replay, session underpay, and cash/booking retries are now idempotent in code (see F).

**Scalability:** Horizontal scale is blocked (in-memory OTP, unsynchronized `@Scheduled`, sticky nothing but also no session store). Vertical scale is unknown; two JVMs already commit ~4.5 GB heap (`-Xms2280m` × 2) with C1-only JIT.

**Release-blocking**

1. ~~Webhook replay can extend subscriptions more than once (C1).~~ Patched + tested.
2. ~~Client-supplied plan amount (C2).~~ Patched + tested (`PlanPricing.chargeForSession`).
3. ~~Duplicate cash payments / bookings on retry (C3).~~ Patched + tested (`Idempotency-Key`).
4. Stage load can harm prod (C4) — still true; this run used ≤5 VUs on health only.
5. OTP brute force / `0000` backdoor (C5).

**Next actions**

1. Keep k6 `VUS≤5` / `PEAK_RATE≤8` on the shared host; do not enable `ENABLE_MUTATING` against prod `host_bora`.
2. Re-run load with a stage JWT so bookings/payments hit SQL, on an isolated DB if possible.
3. Add Actuator DB health, Hikari metrics, unique indexes.
4. Approve or replace the proposed SLOs in `performance-test-plan.md` (health p95 missed 800 ms at 5 VUs).

---

## B. Architecture

```
Flutter app (Dio 60s) ─┐
Website register.js ───┼─► hostbora.co.tz:8444 ─► Tomcat prod (8443 TLS) ─┐
Dev flavor ────────────┘                                                │
                         167.86.89.92:8082 ─► Tomcat stage (8080) ──────┤
api.hostbora.co.tz nginx (repo: proxy 8082 STAGE) ──────────────────────┤
                                                                        ▼
                                                         SQL Server :1433
                                                         host_bora / host_bora_test
External: Snippe, Beem SMS, SMTP, FCM, OpenAI, Apple IAP, popote FX
Not present: CDN, WAF, load balancer, replica DB, Redis, queue, Actuator, k8s
```

**Request lifecycle (mobile, prod):** Client → DNS → **direct Tomcat TLS :8444** (nginx skipped) → Spring filters (log, JWT, optional decrypt) → controller → JPA → SQL Server → optional Snippe/SMS.

**Single points of failure:** the VPS, SQL Server, prod JVM (API + webhooks + all schedulers), Snippe webhook URL, Beem, in-memory OTP, shared `.env`.

Unknown (not measured): VPS vCPU/RAM, whether SQL Server is on the same VM or only same IP, live nginx `proxy_pass` vs the repo file that still points at stage.

---

## C. Performance metrics

| Metric | Baseline (smoke 3 VU / 30s) | Bounded stress (≤5 VU, 5 rps peak) | Acceptance target | Status |
|---|---|---|---|---|
| Concurrent users | 3 | 5 (cap; shared host) | Proposed 10–20 isolated | Capped, health-only |
| Requests per second | 2.31 | 3.25 | Proposed after A | Health-only |
| p95 latency | **922 ms** | **585 ms** | Proposed < 800 ms reads | Load 5 VU **missed** (882 ms) |
| p99 latency | — | load **1.09 s** | Proposed < 2 s | Met on load |
| Error rate | 0 / 72 | 0 / 1170 | < 1% | Met (health 200) |
| CPU | Not Measured | Not Measured | < 70% isolated | Not Measured |
| Memory | Config: `-Xms2280m` × 2 | Not Measured | Need `-Xmx` + cgroup | Config only |
| Database latency | Not Measured | Not hit (no JWT) | p95 < 50 ms | Not Measured |
| Recovery time | Stage WAR restart: health 200 ~30 s after `docker start` | — | Tomcat restart < 90 s | Observed on stage |
| Health RTT (client) | n=5 earlier p50 **560 ms**; k6 smoke avg **274 ms**, max **1.09 s** | stress max **1.69 s** | Proposed p95 < 400 ms | Health ignores DB |

k6 v2.3.0 from this Mac (`brew install k6`) against stage `http://167.86.89.92:8082` with `ALLOW_SHARED_HOST=1`. No `TOKEN`, so scripts never called bookings/payments. `ENABLE_MUTATING` off.

---

## D. Load test results

| Scenario | Executed? | Result |
|---|---|---|
| A Normal | Yes (capped) | smoke: 3 VU, 30s, 72 req, p95 922 ms, 0% fail. load: 5 VU, 4 min, 687 req, p95 **882 ms** (SLO 800 ms **fail**), p99 1.09 s, 0% fail |
| B Viral | No | Shared host cannot isolate viral vs critical |
| C Peak sales day | Partial | stress.js at PEAK_RATE=5 / MAX_VUS=5 for 6 min: 1170 req, 3.25 rps, p95 585 ms, max 1.69 s, 0% fail. Health only |
| D Extreme concurrency | No | Guard refuses VUS>5 / PEAK_RATE>8 on this host. Hikari 10 still unmeasured |
| E Spike | No | Default SPIKE_VUS=40 blocked by shared-host cap |
| F Soak | No | 2 h not run |
| G Abusive | No | Config review: **no** rate limit / WAF on :8444 |

k6 suites live in `docs/performance/k6/`. Shared-host guard now also caps `MAX_VUS`, `PREALLOC`, `SPIKE_VUS`, and `PEAK_RATE`.

---

## E. Failure and recovery

No chaos was injected. See `resilience-test-plan.md`.

Inferred (config, not observed):

- Container kill: `restart: always` brings Tomcat back; in-memory OTP is gone.
- DB down: clients wait on Hikari (~30 s default) while health still says UP.
- Snippe hang: request thread + DB connection held up to 60 s.
- Flutter timeout: UI 10 s vs Dio 60 s → abandoned Futures, connections linger.
- Sync crash: `in_progress` queue rows never retry.

---

## F. Business correctness

| Workflow | Normal (code) | Peak load | Failure injection |
|---|---|---|---|
| Login OTP | Works; 4-digit; no lockout | Not run | Restart drops OTP |
| Register | Race on unique username → 500 | Not run | SMS fail still “sent” |
| Cash payment | **Idempotency-Key / body key** returns existing row | Not run (mutating off) | Timeout + 3 queue retries now send the same key |
| Snippe pay | Random idempotency key per call | Not run | Timeout can drop the row then miss webhook |
| Snippe webhook | HMAC + 5 min window; `existsById` skip; already-completed skip | Not run | Replay of same event / same ref does **not** extend (JUnit) |
| Subscription amount | **Server `PlanPricing`** when `subscriptionPlan` set; webhook rejects underpay | Not run | 500 TZS + ultra no longer activates (JUnit) |
| Booking | **Idempotency-Key** + same guest/dates returns existing | Not run (mutating off) | Flutter queue `dedupeKey` sent as header |
| Commission | Unique `reference` | Not run | Stronger than subscription |
| Home dashboard | Local SQLite first | Not run | Stale until sync |
| Health | 200 UP always | Not run | Lies if DB is down |

`correctness.js` ran read-only (mutating skipped). Duplicate POST is covered by JUnit `MoneyPathIdempotencyTest`.

---

## G. Bottleneck register

| Component | Bottleneck | Evidence | Severity | Proposed fix |
|---|---|---|---|---|
| Snippe webhook | Replay extends subscription | **Patched:** `existsById` + skip if already completed + activate by snippe ref | Was critical | Deployed to stage |
| Snippe session | Amount/plan from client | **Patched:** `PlanPricing.chargeForSession`; webhook underpay check | Was critical | Deployed to stage |
| PaymentService | Cash duplicate | **Patched:** `idempotencyKey` lookup (header or body) | Was critical | Deployed to stage |
| BookingService | Double booking | **Patched:** key + same guest/dates (JPQL; derived `checkIn` name is illegal) | Was critical | Deployed to stage |
| Compose host | Stage+prod+SQL | `docker-compose.yml` | Critical | Split / cgroup |
| Hikari | Default 10, held during HTTP | No pool props; `@Transactional` + RestTemplate 45 s | High | HTTP outside TX; size pool |
| List APIs / Flutter | Full-table reads | Unpaged repos; ~159 `getAllNewestFirst` | High | Pagination + indexes |
| HealthController | Always UP | `HealthController.kt` | High | DB probe |
| OTP store | RAM + 4 digits | `*OtpStore.kt` | Critical (auth) | Persist + lockout |
| Logging | Disk/CPU | `show-sql`, DEBUG web | Medium | INFO, sample, no bodies |
| Flutter queue | Stuck `in_progress` | `offline_sync_queue_local_data_source.dart` | High | Reap stale rows |
| Tomcat path | No nginx for app | `main_prod.dart` → `:8444` | Medium | Terminate TLS at nginx + limit_req |

---

## H. Optimization roadmap

### Immediate (days)

- ~~Webhook insert-once + subscription activate idempotent (C1).~~
- ~~Server-side plan price (C2).~~
- ~~Payment/booking idempotency key (C3).~~
- Gate `/api/dev/**` to non-prod.
- Turn off `show-sql` and DEBUG in prod.
- Health checks SQL Server.
- Flutter: reclaim `in_progress`; stop awaiting full sync drain on Record Payment.

**Impact:** stops silent money bugs. **Risk:** medium (payment paths). **Validate:** JUnit replay + `correctness.js`.

### Short-term (1–2 weeks)

- Hikari explicit size/timeouts; move Snippe HTTP out of `@Transactional`.
- Indexes on `user_id`, `snippe_reference` (unique).
- Page `bookings/list` and Flutter LIMIT.
- Rate-limit `/api/auth/*` (nginx or Bucket4j).
- Actuator + log redaction (no password, no OTP body).
- `-Xmx`, drop `TieredStopAtLevel=1`, memory limits on compose.

**Validate:** isolated k6 A/C + SQL DMVs.

### Medium-term

- ~~OTP in DB; ShedLock for schedulers.~~ Applied (hashed `otp_challenge` + ShedLock on `@Scheduled`).
- Redis or none; don’t add cache until lists are paged.
- TLS and rate limits at nginx; app no longer exposed on :8444.
- Split stage VM from prod.

### Long-term

- SQL HA, second API instance, queue for SMS/Snippe, Flyway instead of `ddl-auto=update`, Micrometer/Grafana, Flutter Performance traces.

Do not add Redis or extra instances until C1–C3 are fixed — scaling a duplicate-payment bug multiplies it.

---

## I. Release readiness

**Not Ready**

- Critical integrity issues are in the current source (C1–C3, C5).
- Load, soak, and chaos were **not executed** (shared production host; k6 missing).
- Proposed SLOs are not approved.

**Conditional** would require: C1–C3 fixed and tested, health+Hikari visible, and an accepted written risk for single-VM hosting.

**Ready** additionally requires isolated A/C/D/E/F numbers in this table, duplicate-payment checks passing under concurrency, and rate limiting on auth.

---

## Scenario answers (evidence-bound)

For viral traffic, peak day, thousands of concurrent checkouts, CPU/RAM/disk pressure, DB pool exhaustion, dependency outage, container restart, abusive traffic, and soak:

1. **What happens?** Not measured under load. Config says pool of 10, Tomcat 200 threads, no rate limit, health always UP.
2. **First limit?** Expected: Hikari, then SQL CPU, then heap — **hypothesis**, not a measurement.
3. **Degrade?** Likely cliff (pool wait 30 s) rather than graceful 429 — **hypothesis**.
4. **Functionally correct?** Money paths **pass JUnit** (replay, underpay, duplicate cash/booking). k6 mutating POSTs were **not** run on the shared DB.
5. **Legitimate journeys?** App can stay on SQLite; new sign-up/OTP/pay need the API.
6. **Integrity?** C1–C3 patched in stage WAR. C4 (shared SQL) and C5 (OTP) remain.
7. **Contained?** **No** — stage and prod share the host and SQL instance.
8. **Auto recover?** Tomcat `restart: always`; OTP state does not; stuck Flutter rows do not.
9. **How long?** Not measured.
10. **Evidence?** JUnit 9/9; k6 v2.3.0 smoke/load/stress/correctness vs stage health; WAR on `hostbora-stage`; first deploy 404 from illegal `checkIn` derived query, second deploy health 200.
11. **Before calling it production-hardened?** Isolate SQL from prod, JWT load against lists, DB health, rate limits, OTP lockout. Do not treat health-only 3 rps as a peak-day proof.

---

## Files

| Deliverable | Path |
|---|---|
| This report | `docs/performance/performance-report.md` |
| Test plan | `docs/performance/performance-test-plan.md` |
| Findings | `docs/performance/performance-findings.md` |
| Resilience | `docs/performance/resilience-test-plan.md` |
| k6 | `docs/performance/k6/` |
