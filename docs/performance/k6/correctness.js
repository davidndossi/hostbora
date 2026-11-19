import http from 'k6/http';
import { check, sleep } from 'k6';
import { assertSafeTarget, authHeaders, envNum, target } from './lib/config.js';
import { checkHealth, checkNoDuplicateCreates, parseBody } from './lib/checks.js';

const BASE = target();
assertSafeTarget(BASE);

/**
 * Business correctness under concurrent load.
 * Mutating POSTs run only when ENABLE_MUTATING=1 against an isolated DB.
 * This script must fail if HTTP 200 hides duplicate payments or bookings.
 */
export const options = {
  scenarios: {
    concurrent_reads: {
      executor: 'constant-vus',
      vus: envNum('VUS', 5),
      duration: __ENV.DURATION || '2m',
      exec: 'reads',
    },
    duplicate_post: {
      executor: 'per-vu-iterations',
      vus: envNum('MUTATING_VUS', 1),
      iterations: 1,
      exec: 'duplicatePost',
      startTime: '5s',
    },
  },
  thresholds: {
    checks: ['rate>0.99'],
    http_req_failed: ['rate<0.05'],
  },
};

export function reads() {
  checkHealth(http.get(`${BASE}/api/health`, { tags: { name: 'health' } }));
  const headers = authHeaders();
  if (!headers.Authorization) {
    sleep(1);
    return;
  }
  const res = http.get(`${BASE}/api/bookings/list`, { headers, tags: { name: 'bookings' } });
  const body = parseBody(res);
  const list = Array.isArray(body) ? body : [];
  const ids = list.map((row) => String(row.id || ''));
  const unique = new Set(ids.filter(Boolean));
  check(res, {
    'bookings 200': (r) => r.status === 200,
    'booking ids unique in payload': () => unique.size === ids.filter(Boolean).length,
  });
  sleep(1);
}

export function duplicatePost() {
  if (__ENV.ENABLE_MUTATING !== '1') {
    check({ skipped: true }, { 'mutating tests skipped (set ENABLE_MUTATING=1)': () => true });
    return;
  }
  const headers = { ...authHeaders(), 'Content-Type': 'application/json' };
  if (!headers.Authorization) {
    check({ auth: false }, { 'TOKEN required for mutating correctness': () => false });
    return;
  }
  const key = `k6-correctness-${__VU}-${Date.now()}`;
  const today = new Date().toISOString().slice(0, 10);
  const payload = JSON.stringify({
    amount: 1,
    paymentMethod: 'Cash',
    status: 'PAID',
    paymentDate: today,
    idempotencyKey: key,
  });
  const keyedHeaders = { ...headers, 'Idempotency-Key': key };
  const first = http.post(`${BASE}/api/payments`, payload, { headers: keyedHeaders, tags: { name: 'pay1' } });
  const second = http.post(`${BASE}/api/payments`, payload, { headers: keyedHeaders, tags: { name: 'pay2' } });
  checkNoDuplicateCreates(first, second, 'cash payment');
}
