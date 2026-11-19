import { check } from 'k6';

export function isJson(res) {
  const ct = (res.headers['Content-Type'] || res.headers['content-type'] || '');
  return ct.indexOf('json') !== -1;
}

export function parseBody(res) {
  try {
    return res.json();
  } catch (_) {
    return null;
  }
}

/** Health must be UP. A 200 with a wrong body is a correctness failure. */
export function checkHealth(res) {
  const body = parseBody(res);
  return check(res, {
    'health status 200': (r) => r.status === 200,
    'health JSON UP': () => body && body.status === 'UP',
    'health names service': () => body && body.service === 'host-bora-service',
  });
}

export function checkAuthList(res, name) {
  const body = parseBody(res);
  const okStatus = check(res, {
    [`${name} 200 or 401`]: (r) => r.status === 200 || r.status === 401 || r.status === 403,
  });
  if (res.status !== 200) return okStatus;
  const list = Array.isArray(body) ? body : body && (body.content || body.items || body.data);
  const ids = Array.isArray(list)
    ? list.map((row) => String(row && (row.id || row.bookingId || row.paymentId) || ''))
    : [];
  const unique = new Set(ids.filter(Boolean));
  return (
    okStatus &&
    check(res, {
      [`${name} JSON`]: () => body !== null,
      [`${name} no duplicate ids`]: () => unique.size === ids.filter(Boolean).length,
    })
  );
}

/**
 * Two identical POSTs that both return 2xx with different ids are a
 * business-correctness failure (duplicate money/booking records).
 */
function entityId(body) {
  if (!body || typeof body !== 'object') return null;
  const nested = body.data && typeof body.data === 'object' ? body.data : {};
  return (
    body.id ||
    body.paymentId ||
    body.bookingId ||
    nested.id ||
    nested.paymentId ||
    nested.bookingId ||
    null
  );
}

export function checkNoDuplicateCreates(first, second, label) {
  const a = parseBody(first);
  const b = parseBody(second);
  const idA = entityId(a);
  const idB = entityId(b);
  const bothCreated = first.status >= 200 && first.status < 300 && second.status >= 200 && second.status < 300;
  return check(
    { first, second },
    {
      [`${label} first accepted or rejected`]: () => first.status > 0,
      [`${label} retry is idempotent`]: () => {
        if (!bothCreated) return true;
        if (!idA || !idB) return false;
        return String(idA) === String(idB);
      },
    },
  );
}
