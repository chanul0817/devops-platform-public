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

require_value() {
  name="$1"
  value="$2"

  if [ -z "$value" ]; then
    echo "Missing required remote backup setting: ${name}" >&2
    exit 1
  fi
}

ENV_FILE="$(resolve_env_file "${ENV_FILE:-.env}")"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

BACKUP_REMOTE_ENABLED="${BACKUP_REMOTE_ENABLED:-false}"

if ! is_enabled "$BACKUP_REMOTE_ENABLED"; then
  echo "Remote backup sync skipped: BACKUP_REMOTE_ENABLED=${BACKUP_REMOTE_ENABLED}"
  exit 0
fi

BACKUP_FILE="${1:-${BACKUP_FILE:-}}"
BACKUP_REMOTE_HOST="${BACKUP_REMOTE_HOST:-}"
BACKUP_REMOTE_USER="${BACKUP_REMOTE_USER:-}"
BACKUP_REMOTE_PORT="${BACKUP_REMOTE_PORT:-22}"
BACKUP_REMOTE_DIR="${BACKUP_REMOTE_DIR:-}"
BACKUP_REMOTE_SSH_KEY="${BACKUP_REMOTE_SSH_KEY:-}"
BACKUP_REMOTE_STRICT_HOST_KEY_CHECKING="${BACKUP_REMOTE_STRICT_HOST_KEY_CHECKING:-yes}"
BACKUP_REMOTE_RSYNC_DELETE="${BACKUP_REMOTE_RSYNC_DELETE:-false}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
FILE_BACKUP_SOURCE_DIR="${FILE_BACKUP_SOURCE_DIR:-}"

require_value BACKUP_FILE "$BACKUP_FILE"
require_value BACKUP_REMOTE_HOST "$BACKUP_REMOTE_HOST"
require_value BACKUP_REMOTE_USER "$BACKUP_REMOTE_USER"
require_value BACKUP_REMOTE_DIR "$BACKUP_REMOTE_DIR"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: ${BACKUP_FILE}" >&2
  exit 1
fi

case "$BACKUP_RETENTION_DAYS" in
  ""|*[!0-9]*)
    echo "Invalid BACKUP_RETENTION_DAYS: ${BACKUP_RETENTION_DAYS}" >&2
    exit 1
    ;;
esac

SSH_OPTS="-p ${BACKUP_REMOTE_PORT} -o StrictHostKeyChecking=${BACKUP_REMOTE_STRICT_HOST_KEY_CHECKING}"

if [ -n "$BACKUP_REMOTE_SSH_KEY" ]; then
  if [ ! -f "$BACKUP_REMOTE_SSH_KEY" ]; then
    echo "Remote backup SSH key not found: ${BACKUP_REMOTE_SSH_KEY}" >&2
    exit 1
  fi
  SSH_OPTS="${SSH_OPTS} -i ${BACKUP_REMOTE_SSH_KEY}"
fi

REMOTE="${BACKUP_REMOTE_USER}@${BACKUP_REMOTE_HOST}"
RSYNC_DELETE_FLAG=""

if is_enabled "$BACKUP_REMOTE_RSYNC_DELETE"; then
  RSYNC_DELETE_FLAG="--delete"
fi

ssh ${SSH_OPTS} "$REMOTE" "mkdir -p '${BACKUP_REMOTE_DIR}/db' '${BACKUP_REMOTE_DIR}/files/current'"

rsync -az -e "ssh ${SSH_OPTS}" "$BACKUP_FILE" "${REMOTE}:${BACKUP_REMOTE_DIR}/db/"
echo "Database backup synced to ${REMOTE}:${BACKUP_REMOTE_DIR}/db/$(basename "$BACKUP_FILE")"

ssh ${SSH_OPTS} "$REMOTE" "find '${BACKUP_REMOTE_DIR}/db' -type f -name '*.sql' -mtime '+${BACKUP_RETENTION_DAYS}' -print -delete"
echo "Remote database backup retention applied: ${BACKUP_RETENTION_DAYS} days"

if [ -n "$FILE_BACKUP_SOURCE_DIR" ]; then
  if [ -d "$FILE_BACKUP_SOURCE_DIR" ]; then
    rsync -az ${RSYNC_DELETE_FLAG} -e "ssh ${SSH_OPTS}" "${FILE_BACKUP_SOURCE_DIR}/" "${REMOTE}:${BACKUP_REMOTE_DIR}/files/current/"
    echo "File backup synced to ${REMOTE}:${BACKUP_REMOTE_DIR}/files/current/"
  else
    echo "File backup source directory does not exist, skipping: ${FILE_BACKUP_SOURCE_DIR}" >&2
  fi
fi
