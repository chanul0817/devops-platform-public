#!/usr/bin/env sh
set -eu

resolve_env_file() {
  case "$1" in
    */*) printf '%s\n' "$1" ;;
    *) printf './%s\n' "$1" ;;
  esac
}

ENV_FILE="$(resolve_env_file "${ENV_FILE:-.env}")"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://localhost:${ALERTMANAGER_PORT:-9093}}"
ALERT_NAME="${1:-PortfolioTestAlert$(date +%Y%m%d%H%M%S)}"
SERVICE="${ALERT_SERVICE:-consulting-orders-api}"
SEVERITY="${ALERT_SEVERITY:-warning}"

cat <<EOF | curl -fsS -X POST "${ALERTMANAGER_URL}/api/v2/alerts" \
  -H 'Content-Type: application/json' \
  --data-binary @-
[
  {
    "labels": {
      "alertname": "${ALERT_NAME}",
      "service": "${SERVICE}",
      "severity": "${SEVERITY}"
    },
    "annotations": {
      "summary": "Portfolio alert channel test",
      "description": "This alert verifies that Alertmanager notification delivery works."
    }
  }
]
EOF

echo
echo "Test alert sent to: ${ALERTMANAGER_URL}"
