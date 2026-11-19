# Host Bora k6 suites

Reusable load, spike, stress, soak, and **business-correctness** scripts.

## Safety

Stage (`http://167.86.89.92:8082`) and production (`https://hostbora.co.tz:8444`) run on **the same VPS and the same SQL Server**. Scripts refuse those hosts unless `ALLOW_SHARED_HOST=1` and `VUS≤5`.

Default target is `http://127.0.0.1:8080`.

Do not enable `ENABLE_MUTATING=1` against a database that holds real money.

Do not call Snippe, Beem SMS, or Apple IAP from these scripts.

## Install

```bash
brew install k6   # macOS (isolated load generator — not on the Contabo VPS)
k6 version        # verified 2026-11-10: k6 v2.3.0 darwin/arm64
```

## Run

```bash
cd docs/performance/k6

k6 run smoke.js
BASE_URL=http://127.0.0.1:8080 TOKEN="$HB_TOKEN" k6 run load.js
DURATION=2h VUS=5 k6 run soak.js
k6 run spike.js
k6 run stress.js
TOKEN="$HB_TOKEN" k6 run correctness.js
ENABLE_MUTATING=1 TOKEN="$HB_TOKEN" k6 run correctness.js   # isolated DB only
```

Shared-host smoke (max 5 VUs):

```bash
BASE_URL=http://167.86.89.92:8082 ALLOW_SHARED_HOST=1 VUS=3 DURATION=20s k6 run smoke.js
```

## Env

| Variable | Default | Meaning |
|---|---|---|
| `BASE_URL` | `http://127.0.0.1:8080` | API origin |
| `TOKEN` / `HB_TOKEN` | empty | JWT for authenticated reads |
| `VUS` | per script | Virtual users |
| `DURATION` | per script | Hold time |
| `ALLOW_SHARED_HOST` | unset | Required to touch 167.86.89.92 / hostbora.co.tz |
| `ENABLE_MUTATING` | unset | Allows duplicate-POST correctness checks |
| `THINK` | 1–2 s | Sleep between iterations |

`TOKEN` is never logged by these scripts. Do not commit tokens.
