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
FAILED_UNIT="${1:-devops-postgres-backup.service}"
SERVICE="${ALERT_SERVICE:-backup}"
SEVERITY="${ALERT_SEVERITY:-critical}"
HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown')"
STARTS_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat <<EOF | curl -fsS -X POST "${ALERTMANAGER_URL}/api/v2/alerts" \
  -H 'Content-Type: application/json' \
  --data-binary @- >/dev/null || {
    echo "Failed to notify Alertmanager: ${ALERTMANAGER_URL}" >&2
    exit 0
  }
[
  {
    "labels": {
      "alertname": "PostgreSQLBackupFailed",
      "service": "${SERVICE}",
      "severity": "${SEVERITY}",
      "instance": "${HOSTNAME_VALUE}",
      "failed_unit": "${FAILED_UNIT}"
    },
    "annotations": {
      "summary": "PostgreSQL backup failed",
      "description": "Scheduled PostgreSQL backup failed on ${HOSTNAME_VALUE}. Check journalctl -u ${FAILED_UNIT}."
    },
    "startsAt": "${STARTS_AT}"
  }
]
EOF

echo "Backup failure alert sent to: ${ALERTMANAGER_URL}"
