#!/usr/bin/env sh
set -eu

resolve_env_file() {
  case "$1" in
    */*) printf '%s\n' "$1" ;;
    *) printf './%s\n' "$1" ;;
  esac
}

discord_slack_url() {
  url="$1"
  case "$url" in
    */slack) printf '%s\n' "$url" ;;
    *) printf '%s/slack\n' "$url" ;;
  esac
}

write_local_receiver() {
  cat <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: local-webhook
  group_by:
    - alertname
    - service
  group_wait: 15s
  group_interval: 1m
  repeat_interval: 3h

receivers:
  - name: local-webhook
    webhook_configs:
      - url: ${ALERT_LOCAL_WEBHOOK_URL:-http://host.docker.internal:9099/alerts}
        send_resolved: true
EOF
}

write_slack_receiver() {
  provider="$1"
  webhook_url="$2"
  channel="${ALERT_SLACK_CHANNEL:-#alerts}"

  cat <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: ${provider}-webhook
  group_by:
    - alertname
    - service
  group_wait: 15s
  group_interval: 1m
  repeat_interval: 3h

receivers:
  - name: ${provider}-webhook
    slack_configs:
      - api_url: '${webhook_url}'
        channel: '${channel}'
        username: 'Alertmanager'
        send_resolved: true
        title: '{{ .Status | toUpper }} {{ .CommonLabels.alertname }}'
        text: |-
          {{ range .Alerts }}
          *Service:* {{ .Labels.service }}
          *Severity:* {{ .Labels.severity }}
          *Summary:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          {{ end }}
EOF
}

ENV_FILE="$(resolve_env_file "${ENV_FILE:-.env}")"
CONFIG_FILE="${ALERTMANAGER_CONFIG_FILE:-alertmanager/alertmanager.yml}"
TMP_FILE="${CONFIG_FILE}.tmp.$$"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi

mkdir -p "$(dirname "$CONFIG_FILE")"

if [ -n "${ALERT_DISCORD_WEBHOOK_URL:-}" ]; then
  write_slack_receiver "discord" "$(discord_slack_url "$ALERT_DISCORD_WEBHOOK_URL")" > "$TMP_FILE"
elif [ -n "${ALERT_SLACK_WEBHOOK_URL:-}" ]; then
  write_slack_receiver "slack" "$ALERT_SLACK_WEBHOOK_URL" > "$TMP_FILE"
else
  write_local_receiver > "$TMP_FILE"
fi

if cmp -s "$TMP_FILE" "$CONFIG_FILE" 2>/dev/null; then
  rm -f "$TMP_FILE"
  echo "Alertmanager config already up to date: ${CONFIG_FILE}"
  echo "changed=false"
  exit 0
fi

mv "$TMP_FILE" "$CONFIG_FILE"
echo "Alertmanager config updated: ${CONFIG_FILE}"
echo "changed=true"
