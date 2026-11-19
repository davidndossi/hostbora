import http from 'k6/http';
import { sleep } from 'k6';
import { assertSafeTarget, envNum, smokeThresholds, target } from './lib/config.js';
import { checkHealth } from './lib/checks.js';

const BASE = target();
assertSafeTarget(BASE);

/** Scenario E — abrupt traffic on the public health/static path only. */
export const options = {
  scenarios: {
    spike: {
      executor: 'ramping-vus',
      stages: [
        { duration: '10s', target: envNum('VUS', 5) },
        { duration: '10s', target: envNum('SPIKE_VUS', 40) },
        { duration: '30s', target: envNum('SPIKE_VUS', 40) },
        { duration: '20s', target: envNum('VUS', 5) },
        { duration: '10s', target: 0 },
      ],
    },
  },
  thresholds: smokeThresholds,
};

export default function () {
  checkHealth(http.get(`${BASE}/api/health`, { tags: { name: 'health' } }));
  sleep(0.2);
}
