#!/usr/bin/env sh
set -eu

usage() {
  echo "Usage: IMAGE_TAG=<image> $0" >&2
  echo "   or: $0 <image>" >&2
}

resolve_env_file() {
  case "$1" in
    */*) printf '%s\n' "$1" ;;
    *) printf './%s\n' "$1" ;;
  esac
}

read_env_value() {
  key="$1"
  file="$2"

  if [ ! -f "$file" ]; then
    return 0
  fi

  grep "^${key}=" "$file" | tail -n 1 | cut -d '=' -f 2- || true
}

set_env_value() {
  key="$1"
  value="$2"
  file="$3"
  tmp="${file}.tmp.$$"

  if [ -f "$file" ] && grep -q "^${key}=" "$file"; then
    awk -v key="$key" -v value="$value" '
      BEGIN { replaced = 0 }
      $0 ~ "^" key "=" && replaced == 0 {
        print key "=" value
        replaced = 1
        next
      }
      $0 ~ "^" key "=" { next }
      { print }
    ' "$file" > "$tmp"
  else
    if [ -f "$file" ]; then
      cp "$file" "$tmp"
    else
      : > "$tmp"
    fi
    printf '\n%s=%s\n' "$key" "$value" >> "$tmp"
  fi

  mv "$tmp" "$file"
}

run_smoke_test() {
  if [ ! -x ./ops/smoke-test.sh ]; then
    echo "Smoke test script is missing or not executable: ./ops/smoke-test.sh" >&2
    return 1
  fi

  ./ops/smoke-test.sh
}

rollback() {
  previous_image="$1"
  env_file="$2"
  compose_file="$3"
  app_service="$4"

  if [ -z "$previous_image" ]; then
    echo "No previous APP_IMAGE was found. Automatic rollback is not available." >&2
    return 1
  fi

  echo "Rolling back to previous image: ${previous_image}"
  set_env_value APP_IMAGE "$previous_image" "$env_file"

  docker compose --env-file "$env_file" -f "$compose_file" pull "$app_service" || true
  docker compose --env-file "$env_file" -f "$compose_file" up -d --no-build --remove-orphans
  docker compose --env-file "$env_file" -f "$compose_file" ps

  echo "Running smoke test after rollback"
  run_smoke_test
}

IMAGE_TAG="${1:-${IMAGE_TAG:-}}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
ENV_FILE="$(resolve_env_file "${ENV_FILE:-.env}")"
APP_SERVICE="${APP_SERVICE:-app}"
STATE_DIR="${DEPLOY_STATE_DIR:-.deploy-state}"

if [ -z "$IMAGE_TAG" ]; then
  usage
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Compose file not found: ${COMPOSE_FILE}" >&2
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  if [ -f .env.example ]; then
    cp .env.example "$ENV_FILE"
  else
    : > "$ENV_FILE"
  fi
fi

mkdir -p "$STATE_DIR"

PREVIOUS_IMAGE="$(read_env_value APP_IMAGE "$ENV_FILE")"

if [ -n "$PREVIOUS_IMAGE" ]; then
  printf '%s\n' "$PREVIOUS_IMAGE" > "${STATE_DIR}/previous-app-image"
fi

echo "Deploying image: ${IMAGE_TAG}"
if [ -n "$PREVIOUS_IMAGE" ] && [ "$PREVIOUS_IMAGE" != "$IMAGE_TAG" ]; then
  echo "Previous image: ${PREVIOUS_IMAGE}"
fi

set_env_value APP_IMAGE "$IMAGE_TAG" "$ENV_FILE"

if ! docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull "$APP_SERVICE"; then
  echo "Image pull failed before changing the running service." >&2
  if [ -n "$PREVIOUS_IMAGE" ]; then
    set_env_value APP_IMAGE "$PREVIOUS_IMAGE" "$ENV_FILE"
  fi
  exit 1
fi

if [ -x ./ops/configure-alertmanager.sh ]; then
  ENV_FILE="$ENV_FILE" ./ops/configure-alertmanager.sh
fi

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --no-build --remove-orphans
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" kill -s HUP alertmanager >/dev/null 2>&1 || true

if run_smoke_test; then
  printf '%s\n' "$IMAGE_TAG" > "${STATE_DIR}/last-successful-app-image"
  echo "Deployment completed successfully: ${IMAGE_TAG}"
  exit 0
fi

echo "Deployment smoke test failed. Starting automatic rollback." >&2

if rollback "$PREVIOUS_IMAGE" "$ENV_FILE" "$COMPOSE_FILE" "$APP_SERVICE"; then
  echo "Rollback completed. The deployment job will still fail because the new image did not pass smoke tests." >&2
else
  echo "Rollback failed. Manual intervention is required." >&2
fi

exit 1
