# Host Bora resilience test plan

**Status:** Design only. No chaos was injected into production or the shared Contabo VPS.  
**Rule:** rollback and emergency stop **before** any fault. Stop `hostbora-stage` only; never `hostbora-prod` during an experiment unless product has approved a maintenance window.

---

## 1. What we already know from config (not from injection)

| Component | Evidence | Failure mode |
|---|---|---|
| Single VPS | `docker-compose.yml` publishes 8082 and 8444 on one host | Host reboot / OOM takes stage **and** prod |
| Single SQL Server | both profiles JDBC `167.86.89.92:1433` | DB down → both apps fail; Hikari 30 s wait (default) |
| In-memory OTP | `RegistrationOtpStore`, `LoginOtpStore` | WAR redeploy drops pending OTP |
| Health | `HealthController` returns static UP | Load balancer / ops cannot detect DB death |
| Shared `.env` | compose `env_file: .env` on both services | Bad secret hits both profiles |
| Snippe webhook URL default | prod `:8444/api/webhooks/snippe` | Stage-created payments may credit **prod** |
| No circuit breaker | no Resilience4j | Beem/Snippe hang holds Tomcat + DB connections |
| Scheduler pool 1000 | `spring.task.scheduling.pool.size=1000` | Two replicas would double-send SMS |
| autoDeploy | `server-*.xml` | Partial WAR copy can bounce the JVM mid-request |

---

## 2. Emergency stop (mandatory before injection)

1. Abort k6 (`Ctrl-C`).
2. `docker stop hostbora-stage` if stage is the subject.
3. Do **not** stop nginx or SQL Server if prod is serving.
4. Confirm `curl https://hostbora.co.tz:8444/api/health` still 200.
5. Restore any dropped test DB only from snapshot, never from prod backup onto prod.

Rollback: `docker start hostbora-stage`; if WAR is corrupt, recopy last known `ROOT.war` and remove exploded `ROOT/`.

---

## 3. Experiments (isolated environment)

Each experiment: detect → safe error → no hang > timeout → resources released → data consistent → recover.

| ID | Fault | How | Expect | Pass |
|---|---|---|---|---|
| R1 | Kill stage Tomcat mid-request | `docker restart hostbora-stage` | In-flight OTP lost; health 502 then UP; **prod unaffected** | Prod p95 unchanged; no duplicate prod payments |
| R2 | SQL Server stop (isolated instance only) | stop SQL | API hang up to Hikari 30 s then 500; health still UP (gap) | After start, committed rows remain; no half-bookings |
| R3 | 300 ms + 1% loss to API | `tc` / proxy | Client 10 s `.timeout` abandons Future; Dio still waits 60 s | UI shows local SQLite; no duplicate local+server payment after retry |
| R4 | Snippe 15–45 s delay then 200 | stub | `@Transactional` holds DB connection | Pool does not exhaust; payment row not rolled back after Snippe success |
| R5 | Snippe timeout after accept | stub | `callAndPersist` marks failed / rolls back | Webhook later still credits **once** |
| R6 | Replay webhook `payment.completed` | signed test event twice | Today: likely **extends subscription twice** | After fix: second event no-ops |
| R7 | Heap pressure | lower `-Xmx` on stage only | OOM kill, `restart: always` | Prod heap untouched; stage comes back |
| R8 | Disk fill (logs) | isolated volume | `show-sql` + DEBUG web logs grow fast | App fails closed; no silent corruption |
| R9 | Drop in-memory OTP | restart during `/reg` | User exists unverified; retry “already exists” | Documented; later: persist OTP |
| R10 | Queue row `in_progress` | kill Flutter mid-sync | Row stuck; UI pending forever | After fix: reclaim `in_progress` older than N minutes |
| R11 | Expired JWT | 90-day token still valid | Session almost never expires | Separate product decision |
| R12 | Public `/api/dev/*` | unauthenticated call | SMS/Snippe can fire | 404/401 in prod profile |

**R2, R4–R8 must not run on 167.86.89.92.**

---

## 4. Recovery validation checklist

For every experiment record:

1. Failure detected? (today health will lie for R2)
2. Errors bounded (no infinite spinner / no 60 s×N stacked Dio)?
3. User message?
4. Connections returned to Hikari?
5. Retries bounded and **idempotent**?
6. Row counts before/after for payments, bookings, subscriptions, commission?
7. Alert fired? (today: **no** metrics/alerts)
8. Time to recover (seconds)?
9. Prod error rate during the experiment?

---

## 5. Observability gaps that block chaos

- No Actuator/micrometer despite `/actuator/health` being permitted.
- Health does not ping SQL Server.
- No Prometheus, tracing, or paging.
- DEBUG + `show-sql` in prod/stage will drown the disk under load.

Minimum before chaos on a dedicated box: Actuator health with DB, Hikari metrics, Tomcat thread count, disk watermark, and an alert on 5xx rate.
