#!/usr/bin/env sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

PROJECT_DIR="${PROJECT_DIR:-/opt/devops-consulting-springboot}"
SERVICE_NAME="${SERVICE_NAME:-devops-postgres-backup}"
BACKUP_SCHEDULE="${BACKUP_SCHEDULE:-*-*-* 03:00:00}"
BACKUP_RANDOMIZED_DELAY_SEC="${BACKUP_RANDOMIZED_DELAY_SEC:-10m}"
RUN_USER="${RUN_USER:-}"
RUN_GROUP="${RUN_GROUP:-}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}.timer"
ALERT_SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}-failure-alert.service"
SERVICE_TMP="$(mktemp)"
TIMER_TMP="$(mktemp)"
ALERT_SERVICE_TMP="$(mktemp)"
changed=false

cleanup() {
  rm -f "${SERVICE_TMP}" "${TIMER_TMP}" "${ALERT_SERVICE_TMP}"
}
trap cleanup EXIT INT TERM

if [ ! -d "${PROJECT_DIR}" ]; then
  echo "Project directory not found: ${PROJECT_DIR}" >&2
  exit 1
fi

if [ ! -x "${PROJECT_DIR}/ops/backup-postgres.sh" ]; then
  echo "Backup script is missing or not executable: ${PROJECT_DIR}/ops/backup-postgres.sh" >&2
  exit 1
fi

if [ ! -x "${PROJECT_DIR}/ops/notify-backup-failure.sh" ]; then
  echo "Backup failure notification script is missing or not executable: ${PROJECT_DIR}/ops/notify-backup-failure.sh" >&2
  exit 1
fi

if [ -z "${RUN_USER}" ]; then
  RUN_USER="$(stat -c '%U' "${PROJECT_DIR}")"
fi

if [ -z "${RUN_GROUP}" ]; then
  RUN_GROUP="$(stat -c '%G' "${PROJECT_DIR}")"
fi

cat > "${SERVICE_TMP}" <<EOF
[Unit]
Description=DevOps platform PostgreSQL backup
Wants=docker.service
After=docker.service
OnFailure=${SERVICE_NAME}-failure-alert.service

[Service]
Type=oneshot
User=${RUN_USER}
Group=${RUN_GROUP}
SupplementaryGroups=docker
WorkingDirectory=${PROJECT_DIR}
Environment=ENV_FILE=.env
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=${PROJECT_DIR}/ops/backup-postgres.sh
Nice=5
IOSchedulingClass=best-effort
EOF

cat > "${TIMER_TMP}" <<EOF
[Unit]
Description=Run DevOps platform PostgreSQL backup on schedule

[Timer]
OnCalendar=${BACKUP_SCHEDULE}
Persistent=true
RandomizedDelaySec=${BACKUP_RANDOMIZED_DELAY_SEC}

[Install]
WantedBy=timers.target
EOF

cat > "${ALERT_SERVICE_TMP}" <<EOF
[Unit]
Description=Send alert when DevOps platform PostgreSQL backup fails

[Service]
Type=oneshot
User=${RUN_USER}
Group=${RUN_GROUP}
WorkingDirectory=${PROJECT_DIR}
Environment=ENV_FILE=.env
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=${PROJECT_DIR}/ops/notify-backup-failure.sh ${SERVICE_NAME}.service
EOF

if ! cmp -s "${SERVICE_TMP}" "${SERVICE_FILE}" 2>/dev/null; then
  install -m 0644 "${SERVICE_TMP}" "${SERVICE_FILE}"
  changed=true
fi

if ! cmp -s "${ALERT_SERVICE_TMP}" "${ALERT_SERVICE_FILE}" 2>/dev/null; then
  install -m 0644 "${ALERT_SERVICE_TMP}" "${ALERT_SERVICE_FILE}"
  changed=true
fi

if ! cmp -s "${TIMER_TMP}" "${TIMER_FILE}" 2>/dev/null; then
  install -m 0644 "${TIMER_TMP}" "${TIMER_FILE}"
  changed=true
fi

if [ "${changed}" = "true" ]; then
  systemctl daemon-reload
fi

if ! systemctl is-enabled --quiet "${SERVICE_NAME}.timer"; then
  systemctl enable "${SERVICE_NAME}.timer"
  changed=true
fi

if ! systemctl is-active --quiet "${SERVICE_NAME}.timer"; then
  systemctl start "${SERVICE_NAME}.timer"
  changed=true
fi

echo "Installed timer: ${SERVICE_NAME}.timer"
echo "changed=${changed}"
systemctl list-timers "${SERVICE_NAME}.timer" --no-pager
