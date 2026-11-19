import http from 'k6/http';
import { sleep } from 'k6';
import { assertSafeTarget, authHeaders, envNum, proposedThresholds, target } from './lib/config.js';
import { checkAuthList, checkHealth } from './lib/checks.js';

const BASE = target();
assertSafeTarget(BASE);

/** Scenario F — constant load. Watch latency drift and error rate over hours. */
export const options = {
  scenarios: {
    soak: {
      executor: 'constant-vus',
      vus: envNum('VUS', 5),
      duration: __ENV.DURATION || '30m',
    },
  },
  thresholds: proposedThresholds,
};

export default function () {
  checkHealth(http.get(`${BASE}/api/health`, { tags: { name: 'health' } }));
  const headers = authHeaders();
  if (headers.Authorization) {
    checkAuthList(http.get(`${BASE}/api/home/overview`, { headers, tags: { name: 'home' } }), 'home');
    checkAuthList(http.get(`${BASE}/api/payments`, { headers, tags: { name: 'payments' } }), 'payments');
  }
  sleep(envNum('THINK', 2));
}
