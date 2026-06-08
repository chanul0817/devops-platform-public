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
  echo "Usage: $0 [--force] <backup-file.sql>" >&2
  echo "Set CONFIRM_RESTORE=yes instead of --force for non-interactive runs." >&2
}

FORCE=false
if [ "${1:-}" = "--force" ]; then
  FORCE=true
  shift
fi

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DB_NAME="${POSTGRES_DB:-orders}"
DB_USER="${POSTGRES_USER:-orders}"
DB_SCHEMA="${POSTGRES_SCHEMA:-public}"
POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
APP_SERVICE="${APP_SERVICE:-app}"
BACKUP_FILE="$1"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PRE_RESTORE_BACKUP="${BACKUP_DIR}/${DB_NAME}_pre_restore_${TIMESTAMP}.sql"
PRE_RESTORE_TMP="${PRE_RESTORE_BACKUP}.tmp"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "Backup file not found: ${BACKUP_FILE}" >&2
  exit 1
fi

if [ ! -s "${BACKUP_FILE}" ]; then
  echo "Backup file is empty: ${BACKUP_FILE}" >&2
  exit 1
fi

case "${DB_SCHEMA}" in
  ""|*[!A-Za-z0-9_]*)
    echo "Invalid schema name: ${DB_SCHEMA}" >&2
    exit 1
    ;;
esac

if [ "${FORCE}" != "true" ] && [ "${CONFIRM_RESTORE:-}" != "yes" ]; then
  echo "Restore is destructive: it stops '${APP_SERVICE}', creates a safety backup, resets schema '${DB_SCHEMA}', and restores '${BACKUP_FILE}'." >&2
  echo "Re-run with --force or CONFIRM_RESTORE=yes when approved." >&2
  exit 1
fi

cleanup() {
  rm -f "${PRE_RESTORE_TMP}"
}
trap cleanup EXIT INT TERM

mkdir -p "${BACKUP_DIR}"

echo "Creating pre-restore safety backup: ${PRE_RESTORE_BACKUP}"
docker compose -f "${COMPOSE_FILE}" exec -T "${POSTGRES_SERVICE}" \
  pg_dump \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    -U "${DB_USER}" \
    "${DB_NAME}" > "${PRE_RESTORE_TMP}"

if [ ! -s "${PRE_RESTORE_TMP}" ]; then
  echo "Pre-restore backup failed: empty dump file was created." >&2
  exit 1
fi

mv "${PRE_RESTORE_TMP}" "${PRE_RESTORE_BACKUP}"

echo "Stopping application service before restore: ${APP_SERVICE}"
docker compose -f "${COMPOSE_FILE}" stop "${APP_SERVICE}"

echo "Resetting database schema: ${DB_SCHEMA}"
docker compose -f "${COMPOSE_FILE}" exec -T "${POSTGRES_SERVICE}" \
  psql -v ON_ERROR_STOP=1 -U "${DB_USER}" -d "${DB_NAME}" <<SQL
DROP SCHEMA IF EXISTS ${DB_SCHEMA} CASCADE;
CREATE SCHEMA ${DB_SCHEMA} AUTHORIZATION ${DB_USER};
GRANT ALL ON SCHEMA ${DB_SCHEMA} TO ${DB_USER};
GRANT ALL ON SCHEMA ${DB_SCHEMA} TO public;
SQL

echo "Restoring from backup: ${BACKUP_FILE}"
docker compose -f "${COMPOSE_FILE}" exec -T "${POSTGRES_SERVICE}" \
  psql -v ON_ERROR_STOP=1 -U "${DB_USER}" -d "${DB_NAME}" < "${BACKUP_FILE}"

TABLE_COUNT="$(docker compose -f "${COMPOSE_FILE}" exec -T "${POSTGRES_SERVICE}" \
  psql -U "${DB_USER}" -d "${DB_NAME}" -tAc \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema = '${DB_SCHEMA}';")"

echo "Starting application service after restore: ${APP_SERVICE}"
docker compose -f "${COMPOSE_FILE}" up -d "${APP_SERVICE}"

echo "Restore completed from: ${BACKUP_FILE}"
echo "Pre-restore safety backup: ${PRE_RESTORE_BACKUP}"
echo "Restored table count in schema '${DB_SCHEMA}': ${TABLE_COUNT}"
