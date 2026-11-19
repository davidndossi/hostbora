import http from 'k6/http';
import { sleep } from 'k6';
import { assertSafeTarget, authHeaders, envNum, smokeThresholds, target } from './lib/config.js';
import { checkAuthList, checkHealth } from './lib/checks.js';

const BASE = target();
assertSafeTarget(BASE);

export const options = {
  vus: envNum('VUS', 1),
  duration: __ENV.DURATION || '30s',
  thresholds: smokeThresholds,
};

export default function () {
  const health = http.get(`${BASE}/api/health`, { tags: { name: 'health' } });
  checkHealth(health);

  const headers = authHeaders();
  if (headers.Authorization) {
    checkAuthList(http.get(`${BASE}/api/properties`, { headers, tags: { name: 'properties' } }), 'properties');
    checkAuthList(http.get(`${BASE}/api/bookings/list`, { headers, tags: { name: 'bookings' } }), 'bookings');
    checkAuthList(http.get(`${BASE}/api/payments`, { headers, tags: { name: 'payments' } }), 'payments');
  }
  sleep(1);
}
