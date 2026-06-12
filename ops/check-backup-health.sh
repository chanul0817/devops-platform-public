#!/usr/bin/env sh
set -eu

resolve_env_file() {
  case "$1" in
    */*) printf '%s\n' "$1" ;;
    *) printf './%s\n' "$1" ;;
  esac
}

is_enabled() {
  case "$1" in
    true|TRUE|yes|YES|1) return 0 ;;
    *) return 1 ;;
  esac
}

ENV_FILE="$(resolve_env_file "${ENV_FILE:-.env}")"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

BACKUP_REMOTE_ENABLED="${BACKUP_REMOTE_ENABLED:-false}"
BACKUP_REMOTE_HOST="${BACKUP_REMOTE_HOST:-}"
BACKUP_REMOTE_USER="${BACKUP_REMOTE_USER:-}"
BACKUP_REMOTE_PORT="${BACKUP_REMOTE_PORT:-22}"
BACKUP_REMOTE_DIR="${BACKUP_REMOTE_DIR:-}"
BACKUP_REMOTE_SSH_KEY="${BACKUP_REMOTE_SSH_KEY:-}"
BACKUP_REMOTE_STRICT_HOST_KEY_CHECKING="${BACKUP_REMOTE_STRICT_HOST_KEY_CHECKING:-yes}"
FILE_BACKUP_SOURCE_DIR="${FILE_BACKUP_SOURCE_DIR:-}"

SENTINEL_FILE=""

if [ -n "$FILE_BACKUP_SOURCE_DIR" ]; then
  mkdir -p "$FILE_BACKUP_SOURCE_DIR"
  SENTINEL_FILE="${FILE_BACKUP_SOURCE_DIR}/.backup-healthcheck"
  {
    printf 'checked_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'host=%s\n' "$(hostname 2>/dev/null || printf 'unknown')"
  } > "$SENTINEL_FILE"
  echo "File backup sentinel written: ${SENTINEL_FILE}"
fi

BACKUP_OUTPUT="$(./ops/backup-postgres.sh 2>&1)" || {
  printf '%s\n' "$BACKUP_OUTPUT" >&2
  exit 1
}

printf '%s\n' "$BACKUP_OUTPUT"

BACKUP_FILE="$(printf '%s\n' "$BACKUP_OUTPUT" | awk -F': ' '/^Backup created: / {print $2}' | tail -n 1)"

if [ -z "$BACKUP_FILE" ] || [ ! -s "$BACKUP_FILE" ]; then
  echo "Local backup health check failed: backup file is missing or empty." >&2
  exit 1
fi

echo "Local database backup verified: ${BACKUP_FILE}"

if is_enabled "$BACKUP_REMOTE_ENABLED"; then
  if [ -z "$BACKUP_REMOTE_HOST" ] || [ -z "$BACKUP_REMOTE_USER" ] || [ -z "$BACKUP_REMOTE_DIR" ]; then
    echo "Remote backup health check failed: remote settings are incomplete." >&2
    exit 1
  fi

  SSH_OPTS="-p ${BACKUP_REMOTE_PORT} -o StrictHostKeyChecking=${BACKUP_REMOTE_STRICT_HOST_KEY_CHECKING}"

  if [ -n "$BACKUP_REMOTE_SSH_KEY" ]; then
    if [ ! -f "$BACKUP_REMOTE_SSH_KEY" ]; then
      echo "Remote backup SSH key not found: ${BACKUP_REMOTE_SSH_KEY}" >&2
      exit 1
    fi
    SSH_OPTS="${SSH_OPTS} -i ${BACKUP_REMOTE_SSH_KEY}"
  fi

  REMOTE="${BACKUP_REMOTE_USER}@${BACKUP_REMOTE_HOST}"
  REMOTE_DB_FILE="${BACKUP_REMOTE_DIR}/db/$(basename "$BACKUP_FILE")"

  ssh ${SSH_OPTS} "$REMOTE" "test -s '${REMOTE_DB_FILE}'"
  echo "Remote database backup verified: ${REMOTE}:${REMOTE_DB_FILE}"

  if [ -n "$SENTINEL_FILE" ]; then
    REMOTE_SENTINEL="${BACKUP_REMOTE_DIR}/files/current/.backup-healthcheck"
    ssh ${SSH_OPTS} "$REMOTE" "test -s '${REMOTE_SENTINEL}'"
    echo "Remote file backup verified: ${REMOTE}:${REMOTE_SENTINEL}"
  fi
fi

echo "Backup health check passed"
