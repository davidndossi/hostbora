import http from 'k6/http';
import { sleep } from 'k6';
import { assertSafeTarget, authHeaders, envNum, proposedThresholds, target } from './lib/config.js';
import { checkAuthList, checkHealth } from './lib/checks.js';

const BASE = target();
assertSafeTarget(BASE);

/**
 * Scenario C — sustained mixed read load. Mutating payment/booking POSTs
 * are off unless ENABLE_MUTATING=1 (see correctness.js).
 */
export const options = {
  scenarios: {
    mixed_reads: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: envNum('VUS', 10) },
        { duration: __ENV.DURATION || '5m', target: envNum('VUS', 10) },
        { duration: '1m', target: 0 },
      ],
    },
  },
  thresholds: proposedThresholds,
};

export default function () {
  const headers = authHeaders();
  checkHealth(http.get(`${BASE}/api/health`, { tags: { name: 'health' } }));
  if (headers.Authorization) {
    const roll = Math.random();
    if (roll < 0.4) {
      checkAuthList(http.get(`${BASE}/api/home/overview`, { headers, tags: { name: 'home' } }), 'home');
    } else if (roll < 0.7) {
      checkAuthList(http.get(`${BASE}/api/bookings/list`, { headers, tags: { name: 'bookings' } }), 'bookings');
    } else if (roll < 0.9) {
      checkAuthList(http.get(`${BASE}/api/properties`, { headers, tags: { name: 'properties' } }), 'properties');
    } else {
      checkAuthList(http.get(`${BASE}/api/payments`, { headers, tags: { name: 'payments' } }), 'payments');
    }
  }
  sleep(envNum('THINK', 1));
}
