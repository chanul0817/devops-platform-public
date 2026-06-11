#!/usr/bin/env sh
set -eu

ENV_FILE="${ENV_FILE:-.env}"
case "${ENV_FILE}" in
  */*) ENV_PATH="${ENV_FILE}" ;;
  *) ENV_PATH="./${ENV_FILE}" ;;
esac

if [ -f "${ENV_PATH}" ]; then
  set -a
  . "${ENV_PATH}"
  set +a
fi

usage() {
  echo "Usage: $0 [--force]" >&2
  echo "Set CONFIRM_RESTORE_REHEARSAL=yes instead of --force for non-interactive runs." >&2
}

FORCE=false
if [ "${1:-}" = "--force" ]; then
  FORCE=true
  shift
fi

if [ "$#" -ne 0 ]; then
  usage
  exit 1
fi

if [ "${FORCE}" != "true" ] && [ "${CONFIRM_RESTORE_REHEARSAL:-}" != "yes" ]; then
  echo "Restore rehearsal is disruptive: it creates a backup, inserts a marker record, restores the backup, and restarts the app." >&2
  echo "Run with --force or CONFIRM_RESTORE_REHEARSAL=yes when approved." >&2
  exit 1
fi

HTTP_PORT="${HTTP_PORT:-8080}"
APP_BASE_URL="${APP_BASE_URL:-http://localhost:${HTTP_PORT}}"
MARKER="restore-rehearsal-$(date +%Y%m%d%H%M%S)"

if [ ! -x ./ops/backup-postgres.sh ]; then
  echo "Backup script is missing or not executable: ./ops/backup-postgres.sh" >&2
  exit 1
fi

if [ ! -x ./ops/restore-postgres.sh ]; then
  echo "Restore script is missing or not executable: ./ops/restore-postgres.sh" >&2
  exit 1
fi

if [ ! -x ./ops/smoke-test.sh ]; then
  echo "Smoke test script is missing or not executable: ./ops/smoke-test.sh" >&2
  exit 1
fi

echo "Creating restore rehearsal checkpoint backup"
BACKUP_OUTPUT="$(./ops/backup-postgres.sh)"
printf '%s\n' "${BACKUP_OUTPUT}"
BACKUP_FILE="$(printf '%s\n' "${BACKUP_OUTPUT}" | sed -n 's/^Backup created: //p' | tail -n 1)"

if [ -z "${BACKUP_FILE}" ] || [ ! -s "${BACKUP_FILE}" ]; then
  echo "Could not find a valid backup file from backup output." >&2
  exit 1
fi

echo "Inserting marker order: ${MARKER}"
curl -fsS -X POST "${APP_BASE_URL}/api/orders" \
  -H 'Content-Type: application/json' \
  -d "{\"customerName\":\"restore-rehearsal\",\"productName\":\"${MARKER}\",\"quantity\":1}" >/dev/null

if ! curl -fsS "${APP_BASE_URL}/api/orders" | grep -q "${MARKER}"; then
  echo "Marker order was not visible before restore: ${MARKER}" >&2
  exit 1
fi

echo "Restoring checkpoint backup: ${BACKUP_FILE}"
CONFIRM_RESTORE=yes ./ops/restore-postgres.sh "${BACKUP_FILE}"

echo "Running smoke test after restore"
./ops/smoke-test.sh

if curl -fsS "${APP_BASE_URL}/api/orders" | grep -q "${MARKER}"; then
  echo "Restore rehearsal failed: marker order is still present after restore: ${MARKER}" >&2
  exit 1
fi

echo "Restore rehearsal passed"
echo "Checkpoint backup: ${BACKUP_FILE}"
echo "Removed marker: ${MARKER}"
