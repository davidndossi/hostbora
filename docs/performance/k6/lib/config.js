/**
 * Shared k6 config. Defaults to a local JVM so scripts cannot silently
 * hammer the Contabo VPS that runs both stage (8082) and prod (8444).
 *
 *   k6 run smoke.js
 *   BASE_URL=http://127.0.0.1:8080 TOKEN=... k6 run load.js
 *   BASE_URL=http://167.86.89.92:8082 ALLOW_SHARED_HOST=1 VUS=3 k6 run smoke.js
 */
export function envNum(name, fallback) {
  const raw = __ENV[name];
  if (raw === undefined || raw === '') return fallback;
  const n = Number(raw);
  return Number.isFinite(n) ? n : fallback;
}

export function target() {
  return (__ENV.BASE_URL || 'http://127.0.0.1:8080').replace(/\/$/, '');
}

export function token() {
  return (__ENV.TOKEN || __ENV.HB_TOKEN || '').trim();
}

export function assertSafeTarget(url) {
  const shared = /167\.86\.89\.92|hostbora\.co\.tz/i.test(url);
  if (!shared) return;
  if (__ENV.ALLOW_SHARED_HOST !== '1') {
    throw new Error(
      `Refusing ${url}: stage and prod share that host. ` +
        'Re-run with ALLOW_SHARED_HOST=1 and keep VUs ≤ 5, or point BASE_URL at localhost.',
    );
  }
  const vus = Math.max(
    envNum('VUS', envNum('vus', 1)),
    envNum('MAX_VUS', 0),
    envNum('PREALLOC', 0),
    envNum('SPIKE_VUS', 0),
  );
  if (vus > 5) {
    throw new Error(`Shared host VU cap is 5; got VUS/MAX_VUS/PREALLOC/SPIKE_VUS=${vus}`);
  }
  const peak = envNum('PEAK_RATE', 0);
  if (peak > 8) {
    throw new Error(`Shared host PEAK_RATE cap is 8; got ${peak}`);
  }
}

export function authHeaders() {
  const t = token();
  const h = { Accept: 'application/json' };
  if (t) h.Authorization = t.startsWith('Bearer ') ? t : `Bearer ${t}`;
  return h;
}

/** Proposed SLOs — not approved release gates. */
export const proposedThresholds = {
  http_req_failed: ['rate<0.01'],
  http_req_duration: ['p(95)<800', 'p(99)<2000'],
};

export const smokeThresholds = {
  http_req_failed: ['rate<0.05'],
  http_req_duration: ['p(95)<2000'],
};
