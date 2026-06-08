#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://localhost:8080}"
APP_METRICS_URL="${APP_METRICS_URL:-http://localhost:8081/actuator/prometheus}"
SMOKE_TEST_ATTEMPTS="${SMOKE_TEST_ATTEMPTS:-20}"
SMOKE_TEST_SLEEP_SECONDS="${SMOKE_TEST_SLEEP_SECONDS:-3}"

run_checks() {
  echo "Checking application health: ${BASE_URL}/api/health"
  curl -fsS "${BASE_URL}/api/health" >/dev/null

  echo "Checking order list: ${BASE_URL}/api/orders"
  curl -fsS "${BASE_URL}/api/orders" >/dev/null

  echo "Checking Prometheus metrics endpoint through direct app port"
  curl -fsS "${APP_METRICS_URL}" >/dev/null
}

attempt=1
while [ "$attempt" -le "$SMOKE_TEST_ATTEMPTS" ]; do
  if run_checks; then
    echo "Smoke test passed"
    exit 0
  fi

  if [ "$attempt" -lt "$SMOKE_TEST_ATTEMPTS" ]; then
    echo "Smoke test attempt ${attempt}/${SMOKE_TEST_ATTEMPTS} failed. Retrying in ${SMOKE_TEST_SLEEP_SECONDS}s."
    sleep "$SMOKE_TEST_SLEEP_SECONDS"
  fi

  attempt=$((attempt + 1))
done

echo "Smoke test failed after ${SMOKE_TEST_ATTEMPTS} attempts" >&2
exit 1
