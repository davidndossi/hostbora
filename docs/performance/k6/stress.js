import http from 'k6/http';
import { sleep } from 'k6';
import { assertSafeTarget, authHeaders, envNum, target } from './lib/config.js';
import { checkAuthList, checkHealth } from './lib/checks.js';

const BASE = target();
assertSafeTarget(BASE);

/**
 * Scenario D — find saturation. Stop when error rate or p95 explodes.
 * Do not run against the shared Contabo host.
 */
export const options = {
  scenarios: {
    stress: {
      executor: 'ramping-arrival-rate',
      startRate: envNum('START_RATE', 2),
      timeUnit: '1s',
      preAllocatedVUs: envNum('PREALLOC', 20),
      maxVUs: envNum('MAX_VUS', 50),
      stages: [
        { duration: '1m', target: envNum('START_RATE', 2) },
        { duration: '2m', target: envNum('PEAK_RATE', 20) },
        { duration: '2m', target: envNum('PEAK_RATE', 20) },
        { duration: '1m', target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<3000'],
  },
};

export default function () {
  checkHealth(http.get(`${BASE}/api/health`, { tags: { name: 'health' } }));
  const headers = authHeaders();
  if (headers.Authorization) {
    checkAuthList(http.get(`${BASE}/api/bookings/list`, { headers, tags: { name: 'bookings' } }), 'bookings');
  }
  sleep(0.1);
}
