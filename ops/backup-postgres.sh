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

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
BACKUP_SYNC_DIR="${BACKUP_SYNC_DIR:-}"
DB_NAME="${POSTGRES_DB:-orders}"
DB_USER="${POSTGRES_USER:-orders}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"
TMP_FILE="${BACKUP_FILE}.tmp"

mkdir -p "${BACKUP_DIR}"

case "${BACKUP_RETENTION_DAYS}" in
  ""|*[!0-9]*)
    echo "Invalid BACKUP_RETENTION_DAYS: ${BACKUP_RETENTION_DAYS}" >&2
    exit 1
    ;;
esac

cleanup() {
  rm -f "${TMP_FILE}"
}
trap cleanup EXIT INT TERM

docker compose -f "${COMPOSE_FILE}" exec -T postgres \
  pg_dump \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    -U "${DB_USER}" \
    "${DB_NAME}" > "${TMP_FILE}"

if [ ! -s "${TMP_FILE}" ]; then
  echo "Backup failed: empty dump file was created." >&2
  exit 1
fi

mv "${TMP_FILE}" "${BACKUP_FILE}"
trap - EXIT INT TERM

find "${BACKUP_DIR}" -type f -name "${DB_NAME}_*.sql" -mtime "+${BACKUP_RETENTION_DAYS}" -print -delete

if [ -n "${BACKUP_SYNC_DIR}" ]; then
  mkdir -p "${BACKUP_SYNC_DIR}"
  cp -p "${BACKUP_FILE}" "${BACKUP_SYNC_DIR}/"
  find "${BACKUP_SYNC_DIR}" -type f -name "${DB_NAME}_*.sql" -mtime "+${BACKUP_RETENTION_DAYS}" -print -delete
  echo "Backup synced: ${BACKUP_SYNC_DIR}/$(basename "${BACKUP_FILE}")"
fi

echo "Backup created: ${BACKUP_FILE}"
echo "Retention applied: ${BACKUP_RETENTION_DAYS} days"
