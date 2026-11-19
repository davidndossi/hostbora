# Host Bora performance test plan

**Status:** Authorized for **static analysis + script generation**. Load execution against the live Contabo host is **blocked** until an isolated environment exists.  
**Date:** 2026-11-10  
**Code reviewed:** Flutter app `host_bora` and Kotlin API `/Users/dell/IdeaProjects/host_bora` (working tree).  
**Discovery:** [Backend](bf561a03-7132-48b6-8179-ed0433af23d7), [Client](28c27fe5-d2f2-491d-b5d7-f0809ab230e0).

A 200 that creates two payments is a **fail**, not a pass.

---

## 1. Environment

| Name | URL | Database | May we load-test? |
|---|---|---|---|
| Local JVM | `http://127.0.0.1:8080` | local or dedicated `host_bora_perf` | Yes, bounded |
| Stage Tomcat | `http://167.86.89.92:8082` | `host_bora_test` on **shared** SQL Server | Smoke only (≤5 VU, ≤30 s) with `ALLOW_SHARED_HOST=1` |
| Production | `https://hostbora.co.tz:8444` | `host_bora` | **No** |

Stage and prod are two Tomcat containers on **one VPS**, both using JDBC `167.86.89.92:1433` (`docker-compose.yml`, `application-stage.properties`, `application-prod.properties`). Heavy stage traffic contends with live traffic.

**k6 default target is localhost.** Scripts abort on the shared host unless `ALLOW_SHARED_HOST=1` and `VUS≤5`.

### Isolation requirements before Scenarios C–G

1. Separate VM or at least cgroup limits so prod Tomcat cannot starve.
2. Dedicated SQL Server (or a restored snapshot of `host_bora_test`) not used by customers.
3. Snippe, Beem SMS, SMTP, Apple IAP stubbed.
4. Synthetic users only. No real STK, no real phones.
5. Emergency stop: Ctrl-C k6; `docker stop hostbora-stage`; do **not** stop `hostbora-prod`.

---

## 2. Proposed SLOs (not approved release gates)

No product SLO document exists. Treat these as proposals until product/SRE sign off.

| Metric | Proposed |
|---|---|
| Availability | 99.5% / month (single-host reality) |
| `GET /api/health` p95 | < 400 ms (does not prove DB health today) |
| Authenticated read p95 | < 800 ms server-side |
| Authenticated read p99 | < 2 s |
| Error rate (5xx + timeout) | < 1% |
| Payment/booking duplicate rate | **0** |
| Subscription activate-once | **100%** of completed Snippe payments |
| OTP brute-force | lockout after 5 bad codes |

---

## 3. Workloads

Think time 1–3 s unless noted. Mix is **read-heavy**; mutating money paths are a separate correctness suite.

### Scenario A — Normal

- 5 VU, 10 min, `load.js`
- Mix: health 20%, home 30%, bookings 25%, properties 15%, payments 10%
- Token from a synthetic host account

### Scenario B — Viral page

- Spike `GET /api/health` and static `www.hostbora.co.tz` (CDN/nginx), `spike.js`
- Assert prod API p95 on a **separate** probe does not move. On the shared host this isolation **cannot** be proven.

### Scenario C — Sustained peak

- 10–20 VU, 30–60 min, `load.js`
- Journeys: login (OTP **mocked**), home, properties, record payment (**stub**), finances
- Watch heap, Hikari wait, Tomcat threads, SQL CPU

### Scenario D — Extreme concurrency

- `stress.js` ramping arrival rate on **local/isolated** only
- Record first resource to saturate (expected: Hikari default 10, then Tomcat, then SQL CPU)

### Scenario E — Spike

- `spike.js`: 5 → 40 VU in 10 s, hold 30 s, down
- Shared host: cap spike at 5 VU

### Scenario F — Soak

- `soak.js`, 5 VU, 2–8 h, isolated
- Watch RSS, GC, `offline_sync` not applicable server-side; watch Tomcat threads, Hikari active, disk logs (`show-sql=true`)

### Scenario G — Overload / abusive

- Config review + bounded 5 VU against public `/api/auth/reg` **on isolated** only
- **Do not** OTP-flood Beem or Snippe
- Assert: no rate limit exists today (expected fail)

### Business correctness (mandatory)

`correctness.js` plus JUnit (not yet added) must assert:

| Workflow | Pass means |
|---|---|
| Health | Body `status=UP` (today this is **static**, so also probe a DB-backed GET) |
| List bookings | HTTP 200 **and** unique ids in payload |
| Cash `POST /api/payments` twice | Second call returns the **same** id or 409 — not a second row |
| Booking create twice | No overlapping stay / no two rows for same idempotency key |
| Snippe webhook `payment.completed` replay | Subscription period extended **once** |
| Client amount vs plan | Session amount must match `PlanPricing` or be rejected |

Mutating checks require `ENABLE_MUTATING=1` and an isolated DB.

---

## 4. Risk controls

1. Discover target before run (`BASE_URL` printed by k6).
2. Shared-host guard in `k6/lib/config.js`.
3. No real Snippe/Beem/Apple.
4. Stop if prod error rate rises (manual: watch `hostbora-prod` logs).
5. Do not disable JWT, HMAC, or TLS to “go faster”.
6. Do not report unrun scenarios as executed.
7. Tokens via env only.

---

## 5. Tooling

| Tool | Use |
|---|---|
| k6 | HTTP load, spike, soak, correctness (`docs/performance/k6`) |
| JUnit | Webhook replay, payment uniqueness (to add next) |
| Tomcat access log + `RequestLoggingFilter` | Server-side ms |
| SQL Server DMVs | waits, missing indexes (isolated) |
| Flutter integration | Duplicate-tap payment on device |

k6 was **not installed** on the authoring machine (`k6 not found`, 2026-11-10). Scripts are ready; install with `brew install k6`.

---

## 6. Acceptance

Release **Ready** only if:

- Isolated Scenarios A, C, D, E, F executed with numbers in `performance-report.md`
- Duplicate payment/booking/subscription tests **pass**
- Proposed SLOs approved or replaced
- Stage/prod no longer share one unconstrained host **or** residual risk is written and accepted
